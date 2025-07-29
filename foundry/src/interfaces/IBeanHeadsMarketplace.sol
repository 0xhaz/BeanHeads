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
    function buyToken(uint256 tokenId, address paymentToken) external;

    /**
     * @notice Cancels the sale of a token
     * @param tokenId The ID of the token to cancel sale for
     * @dev Resets the sale price and seller address
     */
    function cancelTokenSale(uint256 tokenId) external;
}
