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
     * @notice Returns the sale price of a token.
     * @param _tokenId The ID of the token to query.
     * @return The sale price of the token.
     */
    function getTokenSalePrice(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the current mint price for a Genesis NFT
     * @return The current mint price in wei
     */
    function getMintPrice() external view returns (uint256);

    /**
     * @notice Returns the generation of a token
     * @param _tokenId The ID of the token to query
     * @return _generation The generation number of the token
     */
    function getGeneration(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the authorized breeders for minting
     * @param _breeder The address of the breeder to check
     * @return True if the breeder is authorized, false otherwise
     */
    function getAuthorizedBreeders(address _breeder) external view returns (bool);

    /**
     * @notice Checks if a token exists
     * @param tokenId The ID of the token to check
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @notice Check if the token is allowed for minting
     * @param _token The address of the token to check
     * @return isAllowed True if the token is allowed, false otherwise
     */
    function isTokenAllowed(address _token) external view returns (bool);

    /**
     * @notice Returns the price feed address for a token.
     * @param _token The address of the token to query.
     * @return The price feed address for the token.
     */
    function getPriceFeed(address _token) external view returns (address);

    /**
     * @notice Check if the token is on sale
     * @param _tokenId The ID of the token to check
     * @return isOnSale True if the token is on sale, false otherwise
     */
    function isTokenForSale(uint256 _tokenId) external view returns (bool);
}
