// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Genesis} from "src/types/Genesis.sol";

interface IBeanHeadsBreeding {
    /// @notice Error thrown when an unauthorized breeder attempts to mint
    error IBeanHeadsBreeding__UnauthorizedBreeders();

    /// @notice Event emitted when a new breed is minted
    event MintedNewBreed(address indexed to, uint256 indexed tokenId);

    /// @notice Function to mint a new breed from authorized breeders
    /// @param _to The address to mint the new breed to
    /// @param _params The SVG parameters for the new breed
    /// @param _generation The generation of the new breed
    function mintFromBreeders(address _to, Genesis.SVGParams calldata _params, uint256 _generation)
        external
        returns (uint256 _tokenId);
}
