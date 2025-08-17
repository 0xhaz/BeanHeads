// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IDiamondCut {
    /**
     * @notice Error thrown when the caller is not the contract owner
     * @param caller The address of the caller
     * @param owner The address of the contract owner
     */
    error IDiamondCut__NotContractOwner(address caller, address owner);

    /**
     * @notice Enum representing the different actions that can be performed on a facet
     */
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    /**
     * @notice Struct representing a facet cut
     * @param facetAddress The address of the facet
     * @param action The action to be performed on the facet
     * @param functionSelectors The function selectors to be added, replaced, or removed
     */
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Add/replace/remove any number of functions and optionally
     * execute a function with delegatecall
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector
     * and arguments _calldata is executed with delegatecall on _init
     */
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /**
     * @notice Function to perform a diamond cut
     * @param _diamondCuts An array of FacetCut structs defining the cuts to be made
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments,
     * executed with delegatecall on _init
     */
    function diamondCut(FacetCut[] calldata _diamondCuts, address _init, bytes calldata _calldata) external;
}
