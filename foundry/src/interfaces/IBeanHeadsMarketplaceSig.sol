// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {PermitTypes} from "src/types/PermitTypes.sol";

interface IBeanHeadsMarketplaceSig {
    error IBeanHeadsMarketplaceSig__InvalidAmount();
    error IBeanHeadsMarketplaceSig__TokenNotAllowed(address token);
    error IBeanHeadsMarketplaceSig__InsufficientAllowance();
    error IBeanHeadsMarketplaceSig__InsufficientPayment();
    error IBeanHeadsMarketplaceSig__InvalidOraclePrice();
    error IBeanHeadsMarketplaceSig__TokenDoesNotExist();
    error IBeanHeadsMarketplaceSig__NotOwner();
    error IBeanHeadsMarketplaceSig__NotOwnerOrApproved();
    error IBeanHeadsMarketplaceSig__PriceMustBeGreaterThanZero();
    error IBeanHeadsMarketplaceSig__TokenNotForSale();
    error IBeanHeadsMarketplaceSig__PriceExceedsMax();

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

    function sellTokenWithPermit(
        PermitTypes.Sell calldata s,
        bytes calldata sellSig,
        uint256 permitDeadline,
        bytes calldata permitSig
    ) external;

    function buyTokenWithPermit(
        PermitTypes.Buy calldata b,
        bytes calldata buySig,
        uint256 permitValue,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function cancelTokenSaleWithPermit(PermitTypes.Cancel calldata c, bytes calldata cancelSig) external;
}
