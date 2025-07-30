// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {IDiamondCut} from "src/interfaces/IDiamondCut.sol";

/**
 * @title BHDLib
 * @author 0xhaz
 * @notice Diamond library for BeanHeads that stores all storage slots
 * @dev Implementation of EIP-2535 Diamond Standard
 * @dev https://eips.ethereum.org/EIPS/eip-2535
 */
library BHStorage {
    error BHDLib__NotContractOwner(address caller, address owner);
    error BHDLib__NotSelectorsProvided(address facetAddress);
    error BHDLib__CannotAddZeroSelector(bytes4[] functionSelectors);
    error BHDLib__NoBytecodeAtAddress(address contractAddress, bytes4 errorMsg);
    error BHDLib__InitAddressHasNoCode(bytes4 errorMsg);
    error BHDLib__CannotAddExistingSelector(bytes4 selector);
    error BHDLib__IncorrectFacetCutAction(uint8 action);
    error BHDLib__CannotReplaceImmutableFunction(bytes4 selector);
    error BHDLib__MustBeZeroAddress(address facetAddress);
    error BHDLib__CannotReplaceFunctionThatDoesNotExist(bytes4 selector);
    error BHDLib__CannotRemoveFunctionThatDoesNotExist(bytes4 selector);
    error BHDLib__InitializationFunctionReverted(address init, bytes data);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 internal constant BH_STORAGE_POSITION = keccak256("beanheads.diamond.storage");

    uint256 internal constant PRECISION = 1e18;

    uint256 internal constant ADDITIONAL_FEED_PRECISION = 1e10;

    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    struct FacetPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct BeanHeadsStorage {
        mapping(uint256 tokenId => Listing) tokenIdToListing;
        mapping(uint256 tokenId => Genesis.SVGParams params) tokenIdToParams;
        mapping(uint256 tokenId => uint256 generation) tokenIdToGeneration;
        mapping(address tokenOwner => bool isAuthorized) authorizedBreeders;
        mapping(address tokenOwner => uint256[] tokenIds) ownerTokens;
        mapping(address tokenAddress => bool isAllowed) allowedTokens;
        mapping(uint256 tokenId => address tokenAddress) tokenIdToPaymentToken;
        mapping(address tokenAddress => address priceFeed) priceFeeds;
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 selector => FacetPosition position) selectorToFacetPosition;
        // maps facet addresses to function selectors
        mapping(address facetAddress => FacetFunctionSelectors selectors) facetFunctionSelectors;
        address[] privateFeedsAddresses;
        // facet addresses
        address[] facetAddresses;
        address royaltyContract;
        AggregatorV3Interface priceFeed;
        uint256 mintPriceUsd;
        // owner of the contract
        address owner;
        bytes4[] selectors;
        // Used to query if a contract implements an interface.
        mapping(bytes4 interfaceId => bool isSupported) supportedInterfaces;
    }

    function diamondStorage() internal pure returns (BeanHeadsStorage storage ds) {
        bytes32 position = BH_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setContractOwner(address _newOwner) internal {
        BeanHeadsStorage storage ds = diamondStorage();
        address previousOwner = ds.owner;
        ds.owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().owner;
    }

    function enforceContractOwner() internal view {
        if (msg.sender != diamondStorage().owner) {
            revert BHDLib__NotContractOwner(msg.sender, diamondStorage().owner);
        }
    }

    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCut memory facet = _diamondCut[facetIndex];

            if (facet.functionSelectors.length == 0) {
                revert BHDLib__NotSelectorsProvided(facet.facetAddress);
            }

            if (
                (facet.action == IDiamondCut.FacetCutAction.Add || facet.action == IDiamondCut.FacetCutAction.Replace)
                    && facet.facetAddress == address(0)
            ) {
                revert BHDLib__CannotAddZeroSelector(facet.functionSelectors);
            }

            if (facet.action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(facet.facetAddress, facet.functionSelectors);
            } else if (facet.action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(facet.facetAddress, facet.functionSelectors);
            } else if (facet.action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(facet.facetAddress, facet.functionSelectors);
            } else {
                revert BHDLib__IncorrectFacetCutAction(uint8(facet.action));
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        // require(_functionSelectors.length > 0, "BHStorage: No selectors provided");

        BeanHeadsStorage storage ds = diamondStorage();

        require(_facetAddress != address(0), "BHStorage: Cannot add zero address");

        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);

        // add new facet address if it doesn't exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];

            address oldFacetAddress = ds.selectorToFacetPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "BHStorage: Cannot add existing selector");

            addFunction(ds, selector, selectorPosition, _facetAddress);

            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "BHStorage: No selectors provided");
        BeanHeadsStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "BHStorage: Cannot add zero address");

        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);

        // add new facet address if it doesn't exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];

            address oldFacetAddress = ds.selectorToFacetPosition[selector].facetAddress;

            require(oldFacetAddress != _facetAddress, "BHStorage: Cannot replace immutable function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);

            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "BHStorage: No selectors provided");
        BeanHeadsStorage storage ds = diamondStorage();

        require(_facetAddress == address(0), "BHStorage: Must be zero address");

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];

            address oldFacetAddress = ds.selectorToFacetPosition[selector].facetAddress;

            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(BeanHeadsStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "BHStorage: Facet address has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(BeanHeadsStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress)
        internal
    {
        ds.selectorToFacetPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(BeanHeadsStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "BHStorage: Can't remove function that does not exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "BHStorage: Cannot replace immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return; // No initialization required
        }
        enforceHasContractCode(_init, "BHStorage: Init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                // @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert BHDLib__InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMsg) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMsg);
    }
}
