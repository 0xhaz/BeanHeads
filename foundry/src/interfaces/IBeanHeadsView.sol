// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Genesis} from "src/types/Genesis.sol";

interface IBeanHeadsView {
    error IBeanHeadsView__TokenDoesNotExist();
    error IBeanHeadsView__NotOwner();
    error IBeanHeadsView__TokenNotForSale();

    /**
     * @notice Returns the token URI for a given token ID
     * @param _tokenId The ID of the token
     * @return The token URI as a string
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    /**
     * @notice Returns the next available token ID
     * @return The next token ID as a uint256
     */
    function getNextTokenId() external view returns (uint256);

    /**
     * @notice Returns the owner of a given token ID
     * @param _tokenId The ID of the token
     * @return The address of the owner
     */
    function getOwnerOf(uint256 _tokenId) external view returns (address);

    /**
     * @notice Returns the tokens owned by a specific address
     * @param _owner The address of the owner
     * @return An array of token IDs owned by the address
     */
    function getOwnerTokens(address _owner) external view returns (uint256[] memory);

    /**
     * @notice Returns the attributes of a token by its ID
     * @param _tokenId The ID of the token
     * @return The SVG parameters associated with the token
     */
    function getAttributesByTokenId(uint256 _tokenId) external view returns (Genesis.SVGParams memory);

    /**
     * @notice Returns the attributes of a token by its owner and token ID
     * @param _owner The address of the owner
     * @param _tokenId The ID of the token
     * @return The SVG parameters associated with the token for that owner
     */
    function getAttributesByOwner(address _owner, uint256 _tokenId) external view returns (Genesis.SVGParams memory);

    /**
     * @notice Returns the attributes of a token as a JSON string.
     * @param _tokenId The ID of the token to query.
     * @return A JSON string containing the attributes of the token.
     */
    function getAttributes(uint256 _tokenId) external view returns (string memory);

    /**
     * @notice Returns the generation of a token
     * @param _tokenId The ID of the token to query
     * @return _generation The generation number of the token
     */
    function getGeneration(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Checks if a token exists
     * @param tokenId The ID of the token to check
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @notice Returns the price feed address for a token.
     * @param _token The address of the token to query.
     * @return The price feed address for the token.
     */
    function getPriceFeed(address _token) external view returns (address);

    /**
     * @notice Returns the number of tokens owned by the specified address.
     * @param owner Address to query.
     */
    function getOwnerTokensCount(address owner) external view returns (uint256);

    /**
     * @notice Returns the total supply of tokens.
     * @return The total number of tokens minted.
     */
    function getTotalSupply() external view returns (uint256);
}
