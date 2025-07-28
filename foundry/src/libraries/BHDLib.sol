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
library BHDLib {
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 internal constant BH_STORAGE_POSITION = keccak256("beanheads.diamond.storage");

    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    struct FacetPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct BeanHeadsStorage {
        mapping(uint256 tokenId => IBeanHeads.Listing) tokenIdToListing;
        mapping(uint256 tokenId => Genesis.SVGParams params) tokenIdToParams;
        mapping(uint256 tokenId => uint256 generation) tokenIdToGeneration;
        mapping(address tokenOwner => bool isAuthorized) authorizedBreeders;
        mapping(address tokenOwner => uint256[] tokenIds) ownerTokens;
        mapping(address tokenAddress => bool isAllowed) allowedTokens;
        mapping(uint256 tokenId => address tokenAddress) tokenIdToPaymentToken;
        mapping(address tokenAddress => address priceFeed) priceFeeds;
        mapping(bytes4 selector => FacetPosition position) selectorToFacetPosition;
        address[] privateFeeds;
        address royaltyContract;
        AggregatorV3Interface priceFeed;
        uint256 mintPriceUsd;
        address owner;
        bytes4[] selectors;
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
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;

            if (functionSelectors.length == 0) revert BHDLib__NotSelectorsProvided(facetAddress);

            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            }

            if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            }

            if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert BHDLib__IncorrectFacetCutAction(uint8(action));
            }

            emit DiamondCut(_diamondCut, _init, _calldata);
        }
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_facetAddress == address(0)) revert BHDLib__CannotAddZeroSelector(_functionSelectors);

        BeanHeadsStorage storage ds = diamondStorage();

        uint16 selectorCount = uint16(ds.selectors.length);

        enforceHasContractCode(_facetAddress, BHDLib__InitAddressHasNoCode.selector);

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];

            address oldFacetAddress = ds.selectorToFacetPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) revert BHDLib__CannotAddExistingSelector(selector);

            ds.selectorToFacetPosition[selector] =
                FacetPosition({facetAddress: _facetAddress, selectorPosition: selectorCount});

            ds.selectors.push(selector);

            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        BeanHeadsStorage storage ds = diamondStorage();

        if (_facetAddress == address(0)) revert BHDLib__CannotAddZeroSelector(_functionSelectors);

        enforceHasContractCode(_facetAddress, BHDLib__InitAddressHasNoCode.selector);

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];

            address oldFacetAddress = ds.selectorToFacetPosition[selector].facetAddress;

            if (oldFacetAddress == address(this)) revert BHDLib__CannotReplaceImmutableFunction(selector);

            if (oldFacetAddress == _facetAddress) revert BHDLib__CannotAddExistingSelector(selector);

            if (oldFacetAddress == address(0)) revert BHDLib__CannotReplaceFunctionThatDoesNotExist(selector);

            ds.selectorToFacetPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        BeanHeadsStorage storage ds = diamondStorage();

        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) revert BHDLib__MustBeZeroAddress(_facetAddress);

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];

            FacetPosition memory oldFacetPosition = ds.selectorToFacetPosition[selector];

            if (oldFacetPosition.facetAddress == address(0)) {
                revert BHDLib__CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // can't remove immutable functions
            if (oldFacetPosition.facetAddress == address(this)) revert BHDLib__CannotReplaceImmutableFunction(selector);

            // replace selector with last selector
            selectorCount--;
            if (oldFacetPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetPosition.selectorPosition] = lastSelector;
                ds.selectorToFacetPosition[lastSelector].selectorPosition = oldFacetPosition.selectorPosition;
            }
        }
    }

    function enforceHasContractCode(address _contract, bytes4 _errorMsg) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) revert BHDLib__NoBytecodeAtAddress(_contract, bytes4(_errorMsg));
    }
}
