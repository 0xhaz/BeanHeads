// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Genesis} from "src/types/Genesis.sol";
import {PermitTypes} from "src/types/PermitTypes.sol";

interface IBeanHeadsBridge {
    /// @notice Error thrown when the remote bridge address is invalid
    error IBeanHeadsBridge__InvalidRemoteAddress();
    /// @notice Error thrown when the LINK balance is insufficient
    error IBeanHeadsBridge__InsufficientLinkBalance(uint256 amount);
    /// @notice Error thrown when the amount is invalid
    error IBeanHeadsBridge__InvalidAmount();
    /// @notice Error thrown when the sender is not authorized
    error IBeanHeadsBridge__UnauthorizedSender(address sender);
    /// @notice Error thrown when the token is not deposited
    error IBeanHeadsBridge__TokenNotDeposited(uint256 tokenId);
    /// @notice Error thrown when the payment is insufficient
    error IBeanHeadsBridge__InsufficientPayment();
    /// @notice Error thrown when the token is not locked
    error IBeanHeadsBridge__InvalidTokenReceived();
    /// @notice Error thrown when the token is not allowed for minting
    error IBeanHeadsBridge__InvalidToken();
    /// @notice Error thrown when the oracle price is invalid
    error IBeanHeadsBridge__InvalidOraclePrice();
    /// @notice Error thrown when the token is not set for sale
    error IBeanHeadsBridge__TokenNotAllowed(address token);
    /// @notice Error thrown when the token is not for sale
    error IBeanHeadsBridge__TokenIsNotForSale();
    /// @notice Error thrown when the allowance for the payment token is insufficient
    error IBeanHeadsBridge__InsufficientAllowance();
    /// @notice Error thrown when there's an invalid nonce
    error IBeanHeadsBridge__InvalidNonce();
    /// @notice Error thrown when the message length is invalid
    error IBeanHeadsBridge__InvalidLength();
    /// @notice Error thrown when the token does not exist
    error IBeanHeadsBridge__InvalidPaymentToken(address received, address expected);
    /// @notice Error thrown when the price exceeds the maximum allowed value
    error IBeanHeadsBridge__PriceExceedsMax();
    /// @notice Error thrown when the token length does not match the price length
    error IBeanHeadsBridge__MismatchedArrayLengths();

    enum ActionType {
        MINT,
        SELL,
        BUY,
        CANCEL,
        TRANSFER_TO_MIRROR,
        TRANSFER_TO_ORIGIN,
        BATCH_BUY,
        BATCH_SELL,
        BATCH_CANCEL
    }

    /// @notice Emitted when the remote bridge address is updated.
    event RemoteBridgeUpdated(address newRemoteBridge);

    /// @notice Emitted when a mint token request is sent.
    event SentMintTokenRequest(
        bytes32 indexed messageId, uint64 indexed destinationChainSelector, address indexed receiver, uint256 amount
    );

    /// @notice Emitted when a sell token request is sent.
    event SentSellTokenRequest(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address indexed receiver,
        uint256 tokenId,
        uint256 price
    );

    /// @notice Emitted when a batch sell tokens request is sent.
    event SentBatchSellTokensRequest(PermitTypes.Sell[] sellRequests);

    /// @notice Emitted when a buy token request is sent.
    event SentBuyTokenRequest(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address indexed receiver,
        uint256 tokenId,
        uint256 price
    );

    /// @notice Emitted when a batch buy tokens request is sent.
    event SentBatchBuyTokensRequest(
        bytes32 indexed messageId, uint64 indexed destinationChainSelector, address indexed receiver
    );

    /// @notice Emitted when a token transfer request is sent.
    event SentTransferTokenRequest(
        bytes32 indexed messageId, uint64 indexed destinationChainSelector, address indexed receiver, uint256 tokenId
    );

    /// @notice Emitted when a cancel token sale request is sent.
    event CancelSellTokenRequest(
        bytes32 indexed messageId, uint64 indexed destinationChainSelector, address indexed receiver, uint256 tokenId
    );

    /// @notice Emitted when a batch cancel token sales request is sent.
    event CancelBatchSellTokenRequest(PermitTypes.Cancel[] cancelRequests);

    /// @notice Emitted when a token is bought cross-chain.
    event TokenBoughtCrossChain(address indexed buyer, uint256 tokenId);

    /// @notice Emitted when a token is bought in batch cross-chain.
    event BatchTokenBoughtCrossChain(address indexed buyer, address indexed paymentToken);

    /// @notice Emitted when a token is minted cross-chain.
    event TokenMintedCrossChain(
        address indexed receiver, Genesis.SVGParams params, uint256 tokenId, address paymentToken, uint256 amount
    );

    /// @notice Emitted when a token is listed for sale cross-chain.
    event TokenListedCrossChain(address indexed seller, uint256 tokenId, uint256 price);

    /// @notice Emitted when a batch of tokens is listed for sale cross-chain.
    event BatchTokensListedCrossChain(PermitTypes.Sell[] sellRequests);

    /// @notice Emitted when a token sale is cancelled cross-chain.
    event TokenSaleCancelled(address indexed owner, uint256 tokenId);

    /// @notice Emitted when a token is transferred cross-chain.
    event TokenTransferredCrossChain(address indexed receiver, uint256 tokenId);

    /// @notice Emitted when a batch of tokens is cancelled cross-chain.
    event BatchTokenSaleCancelledCrossChain(PermitTypes.Cancel[] cancelRequests);

