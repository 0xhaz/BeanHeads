// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Genesis} from "src/types/Genesis.sol";

interface IBeanHeads {
    /// @notice Return error when token does not exist
    error IBeanHeads__TokenDoesNotExist();

    error IBeanHeads__NotOwner();

    error IBeanHeads__WithdrawFailed();

    error IBeanHeads__InvalidRoyaltyFee();

    error IBeanHeads__PriceMustBeGreaterThanZero();
    error IBeanHeads__PriceMismatch();
    error IBeanHeads__TokenIsNotForSale();
    error IBeanHeads__RoyaltyPaymentFailed(uint256 tokenId);
    error IBeanHeads__InsufficientPayment();
    error IBeanHeads__InvalidAmount();
    error IBeanHeads__InvalidAttributesArray();
    error IBeanHeads__InvalidRequestId();
    error IBeanHeads__UnauthorizedBreeders();
    error IBeanHeads__NotParentGeneration();

    event MintedGenesis(address indexed owner, uint256 indexed tokenId);
    event TokenWithdrawn(address indexed owner, uint256 amount);
    event SetTokenPrice(address indexed owner, uint256 indexed tokenId, uint256 price);
    event RoyaltyPaid(address indexed receiver, uint256 indexed tokenId, uint256 salePrice, uint256 royaltyAmount);
    event RoyaltyInfoUpdated(address indexed receiver, uint96 feeBps);
    event TokenSaleCancelled(address indexed owner, uint256 indexed tokenId);
    event TokenSold(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 salePrice);
    event MintedNewBreed(address indexed owner, uint256 indexed tokenId);

    /**
     * @notice Mints a new Genesis NFT with the provided SVG parameters
     * @param params The struct containing SVG configuration parameters
     * @return tokenId The ID of the newly minted token
     */
    function mintGenesis(address to, Genesis.SVGParams memory params, uint256 amount)
        external
        payable
        returns (uint256);

    /**
     * @notice Returns the attributes of a token as a JSON string.
     * @param tokenId The ID of the token to query.
     * @return A JSON string containing the attributes of the token.
     */
    function getAttributes(uint256 tokenId) external view returns (string memory);

    /**
     * @notice Retrieves all token IDs owned by a specific address
     * @param owner The address of the token owner
     * @return tokenIds An array of token IDs owned by the specified address
     */
    function getOwnerTokens(address owner) external view returns (uint256[] memory);

    /**
     * @notice Returns the number of tokens owned by the specified address.
     * @param owner Address to query.
     */
    function getOwnerTokensCount(address owner) external view returns (uint256);

    /**
     * @notice Returns the owner of a given token ID.
     * @param tokenId Token ID to query.
     */
    function getOwnerOf(uint256 tokenId) external view returns (address);

    /**
     * @notice Retrieves the stored SVG parameters for a token ID.
     * @param tokenId The token ID.
     * @return params The SVG parameters struct.
     */
    function getAttributesByTokenId(uint256 tokenId) external view returns (Genesis.SVGParams memory);

    /**
     * @notice Retrieves the stored SVG parameters for a token ID, checking caller ownership.
     * @param owner Address expected to own the token.
     * @param tokenId The token ID.
     * @return params The SVG parameters struct.
     */
    function getAttributesByOwner(address owner, uint256 tokenId) external view returns (Genesis.SVGParams memory);

    /**
     * @notice Sell token with custom price
     * @param tokenId The ID of the token to sell
     * @param price The price at which to sell the token
     */
    function sellToken(uint256 tokenId, uint256 price) external;

    /**
     * @notice Buys a token currently on sale.
     * @param tokenId The ID of the token to buy.
     * @param price The agreed sale price.
     * @dev This function transfers the token to the buyer, pays the seller minus royalties, and emits relevant events.
     */
    function buyToken(uint256 tokenId, uint256 price) external payable;

    /**
     * @notice Cancels the sale of a token
     * @param tokenId The ID of the token to cancel sale for
     * @dev Resets the sale price and seller address
     */
    function cancelTokenSale(uint256 tokenId) external;

    /**
     * @notice Withdraws the contract's balance to the owner's address
     * @dev Only callable by the owner
     */
    function withdraw() external;

    /**
     * @notice Get the current mint price for a Genesis NFT
     * @return The current mint price in wei
     */
    function getMintPrice() external view returns (uint256);

    /**
     * @notice Returns the generation of a token
     * @param tokenId The ID of the token to query
     * @return generation The generation number of the token
     */
    function getGeneration(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Mints a new token with randomized attributes
     * @dev Only callable by authorized breeders
     * @param to The address to mint the token to
     * @param params The generated SVG parameters for the token
     * @param generation The generation number of the token
     * @return tokenId The ID of the newly minted token
     */
    function mintFromBreeders(address to, Genesis.SVGParams memory params, uint256 generation)
        external
        returns (uint256);

    function getAuthorizedBreeders(address owner) external view returns (bool);

    /**
     * @notice Burns a token, removing it from circulation
     * @param tokenId The ID of the token to burn
     * @dev This function can only be called by the owner of the token or an authorized breeder.
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Safely transfers a token from one address to another
     * @param from The address to transfer the token from
     * @param to The address to transfer the token to
     * @param tokenId The ID of the token to transfer
     * @dev This function checks that the recipient is capable of receiving the token.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;

    /**
     * @notice Approves another address to transfer the specified token ID
     * @param to The address to approve
     * @param tokenId The ID of the token to approve
     * @dev This function allows the owner of a token to approve another address to transfer it.
     */
    function approve(address to, uint256 tokenId) external payable;

    function authorizeBreeder(address breeder) external;

    /**
     * @notice Returns the next token ID to be minted
     * @return The next token ID
     * @dev This function is used to determine the next available token ID for minting.
     */
    function getNextTokenId() external view returns (uint256);

    /**
     * @notice Checks if a token exists
     * @param tokenId The ID of the token to check
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @notice Returns the metadata URI for a token.
     * @param tokenId Token ID to query.
     * @return Metadata URI.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
