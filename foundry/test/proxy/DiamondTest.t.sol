// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BeanHeadsDiamond} from "src/BeanHeadsDiamond.sol";
import {DiamondCutFacet} from "src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "src/facets/OwnershipFacet.sol";
import {DiamondInit} from "src/updateinitializers/DiamondInit.sol";
import {IDiamondCut} from "src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "src/interfaces/IDiamondLoupe.sol";
import {IERC173} from "src/interfaces/IERC173.sol";
import {IERC165} from "src/interfaces/IERC165.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";

interface AggregatorV3Interface {}

contract MockRoyalty {}

contract MockFacet {
    function mockFunction() external pure returns (string memory) {
        return "Mock Function Called";
    }
}

contract RevertingInit {
    function revertFunction() external pure {
        revert("Initialization reverted");
    }
}

contract DiamondTest is Test {
    BeanHeadsDiamond public diamond;
    DiamondCutFacet public diamondCutFacet;
    DiamondLoupeFacet public diamondLoupeFacet;
    OwnershipFacet public ownershipFacet;
    DiamondInit public diamondInit;
    MockFacet public mockFacet;

    address owner = address(this);
    address newOwner = makeAddr("newOwner");
    address nonOwner = makeAddr("nonOwner");
    address mockRoyalty = address(new MockRoyalty());
    address mockPriceFeed = makeAddr("mockPriceFeed");

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function setUp() public {
        // Deploy facet
        diamondCutFacet = new DiamondCutFacet();
        diamond = new BeanHeadsDiamond(owner, address(diamondCutFacet));
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        diamondInit = new DiamondInit();
        mockFacet = new MockFacet();

        // Prepare diamond cut to add facets and initialize
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

        // Add DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = IDiamondLoupe.facets.selector;
        loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
        loupeSelectors[4] = IERC165.supportsInterface.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Add OwnershipFacet
        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = IERC173.transferOwnership.selector;
        ownershipSelectors[1] = IERC173.owner.selector;

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // Prepare initialization data
        bytes memory initCalldata = abi.encodeWithSelector(DiamondInit.init.selector, mockRoyalty, mockPriceFeed);

        // Perform diamond cut
        IDiamondCut(address(diamond)).diamondCut(cut, address(diamondInit), initCalldata);
    }

    function test_Owner() public view {
        address currentOwner = IERC173(address(diamond)).owner();
        assertEq(currentOwner, owner);
    }

    // function test_TransferOwnership() public {
    //     IERC173(address(diamond)).transferOwnership(newOwner);
    //     address currentOwner = IERC173(address(diamond)).owner();
    //     assertEq(currentOwner, newOwner);
    // }

    function test_Facets() public view {
        IDiamondLoupe.Facet[] memory facetsList = IDiamondLoupe(address(diamond)).facets();
        assertEq(facetsList.length, 3); // DiamondCutFacet, DiamondLoupeFacet, OwnershipFacet
    }

    function test_FacetAddresses() public view {
        address[] memory addresses = IDiamondLoupe(address(diamond)).facetAddresses();
        assertEq(addresses.length, 3); // DiamondCutFacet, DiamondLoupeFacet, OwnershipFacet
        assertTrue(
            addresses[0] == address(diamondCutFacet) || addresses[1] == address(diamondCutFacet)
                || addresses[2] == address(diamondCutFacet)
        );
        assertTrue(
            addresses[0] == address(diamondLoupeFacet) || addresses[1] == address(diamondLoupeFacet)
                || addresses[2] == address(diamondLoupeFacet)
        );
        assertTrue(
            addresses[0] == address(ownershipFacet) || addresses[1] == address(ownershipFacet)
                || addresses[2] == address(ownershipFacet)
        );
    }

    function test_FacetFunctionSelectors() public view {
        bytes4[] memory selectors = IDiamondLoupe(address(diamond)).facetFunctionSelectors(address(diamondLoupeFacet));
        assertEq(selectors.length, 5); // 5 selectors from DiamondLoupeFacet
    }

    function test_FacetAddress() public view {
        address facetAddr = IDiamondLoupe(address(diamond)).facetAddress(IERC173.owner.selector);
        assertEq(facetAddr, address(ownershipFacet));
    }

    function test_SupportsInterface() public view {
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondCut).interfaceId));
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondLoupe).interfaceId));
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC173).interfaceId));
    }

    function test_DiamondCut_AddFacets() public {
        bytes4[] memory mockSelectors = new bytes4[](1);
        mockSelectors[0] = MockFacet.mockFunction.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mockSelectors
        });

        vm.expectEmit(true, true, true, true);
        emit DiamondCut(cut, address(0), "");

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        address facetAddr = IDiamondLoupe(address(diamond)).facetAddress(mockSelectors[0]);
        assertEq(facetAddr, address(mockFacet));
    }

    function test_DiamondCut_ReplaceFacet() public {
        bytes4[] memory mockSelectors = new bytes4[](1);
        mockSelectors[0] = MockFacet.mockFunction.selector;
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mockSelectors
        });
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        MockFacet newMockFacet = new MockFacet();

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(newMockFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: mockSelectors
        });

        vm.expectEmit(true, true, true, true);
        emit DiamondCut(cut, address(0), "");

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        address facetAddr = IDiamondLoupe(address(diamond)).facetAddress(mockSelectors[0]);
        assertEq(facetAddr, address(newMockFacet));
        string memory result = MockFacet(facetAddr).mockFunction();
        assertEq(result, "Mock Function Called");
    }

    function test_DiamondCut_RemoveFacet() public {
        bytes4[] memory mockSelectors = new bytes4[](1);
        mockSelectors[0] = MockFacet.mockFunction.selector;
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mockSelectors
        });
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: mockSelectors
        });

        vm.expectEmit(true, true, true, true);
        emit DiamondCut(cut, address(0), "");

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        address facetAddr = IDiamondLoupe(address(diamond)).facetAddress(mockSelectors[0]);
        assertEq(facetAddr, address(0));
    }

    function test_TransferOwnership_NonOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(BHStorage.BHDLib__NotContractOwner.selector, nonOwner, owner));
        IERC173(address(diamond)).transferOwnership(newOwner);
    }

    function test_DiamondCut_NoSelectors() public {
        bytes4[] memory emptySelectors = new bytes4[](0);
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: emptySelectors
        });

        vm.expectRevert(abi.encodeWithSelector(BHStorage.BHDLib__NotSelectorsProvided.selector, address(mockFacet)));
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function test_DiamondCut_ZeroAddress() public {
        bytes4[] memory mockSelectors = new bytes4[](1);
        mockSelectors[0] = MockFacet.mockFunction.selector;
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mockSelectors
        });

        vm.expectRevert(abi.encodeWithSelector(BHStorage.BHDLib__CannotAddZeroSelector.selector, mockSelectors));
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function test_DiamondCut_ExistingSelector() public {
        bytes4[] memory mockSelectors = new bytes4[](1);
        mockSelectors[0] = MockFacet.mockFunction.selector;
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mockSelectors
        });
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        vm.expectRevert(abi.encodeWithSelector(BHStorage.BHDLib__CannotAddExistingSelector.selector, mockSelectors[0]));
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function test_DiamondCut_ReplaceNonExistentFacet() public {
        bytes4[] memory mockSelectors = new bytes4[](1);
        mockSelectors[0] = MockFacet.mockFunction.selector;
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: mockSelectors
        });

        vm.expectRevert(
            abi.encodeWithSelector(BHStorage.BHDLib__CannotReplaceFunctionThatDoesNotExist.selector, mockSelectors[0])
        );
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function test_DiamondCut_RemoveNonExistent() public {
        bytes4[] memory mockSelectors = new bytes4[](1);
        mockSelectors[0] = MockFacet.mockFunction.selector;
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: mockSelectors
        });

        vm.expectRevert(
            abi.encodeWithSelector(BHStorage.BHDLib__CannotRemoveFunctionThatDoesNotExist.selector, mockSelectors[0])
        );
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function test_DiamondCut_InitReverts() public {
        address mockInit = address(new RevertingInit());
        bytes4[] memory mockSelectors = new bytes4[](1);
        mockSelectors[0] = MockFacet.mockFunction.selector;
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mockSelectors
        });

        bytes memory initCalldata = abi.encodeWithSelector(bytes4(keccak256("revertFunction()")));
        vm.expectRevert(
            abi.encodeWithSelector(BHStorage.BHDLib__InitializationFunctionReverted.selector, mockInit, initCalldata)
        );
        IDiamondCut(address(diamond)).diamondCut(cut, mockInit, initCalldata);
    }

    function test_SupportsInterface_Fail_InvalidInterface() public view {
        bool isSupported = IERC165(address(diamond)).supportsInterface(bytes4(0x12345678));
        assertFalse(isSupported);
    }

    function test_FacetAddress_Fail_InvalidSelector() public view {
        address facetAddr = IDiamondLoupe(address(diamond)).facetAddress(bytes4(0x12345678));
        assertEq(facetAddr, address(0));
    }
}
