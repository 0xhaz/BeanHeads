// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Genesis} from "src/types/Genesis.sol";

interface IBeanHeadsBreeding {
    /// @notice Error thrown when an unauthorized breeder attempts to mint
    error IBeanHeadsBreeding__UnauthorizedBreeders();
    /// @notice Error thrown when a token does not exist
    error IBeanHeadsBreeding__TokenDoesNotExist();

    /// @notice Event emitted when a new breed is minted
    event MintedNewBreed(address indexed to, uint256 indexed tokenId);

    /// @notice Function to mint a new breed from authorized breeders
    /// @param _to The address to mint the new breed to
    /// @param _params The SVG parameters for the new breed
    /// @param _generation The generation of the new breed
    function mintFromBreeders(address _to, Genesis.SVGParams calldata _params, uint256 _generation)
        external
        returns (uint256 _tokenId);

    /**
     * @notice Get the current mint price for a Genesis NFT
     * @return The current mint price in wei
     */
    function getMintPrice() external view returns (uint256);

    /**
     * @notice Get the authorized breeders for minting
     * @param _breeder The address of the breeder to check
     * @return True if the breeder is authorized, false otherwise
     */
    function getAuthorizedBreeders(address _breeder) external view returns (bool);

    /**
     * @notice Burns a token, removing it from circulation
     * @param tokenId The ID of the token to burn
     * @dev This function can only be called by the owner of the token or an authorized breeder.
     */
    function burn(uint256 tokenId) external;
}
