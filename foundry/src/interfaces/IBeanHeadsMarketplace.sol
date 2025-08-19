// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IBeanHeadsMarketplace {
    /// @notice Error thrown when a token does not exist
    error IBeanHeadsMarketplace__TokenDoesNotExist();
    /// @notice Error thrown when the caller is not the owner of the token
    error IBeanHeadsMarketplace__NotOwner();
    /// @notice Error thrown when the price is not greater than zero
    error IBeanHeadsMarketplace__PriceMustBeGreaterThanZero();
    /// @notice Error thrown when the token is not for sale
    error IBeanHeadsMarketplace__TokenNotForSale();
    /// @notice Error thrown when the token is not allowed for sale
    error IBeanHeadsMarketplace__TokenNotAllowed(address token);
    /// @notice Error thrown when the payment is insufficient
    error IBeanHeadsMarketplace__InsufficientPayment();
    /// @notice Error thrown when the oracle price is invalid
    error IBeanHeadsMarketplace__InvalidOraclePrice();
    /// @notice Error thrown when the allowance for the token is insufficient
    error IBeanHeadsMarketplace__InsufficientAllowance();
    /// @notice Error thrown when the price is higher than the maximum allowed price
    error IBeanHeadsMarketplace__PriceExceedsMax();
    /// @notice Error when token's length is not equal to the price's length
    error IBeanHeadsMarketplace__MismatchedArrayLengths();

    /// @notice Emitted when a seller sets a price for a token
    event SetTokenPrice(address indexed owner, uint256 indexed tokenId, uint256 price);
    /// @notice Emitted when token is sold and royalties are paid
    event RoyaltyPaid(address indexed receiver, uint256 indexed tokenId, uint256 salePrice, uint256 royaltyAmount);
    /// @notice Emitted when a token is sold and transferred to the seller
    event TokenSold(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 salePrice);
    /// @notice Emitted when a token sale is cancelled
    event TokenSaleCancelled(address indexed owner, uint256 indexed tokenId);

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
    function buyToken(address buyer, uint256 tokenId, address paymentToken) external;

    /**
     * @notice Cancels the sale of a token
     * @param tokenId The ID of the token to cancel sale for
     * @dev Resets the sale price and seller address
     */
    function cancelTokenSale(uint256 tokenId) external;

    /**
     * @notice Check if the token is on sale
     * @param _tokenId The ID of the token to check
     * @return isOnSale True if the token is on sale, false otherwise
     */
    function isTokenForSale(uint256 _tokenId) external view returns (bool);

    /**
     * @notice Check if the token is allowed for minting
     * @param _token The address of the token to check
     * @return isAllowed True if the token is allowed, false otherwise
     */
    function isTokenAllowed(address _token) external view returns (bool);

    /**
     * @notice Returns the sale price of a token.
     * @param _tokenId The ID of the token to query.
     * @return The sale price of the token.
     */
    function getTokenSalePrice(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Returns the sale information of a token.
     * @param _tokenId The ID of the token to query.
     * @return seller The address of the seller.
     * @return price The sale price of the token.
     * @return isActive Whether the token is currently for sale.
     */
    function getTokenSaleInfo(uint256 _tokenId) external view returns (address seller, uint256 price, bool isActive);

    /**
     * @notice Bulk purchase of tokens
     * @dev This function allows a buyer to purchase multiple tokens in a single transaction.
     * @param _buyer  The address of the buyer
     * @param _tokenIds  The array of token IDs to purchase
     * @param paymentToken  The address of the payment token
     */
    function batchBuyTokens(address _buyer, uint256[] calldata _tokenIds, address paymentToken) external;

    /**
     * @notice Batch sell tokens with custom prices
     * @param _tokenIds The array of token IDs to sell
     * @param _prices The array of prices for each token ID
     */
    function batchSellTokens(uint256[] calldata _tokenIds, uint256[] calldata _prices) external;

    /**
     * @notice Batch cancel token sales
     * @param _tokenIds The array of token IDs to cancel sales for
     */
    function batchCancelTokenSales(uint256[] calldata _tokenIds, address _seller) external;
}
