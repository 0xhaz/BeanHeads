// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Genesis} from "src/types/Genesis.sol";

interface IBeanHeadsView {
    /// @notice Error thrown when a token does not exist
    error IBeanHeadsView__TokenDoesNotExist();
    /// @notice Error thrown when the caller is not the owner of the token
    error IBeanHeadsView__NotOwner();
    /// @notice Error thrown when the token is not for sale
    error IBeanHeadsView__TokenNotForSale();

    /**
     * @notice Returns the token URI for a given token ID
     * @param _tokenId The ID of the token
     * @return The token URI as a string
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory);

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
     * @notice Checks if a token exists
     * @param tokenId The ID of the token to check
     */
    function exists(uint256 tokenId) external view returns (bool);

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

    /**
     * @notice Checks if a bridge is authorized for cross-chain operations
     * @param chainSelector The chain selector for the remote bridge
     * @param bridge The address of the remote bridge contract
     * @return True if the bridge is authorized, false otherwise
     */
    function isBridgeAuthorized(uint64 chainSelector, address bridge) external view returns (bool);

    /**
     * @notice Checks if a token is locked
     * @param tokenId The ID of the token to check
     * @return True if the token is locked, false otherwise
     */
    function isTokenLocked(uint256 tokenId) external view returns (bool);

    /**
     * @notice Returns the origin chain ID of a token
     * @param tokenId The ID of the token
     * @return The origin chain ID as a uint256
     */
    function getOriginChainId(uint256 tokenId) external view returns (uint256);
}
