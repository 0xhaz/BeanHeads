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
    error IBeanHeads__TokenNotAllowed(address token);
    error IBeanHeads__InvalidTokenAddress();
    error IBeanHeads__InsufficientAllowance();
    error IBeanHeads__InvalidTokenDecimals();
    error IBeanHeads__InvalidOraclePrice();

    /// @notice Emitted when a new Genesis NFT is minted
    event MintedGenesis(address indexed owner, uint256 indexed tokenId);

    /// @notice Emitted when a token is withdrawn
    event TokenWithdrawn(address indexed owner, uint256 amount);

    /// @notice Emitted when a seller sets a price for a token
    event SetTokenPrice(address indexed owner, uint256 indexed tokenId, uint256 price);
    event RoyaltyPaid(address indexed receiver, uint256 indexed tokenId, uint256 salePrice, uint256 royaltyAmount);
    event RoyaltyInfoUpdated(address indexed receiver, uint96 feeBps);
    event TokenSaleCancelled(address indexed owner, uint256 indexed tokenId);
    event TokenSold(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 salePrice);
    event MintedNewBreed(address indexed owner, uint256 indexed tokenId);
    event AllowedTokenUpdated(address indexed token, bool isAllowed);
    event MintPriceUpdated(uint256 newPrice);
    event PriceFeedAdded(address indexed token, address indexed priceFeed);

    /// @notice Struct representing a token listing
    /// @param seller The address of the seller.
    /// @param price The price at which the token is listed for sale.
    /// @param isActive Whether the listing is currently active.
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }

    /**
     * @notice Mints a new Genesis NFT with the provided SVG parameters
     * @param params The struct containing SVG configuration parameters
     * @return tokenId The ID of the newly minted token
     */
    function mintGenesis(address to, Genesis.SVGParams memory params, uint256 amount, address token)
        external
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
     * @dev This function transfers the token to the buyer, pays the seller minus royalties, and emits relevant events.
     */
    function buyToken(uint256 tokenId, address token) external;

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
    function withdraw(address token) external;

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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;

    /**
     * @notice Approves another address to transfer the specified token ID
     * @param to The address to approve
     * @param tokenId The ID of the token to approve
     * @dev This function allows the owner of a token to approve another address to transfer it.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @notice Sets or unsets an address as an authorized breeder
     * @param breeder The address to authorize or unauthorize
     * @dev This function allows the contract owner to manage which addresses can call breeder functions.
     */
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

    /**
     * @notice Add or remove a token from the allow list
     * @param token The address of the token to add or remove
     * @param allowList Whether to add (true) or remove (false) the token
     * @dev This function allows the contract owner to manage the allow list of tokens that can be used with the contract.
     */
    function setAllowedToken(address token, bool allowList) external;

    /**
     * @notice Sets the mint price for a Genesis NFT
     * @param newPrice The new mint price in wei
     * @dev Only callable by the contract owner
     */
    function setMintPrice(uint256 newPrice) external;

    /**
     * @notice Returns the sale price of a token.
     * @param tokenId The ID of the token to query.
     * @return The sale price of the token.
     */
    function getTokenSalePrice(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Check if the token is allowed for minting
     * @param token The address of the token to check
     * @return isAllowed True if the token is allowed, false otherwise
     */
    function isTokenAllowed(address token) external view returns (bool);

    /**
     * @notice Check if the token is on sale
     * @param tokenId The ID of the token to check
     * @return isOnSale True if the token is on sale, false otherwise
     */
    function isTokenForSale(uint256 tokenId) external view returns (bool);

    /**
     * @notice Returns the price feed address for a token.
     * @param token The address of the token to query.
     * @return The price feed address for the token.
     */
    function getPriceFeed(address token) external view returns (address);

    /**
     * @notice Adds a price feed for a token.
     * @param token The address of the token to add the price feed for.
     * @param priceFeed The address of the price feed contract.
     */
    function addPriceFeed(address token, address priceFeed) external;

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256);

    function getTotalSupply() external view returns (uint256);

    function owner() external view returns (address);
}