    /// @notice Emitted when the token return to the source chain.
    event TokenReturnedToSourceChain(uint256 tokenId);

    /// @notice Emitted when a token is mirrored on the destination chain.
    event TokenMirroredOnDestinationChain(
        address indexed receiver, uint256 tokenId, Genesis.SVGParams params, uint256 originChainId
    );

    /**
     * @notice Updates the trusted remote bridge address.
     * @dev Only callable by the owner.
     * @param _newRemoteBridge The new remote bridge address.
     * @param allowed Whether the new remote bridge is allowed.
     */
    function setRemoteBridge(uint64 _chainSelector, address _newRemoteBridge, bool allowed) external;

    /**
     * @notice Initiates a cross-chain mint token request.
     * @param _destinationChainSelector The target chain selector for the mint request.
     * @param _receiver The address that will receive the minted token.
     * @param _params The SVG parameters for the token to be minted.
     * @param _amount The amount of tokens to be minted.
     * @param _paymentToken The address of the payment token used for the minting.
     * @return messageId The ID of the sent message.
     */
    function sendMintTokenRequest(
        uint64 _destinationChainSelector,
        address _receiver,
        Genesis.SVGParams calldata _params,
        uint256 _amount,
        address _paymentToken
    ) external payable returns (bytes32 messageId);

    /**
     * @notice Sends a sell token request to the remote bridge.
     * @param _destinationChainSelector The target chain selector for the sell request.
     * @param s The struct containing the sell parameters.
     * @param sellSig The signature of the seller authorizing the sale.
     * @param permitDeadline The deadline for the permit signature.
     * @param permitSig The signature for the permit, if applicable.
     * @return messageId The ID of the sent message.
     */
    function sendSellTokenRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Sell calldata s,
        bytes calldata sellSig,
        uint256 permitDeadline,
        bytes calldata permitSig
    ) external returns (bytes32 messageId);

    /**
     * @notice Sends a batch sell tokens request to the remote bridge.
     * @param sellRequests The array of sell requests containing token IDs and prices.
     * @param sellSigs The signatures for the sell permits.
     * @param permitDeadlines The deadlines for the permits.
     * @param permitSigs The signatures for the permits.
     * @return messageId The ID of the sent message.
     */
    function sendBatchSellTokenRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Sell[] calldata sellRequests,
        bytes[] calldata sellSigs,
        uint256[] calldata permitDeadlines,
        bytes[] calldata permitSigs
    ) external returns (bytes32 messageId);

    /**
     * @notice Send the buyToken request to the remote bridge.
     * @param _destinationChainSelector The target chain selector for the buy request.
     * @param _tokenId The ID of the token to be bought.
     * @return messageId The ID of the sent message.
     */
    function sendBuyTokenRequest(
        uint64 _destinationChainSelector,
        uint256 _tokenId,
        address _paymentToken,
        uint256 price
    ) external returns (bytes32 messageId);

    /**
     * @notice Sends a batch buy tokens request to the remote bridge.
     * @param _destinationChainSelector The target chain selector for the buy request.
     * @param _tokenIds The array of token IDs to purchase.
     * @param _prices The array of prices for each token ID.
     * @param _paymentToken The address of the payment token.
     * @return messageId The ID of the sent message.
     */
    function sendBatchBuyTokenRequest(
        uint64 _destinationChainSelector,
        uint256[] calldata _tokenIds,
        uint256[] calldata _prices,
        address _paymentToken
    ) external returns (bytes32 messageId);

    /**
     * @notice Sends a cancel token sale request to the remote bridge.
     * @param _destinationChainSelector The target chain selector for the cancel request.
     * @param c The struct containing the cancel parameters.
     * @param cancelSig The signature of the seller authorizing the cancellation.
     * @return messageId The ID of the sent message.
     */
    function sendCancelTokenSaleRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Cancel calldata c,
        bytes calldata cancelSig
    ) external returns (bytes32 messageId);

    /**
     * @notice Sends a batch cancel token sales request to the remote bridge.
     * @param _destinationChainSelector The target chain selector for the cancel request.
     * @param cancelRequests The array of cancel requests containing token IDs.
     * @param cancelSigs The signatures for the cancel permits.
     * @return messageId The ID of the sent message.
     */
    function sendBatchCancelTokenSaleRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Cancel[] calldata cancelRequests,
        bytes[] calldata cancelSigs
    ) external returns (bytes32 messageId);

    /**
     * @notice Initiates a cross-chain transfer of a token.
     * @param _destinationChainSelector The target chain selector for the transfer.
     * @param _tokenId The ID of the token to be transferred.
     * @param _receiver The address that will receive the transferred token.
     * @return messageId The ID of the sent message.
     */
    function sendTransferTokenRequest(uint64 _destinationChainSelector, uint256 _tokenId, address _receiver)
        external
        returns (bytes32 messageId);

    /**
     * @notice Deposit LINK tokens to the bridge contract.
     * @dev This function allows the owner to deposit LINK tokens into the bridge contract.
     * @param amount The amount of LINK tokens to deposit.
     */
    function depositLink(uint256 amount) external;

    /**
     * @notice Withdraw LINK tokens from the bridge contract.
     * @dev This function allows the owner to withdraw LINK tokens from the bridge contract.
     * @param amount The amount of LINK tokens to withdraw.
     */
    function withdrawLink(uint256 amount) external;
}
