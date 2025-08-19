// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {PermitTypes} from "src/types/PermitTypes.sol";

interface IBeanHeadsMarketplaceSig {
    /// @notice Error thrown when the amount is invalid
    error IBeanHeadsMarketplaceSig__InvalidAmount();
    /// @notice Error thrown when the token is not allowed for minting
    error IBeanHeadsMarketplaceSig__TokenNotAllowed(address token);
    /// @notice Error thrown when the allowance for the payment token is insufficient
    error IBeanHeadsMarketplaceSig__InsufficientAllowance();
    /// @notice Error thrown when the payment for minting is insufficient
    error IBeanHeadsMarketplaceSig__InsufficientPayment();
    /// @notice Error thrown when the oracle price is invalid
    error IBeanHeadsMarketplaceSig__InvalidOraclePrice();
    /// @notice Error thrown when the token does not exist
    error IBeanHeadsMarketplaceSig__TokenDoesNotExist();
    /// @notice Error thrown when the caller is not the owner of the token
    error IBeanHeadsMarketplaceSig__NotOwner();
    /// @notice Error thrown when the caller is not the owner or approved for the token
    error IBeanHeadsMarketplaceSig__NotOwnerOrApproved();
    /// @notice Error thrown when the price is not greater than zero
    error IBeanHeadsMarketplaceSig__PriceMustBeGreaterThanZero();
    /// @notice Error thrown when the token is not for sale
    error IBeanHeadsMarketplaceSig__TokenNotForSale();
    /// @notice Error thrown when the sale price exceeds the maximum allowed price
    error IBeanHeadsMarketplaceSig__PriceExceedsMax();
    /// @notice Error thrown when the token length does not match the price length
    error IBeanHeadsMarketplaceSig__MismatchedArrayLengths();

    /// @notice Emitted when a seller sets a price for a token
    event TokenListedCrossChain(address indexed owner, uint256 indexed tokenId, uint256 price);

    /// @notice Emitted when token is sold and royalties are paid
    event RoyaltyPaidCrossChain(
        address indexed receiver, uint256 indexed tokenId, uint256 salePrice, uint256 royaltyAmount
    );
    /// @notice Emitted when a token is sold and transferred to the seller
    event TokenSoldCrossChain(
        address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 salePrice
    );
    /// @notice Emitted when a token sale is cancelled
    event TokenSaleCancelledCrossChain(address indexed owner, uint256 indexed tokenId);

    /**
     * @notice Sell token with custom price
     * @param s The sell parameters
     * @param sellSig The signature for the sell permit
     * @param permitDeadline The deadline for the permit
     * @param permitSig The signature for the permit
     */
    function sellTokenWithPermit(
        PermitTypes.Sell calldata s,
        bytes calldata sellSig,
        uint256 permitDeadline,
        bytes calldata permitSig
    ) external;

    /**
     * @notice Sells multiple tokens with custom prices using permits
     * @param sellRequests The sell requests containing token IDs and prices
     * @param sellSigs The signatures for the sell permits
     * @param permitDeadlines The deadlines for the permits
     * @param permitSigs The signatures for the permits
     */
    function batchSellTokensWithPermit(
        PermitTypes.Sell[] calldata sellRequests,
        bytes[] calldata sellSigs,
        uint256[] calldata permitDeadlines,
        bytes[] calldata permitSigs
    ) external;

    /**
     * @notice Buys a token currently on sale with a permit
     * @param b The buy parameters
     * @param buySig The signature for the buy permit
     * @param permitValue The value for the permit
     * @param permitDeadline The deadline for the permit
     * @param v The v component of the ECDSA signature
     * @param r The r component of the ECDSA signature
     * @param s The s component of the ECDSA signature
     */
    function buyTokenWithPermit(
        PermitTypes.Buy calldata b,
        bytes calldata buySig,
        uint256 permitValue,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Cancels the sale of a token with a permit
     * @param c The cancel parameters
     * @param cancelSig The signature for the cancel permit
     */
    function cancelTokenSaleWithPermit(PermitTypes.Cancel calldata c, bytes calldata cancelSig) external;

    /**
     * @notice Cancels the sale of multiple tokens with permits
     * @param cancelRequests The cancel requests containing token IDs
     * @param cancelSigs The signatures for the cancel permits
     */
    function batchCancelTokenSalesWithPermit(PermitTypes.Cancel[] calldata cancelRequests, bytes[] calldata cancelSigs)
        external;
}
