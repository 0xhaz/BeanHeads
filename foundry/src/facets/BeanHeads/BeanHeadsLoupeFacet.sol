// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {BHStorage} from "src/libraries/BHStorage.sol";
import {IDiamondLoupe} from "src/interfaces/IDiamondLoupe.sol";
import {IERC165} from "src/interfaces/IERC165.sol";

contract BeanHeadsLoupeFacet is IDiamondLoupe, IERC165 {
    function facets() external view override returns (Facet[] memory facets_) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        uint256 selectorCount = ds.selectors.length;

        // create an array for counting the number of selectors per facet
        uint8[] memory numFacetSelectors = new uint8[](selectorCount);

        // total number of facets
        uint256 numFacets;

        // loop through all selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.selectorToFacetPosition[selector].facetAddress;
            bool continueLoop = false;

            // find the functionSelectors array for selector and add selector to it
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facets_[facetIndex].facetAddress == facetAddress_) {
                    facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                    // probably will never have more than 256 functions from one facet
                    require(numFacetSelectors[facetIndex] < 255);
                    numFacetSelectors[facetIndex]++;
                    continueLoop = true;
                    break;
                }
            }
            // if functionSelectors array exists for selector then continue loop
            if (continueLoop) {
                continueLoop = false;
                continue;
            }

            // create a new functionSelectors array for selector
            facets_[numFacets].facetAddress = facetAddress_;
            facets_[numFacets].functionSelectors = new bytes4[](selectorCount);
            facets_[numFacets].functionSelectors[0] = selector;
            numFacetSelectors[numFacets] = 1;
            numFacets++;
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet
    /// @param _facet The facet address
    /// @return _facetFunctionSelectors The selectors associated with the facet
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory _facetFunctionSelectors)
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](selectorCount);
        // loop through all selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.selectorToFacetPosition[selector].facetAddress;
            if (_facet == facetAddress_) {
                _facetFunctionSelectors[numSelectors] = selector;
                numSelectors++;
            }
        }
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond
    /// @return facetAddresses_ The facet addresses
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array to the maximum size possible
        facetAddresses_ = new address[](selectorCount);
        uint256 numFacets;
        // loop through all selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.selectorToFacetPosition[selector].facetAddress;
            bool continueLoop = false;

            // find the facet address in the array and add it if not found
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facetAddresses_[facetIndex] == facetAddress_) {
                    continueLoop = true;
                    break;
                }
            }

            // continue loop if facet address is found
            if (continueLoop) {
                continueLoop = false;
                continue;
            }

            // include address
            facetAddresses_[numFacets] = facetAddress_;
            numFacets++;
        }

        // set the number of facets in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet address that supports the given selector
    /// @dev If facet is not found returns address(0)'
    /// @param _functionSelector The function selector
    /// @return facetAddress_ The facet address that supports the selector
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        facetAddress_ = ds.selectorToFacetPosition[_functionSelector].facetAddress;
    }

    // ERC165 Functions
    ////////////////////////////////////////////////////////////////////
    /// @notice Checks if the contract supports the given interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @return bool True if the contract supports the interface, false otherwise
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        return ds.supportedInterfaces[_interfaceId] == true;
    }
}
