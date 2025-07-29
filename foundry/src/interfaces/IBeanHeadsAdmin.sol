// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IBeanHeadsAdmin {
    /// @notice Error thrown when the new price is not greater than zero
    error IBeanHeadsAdmin__PriceMustBeGreaterThanZero();
    /// @notice Error thrown when the provided token address is invalid
    error IBeanHeadsAdmin__InvalidTokenAddress();
    /// @notice Error thrown when an invalid address is provided
    error IBeanHeadsAdmin__InvalidAddress();

    /// @notice Event emitted when the mint price is updated
    event MintPriceUpdated(uint256 newPrice);
    /// @notice Event emitted when a token is added or removed from the allow list
    event AllowedTokenUpdated(address indexed token, bool isAllowed);
    /// @notice Event emitted when a price feed is added
    event PriceFeedAdded(address indexed token, address indexed priceFeed);

    /**
     * @notice Sets the mint price for a Genesis NFT
     * @param newPrice The new mint price in wei
     * @dev Only callable by the contract owner
     */
    function setMintPrice(uint256 newPrice) external;

    /**
     * @notice Add or remove a token from the allow list
     * @param token The address of the token to add or remove
     * @param isAllowed Whether to add (true) or remove (false) the token
     * @dev This function allows the contract owner to manage the allow list of tokens that can be used with the contract.
     */
    function setAllowedToken(address token, bool isAllowed) external;

    /**
     * @notice Adds a price feed for a token.
     * @param token The address of the token to add the price feed for.
     * @param priceFeed The address of the price feed contract.
     */
    function addPriceFeed(address token, address priceFeed) external;

    /**
     * @notice Withdraws the contract's balance to the owner's address
     * @dev Only callable by the owner
     */
    function withdraw(address paymentToken) external;

    /**
     * @notice Allows the contract owner to authorize a breeder contract
     * @param breeder The address of the breeder contract to authorize
     */
    function authorizeBreeder(address breeder) external;
}
