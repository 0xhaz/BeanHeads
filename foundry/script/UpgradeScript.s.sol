// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IDiamondCut} from "src/interfaces/IDiamondCut.sol";
import {BeanHeadsMarketplaceSigFacet} from "src/facets/upgrade/BeanHeadsMarketplaceSigFacet.sol";
import {ReentrancyLib} from "src/libraries/ReentrancyLib.sol";
import {IERC721Permit} from "src/interfaces/IERC721Permit.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IDiamondLoupe} from "src/interfaces/IDiamondLoupe.sol";

contract DiamondInitV2 {
    function init() external {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        ds.supportedInterfaces[type(IERC1271).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Permit).interfaceId] = true;

        ReentrancyLib.initReentrancyGuard(); // Initialize reentrancy guard
    }
}

contract UpgradeScript is Script {
    HelperConfig helperConfig;
    address constant DIAMOND_ADDRESS_SEPOLIA = 0xA695E5cA989482fDcE4321A01a3308F790749497;
    address constant DIAMOND_ADDRESS_ARBITRUM = 0x3848388D51a40c4eae70c4bC14b00E34526831Dc;

    BeanHeadsMarketplaceSigFacet facet;
    uint256 deployerKey;
    address diamond;

    function setUp() public {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();
        deployerKey = config.deployerKey;
    }

    function run() public {
        vm.startBroadcast(deployerKey);

        // Deploy the new facet
        if (block.chainid == helperConfig.ETH_SEPOLIA_CHAIN_ID()) {
            diamond = DIAMOND_ADDRESS_SEPOLIA;
        } else if (block.chainid == helperConfig.ARBITRUM_SEPOLIA_CHAIN_ID()) {
            diamond = DIAMOND_ADDRESS_ARBITRUM;
        } else {
            revert("Unsupported network for upgrade");
        }

        facet = new BeanHeadsMarketplaceSigFacet(diamond);
        console.log("BeanHeadsMarketplaceSigFacet deployed at:", address(facet));

        bytes4[] memory selectors = new bytes4[](7);
        uint256 i;

        selectors[i++] = facet.sellTokenWithPermit.selector;
        selectors[i++] = facet.buyTokenWithPermit.selector;
        selectors[i++] = facet.cancelTokenSaleWithPermit.selector;
        selectors[i++] = facet.permit.selector;
        selectors[i++] = facet.nonces.selector;
        selectors[i++] = facet.eip712Domain.selector;
        selectors[i++] = facet.DOMAIN_SEPARATOR.selector;

        // Prepare the diamond cut
        IDiamondCut.FacetCut[] memory diamondCut = new IDiamondCut.FacetCut[](1);
        diamondCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        DiamondInitV2 initV2 = new DiamondInitV2();
        address initAddr = address(initV2);
        bytes memory initCallData = abi.encodeWithSelector(initV2.init.selector);

        // Perform the diamond cut
        IDiamondCut(diamond).diamondCut(diamondCut, initAddr, initCallData);

        vm.stopBroadcast();
        console.log("Upgrade completed successfully");
    }
}
