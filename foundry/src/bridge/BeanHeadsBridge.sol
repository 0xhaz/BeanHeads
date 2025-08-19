// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {CCIPReceiver} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IRouterClient} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721A} from "ERC721A/IERC721A.sol";
import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeadsBridge} from "src/interfaces/IBeanHeadsBridge.sol";
import {OracleLib} from "src/libraries/OracleLib.sol";
import {PermitTypes} from "src/types/PermitTypes.sol";
import {console} from "forge-std/console.sol";

contract BeanHeadsBridge is CCIPReceiver, Ownable, IBeanHeadsBridge, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using OracleLib for AggregatorV3Interface;

    /*//////////////////////////////////////////////////////////////
                             GLOBAL STATES
    //////////////////////////////////////////////////////////////*/

    IRouterClient private immutable i_router;
    address public s_remoteBridge;
    IERC20 private s_linkToken;
    address private immutable i_beanHeadsContract;

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant GAS_LIMIT_TRANSFER = 500_000;
    uint256 private constant GAS_LIMIT_MINT = 500_000;
    uint256 private constant GAS_LIMIT_BUY = 200_000;
    uint256 private constant GAS_LIMIT_SELL = 500_000;

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping to track the remote bridge address
    mapping(address remoteBridge => bool isRegistered) public remoteBridgeAddresses;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier to ensure that the remote bridge is registered
    modifier onlyRegisteredRemoteBridge() {
        if (!remoteBridgeAddresses[s_remoteBridge]) {
            revert IBeanHeadsBridge__InvalidRemoteAddress();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address router, address remote, address initialOwner, address linkToken, address beanHeads)
        CCIPReceiver(router)
        Ownable(initialOwner)
    {
        i_router = IRouterClient(router);
        s_remoteBridge = remote;
        s_linkToken = IERC20(linkToken);
        i_beanHeadsContract = beanHeads;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IBeanHeadsBridge
    function sendMintTokenRequest(
        uint64 _destinationChainSelector,
        address _receiver,
        Genesis.SVGParams calldata _params,
        uint256 _amount,
        address _paymentToken
    ) external payable onlyRegisteredRemoteBridge nonReentrant returns (bytes32 messageId) {
        if (_amount == 0) revert IBeanHeadsBridge__InvalidAmount();

        IERC20 token = IERC20(_paymentToken);
        uint256 rawMintPayment = IBeanHeads(i_beanHeadsContract).getMintPrice() * _amount;
        uint256 mintPayment = _getTokenAmountFromUsd(_paymentToken, rawMintPayment);

        _checkPaymentTokenAllowanceAndBalance(token, mintPayment);

        token.safeTransferFrom(msg.sender, address(this), mintPayment);

        bytes memory encodeMintPayload = abi.encode(_receiver, _params, _amount);

        Client.EVMTokenAmount[] memory tokenAmounts = _wrapToken(_paymentToken, mintPayment);

        Client.EVM2AnyMessage memory message =
            _buildCCIPMessage(ActionType.MINT, encodeMintPayload, tokenAmounts, GAS_LIMIT_MINT);

        // Approve router to spend the tokens
        token.safeApprove(address(i_router), mintPayment);

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentMintTokenRequest(messageId, _destinationChainSelector, _receiver, _amount);
    }

    /// @inheritdoc IBeanHeadsBridge
    function sendSellTokenRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Sell calldata s,
        bytes calldata sellSig,
        uint256 permitDeadline,
        bytes calldata permitSig
    ) external onlyRegisteredRemoteBridge returns (bytes32 messageId) {
        if (s.price == 0) revert IBeanHeadsBridge__InvalidAmount();

        bytes memory encodeSellPayload = abi.encode(s, sellSig, permitDeadline, permitSig);

        Client.EVM2AnyMessage memory message = _buildCCIPMessage(
            ActionType.SELL,
            encodeSellPayload,
            new Client.EVMTokenAmount[](0), // No token transfers in this message
            GAS_LIMIT_SELL
        );

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentSellTokenRequest(messageId, _destinationChainSelector, s.owner, s.tokenId, s.price);
    }

    function sendBatchSellTokenRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Sell[] calldata _sellRequests,
        bytes[] calldata _sellSigs,
        uint256[] calldata _permitDeadlines,
        bytes[] calldata _permitSigs
    ) external onlyRegisteredRemoteBridge returns (bytes32 messageId) {
        if (
            _sellRequests.length != _sellSigs.length || _sellRequests.length != _permitDeadlines.length
                || _sellRequests.length != _permitSigs.length
        ) {
            revert IBeanHeadsBridge__MismatchedArrayLengths();
        }

        bytes memory encodeBatchSellPayload = abi.encode(_sellRequests, _sellSigs, _permitDeadlines, _permitSigs);

        Client.EVM2AnyMessage memory message = _buildCCIPMessage(
            ActionType.BATCH_SELL,
            encodeBatchSellPayload,
            new Client.EVMTokenAmount[](0), // No token transfers in this message
            GAS_LIMIT_SELL
        );

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentBatchSellTokensRequest(_sellRequests);
    }

    /// @inheritdoc IBeanHeadsBridge
    function sendBuyTokenRequest(
        uint64 _destinationChainSelector,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _price
    ) external onlyRegisteredRemoteBridge nonReentrant returns (bytes32 messageId) {
        IERC20 token = IERC20(_paymentToken);

        // _getTokenAmountFromUsd(_paymentToken, _price);
        _checkPaymentTokenAllowanceAndBalance(token, _price);

        // Transfer the token to the bridge contract
        token.safeTransferFrom(msg.sender, address(this), _price);

        bytes memory encodeBuyPayload = abi.encode(msg.sender, _tokenId, _price, _paymentToken);

        Client.EVMTokenAmount[] memory tokenAmounts = _wrapToken(_paymentToken, _price);

        Client.EVM2AnyMessage memory message =
            _buildCCIPMessage(ActionType.BUY, encodeBuyPayload, tokenAmounts, GAS_LIMIT_BUY);

        // Approve router to spend the tokens
        token.safeApprove(address(i_router), _price);

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentBuyTokenRequest(messageId, _destinationChainSelector, msg.sender, _tokenId, _price);
    }

    function sendBatchBuyTokenRequest(
        uint64 _destinationChainSelector,
        uint256[] calldata _tokenIds,
        uint256[] calldata _prices,
        address _paymentToken
    ) external onlyRegisteredRemoteBridge nonReentrant returns (bytes32 messageId) {
        if (_tokenIds.length != _prices.length) {
            revert IBeanHeadsBridge__MismatchedArrayLengths();
        }
        if (_tokenIds.length == 0) {
            revert IBeanHeadsBridge__InvalidAmount();
        }

        IERC20 token = IERC20(_paymentToken);
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < _prices.length; i++) {
            totalPrice += _prices[i];
        }

        _checkPaymentTokenAllowanceAndBalance(token, totalPrice);

        // Transfer the token to the bridge contract
        token.safeTransferFrom(msg.sender, address(this), totalPrice);

        bytes memory encodeBuyPayload = abi.encode(msg.sender, _tokenIds, _prices, _paymentToken);

        Client.EVMTokenAmount[] memory tokenAmounts = _wrapToken(_paymentToken, totalPrice);

        Client.EVM2AnyMessage memory message =
            _buildCCIPMessage(ActionType.BATCH_BUY, encodeBuyPayload, tokenAmounts, GAS_LIMIT_BUY);

        // Approve router to spend the tokens
        token.safeApprove(address(i_router), totalPrice);

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentBatchBuyTokensRequest(messageId, _destinationChainSelector, msg.sender);
    }

    /// @inheritdoc IBeanHeadsBridge
    function sendCancelTokenSaleRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Cancel calldata c,
        bytes calldata cancelSig
    ) external onlyRegisteredRemoteBridge returns (bytes32 messageId) {
        bytes memory encodeCancelPayload = abi.encode(c, cancelSig);

        Client.EVM2AnyMessage memory message = _buildCCIPMessage(
            ActionType.CANCEL,
            encodeCancelPayload,
            new Client.EVMTokenAmount[](0), // No token transfers in this message
            GAS_LIMIT_SELL
        );

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit CancelSellTokenRequest(messageId, _destinationChainSelector, c.seller, c.tokenId);
    }

    function sendBatchCancelTokenSaleRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Cancel[] calldata _cancelRequests,
        bytes[] calldata _cancelSigs
    ) external onlyRegisteredRemoteBridge returns (bytes32 messageId) {
        if (_cancelRequests.length != _cancelSigs.length) {
            revert IBeanHeadsBridge__MismatchedArrayLengths();
        }

        bytes memory encodeBatchCancelPayload = abi.encode(_cancelRequests, _cancelSigs);

        Client.EVM2AnyMessage memory message = _buildCCIPMessage(
            ActionType.BATCH_CANCEL,
            encodeBatchCancelPayload,
            new Client.EVMTokenAmount[](0), // No token transfers in this message
            GAS_LIMIT_SELL
        );

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit CancelBatchSellTokenRequest(_cancelRequests);
    }

    /// @inheritdoc IBeanHeadsBridge
    function sendTransferTokenRequest(uint64 _destinationChainSelector, uint256 _tokenId, address _receiver)
        external
        onlyRegisteredRemoteBridge
        returns (bytes32 messageId)
    {
        if (_receiver == address(0)) revert IBeanHeadsBridge__InvalidRemoteAddress();

        Genesis.SVGParams memory params = IBeanHeads(i_beanHeadsContract).getAttributesByTokenId(_tokenId);

        IERC721A(i_beanHeadsContract).safeTransferFrom(msg.sender, address(this), _tokenId);

        (ActionType action, bytes memory transferCalldata) = _getTransferAction(_tokenId, _receiver, params);

        Client.EVM2AnyMessage memory message = _buildCCIPMessage(
            action,
            transferCalldata,
            new Client.EVMTokenAmount[](0), // No token transfers in this message
            GAS_LIMIT_TRANSFER
        );

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentTransferTokenRequest(messageId, _destinationChainSelector, _receiver, _tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IBeanHeadsBridge
    function setRemoteBridge(address _newRemoteBridge) external onlyOwner {
        if (_newRemoteBridge == address(0)) revert IBeanHeadsBridge__InvalidRemoteAddress();
        s_remoteBridge = _newRemoteBridge;
        remoteBridgeAddresses[_newRemoteBridge] = true;

        emit RemoteBridgeUpdated(_newRemoteBridge);
    }
    /// @inheritdoc IBeanHeadsBridge

    function depositLink(uint256 amount) external onlyOwner {
        if (amount == 0) revert IBeanHeadsBridge__InvalidAmount();
        s_linkToken.transferFrom(msg.sender, address(this), amount);
    }

    /// @inheritdoc IBeanHeadsBridge
    function withdrawLink(uint256 amount) external onlyOwner {
        if (amount == 0) revert IBeanHeadsBridge__InvalidAmount();
        uint256 contractBalance = s_linkToken.balanceOf(address(this));
        if (amount > contractBalance) revert IBeanHeadsBridge__InsufficientLinkBalance(contractBalance);
        s_linkToken.safeTransfer(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                           CALLBACK FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        address sender = abi.decode(message.sender, (address));

        if (sender != s_remoteBridge) revert IBeanHeadsBridge__UnauthorizedSender(sender);

        // Decode the action type from the message data
        (ActionType action, bytes memory payload) = abi.decode(message.data, (ActionType, bytes));

        IBeanHeads beans = IBeanHeads(i_beanHeadsContract);

        if (action == ActionType.MINT) {
            /// @notice Decode the message data for minting a Genesis token.
            (address receiver, Genesis.SVGParams memory params, uint256 quantity) =
                abi.decode(payload, (address, Genesis.SVGParams, uint256));

            address bridgedToken = message.destTokenAmounts[0].token;
            uint256 bridgedAmount = message.destTokenAmounts[0].amount;

            // Approve the BeanHeads contract to spend the bridged token
            _safeApproveTokens(IERC20(bridgedToken), bridgedAmount);

            beans.mintGenesis(receiver, params, quantity, bridgedToken);

            emit TokenMintedCrossChain(receiver, params, quantity);
        }

        if (action == ActionType.SELL) {
            /// @notice Decode the message data for selling a token.
            (PermitTypes.Sell memory s, bytes memory sellSig, uint256 permitDeadline, bytes memory permitSig) =
                abi.decode(payload, (PermitTypes.Sell, bytes, uint256, bytes));

            // Call facet
            beans.sellTokenWithPermit(
                s,
                sellSig, // sellSig
                permitDeadline,
                permitSig
            );

            emit TokenListedCrossChain(s.owner, s.tokenId, s.price);
        }

        if (action == ActionType.BUY) {
            /// @notice Decode the message data for buying a token.
            (address buyer, uint256 buyTokenId, address paymentToken, uint256 price) =
                abi.decode(payload, (address, uint256, address, uint256));

            price = message.destTokenAmounts[0].amount;
            paymentToken = message.destTokenAmounts[0].token;

            // Approve the BeanHeads contract to spend the bridged token
            _safeApproveTokens(IERC20(paymentToken), price);

            beans.buyToken(buyer, buyTokenId, paymentToken);

            emit TokenBoughtCrossChain(buyer, buyTokenId);
        }

        if (action == ActionType.CANCEL) {
            /// @notice Decode the message data for canceling a token sale.
            (PermitTypes.Cancel memory c, bytes memory cancelSig) = abi.decode(payload, (PermitTypes.Cancel, bytes));

            beans.cancelTokenSaleWithPermit(c, cancelSig);

            emit TokenSaleCancelled(c.seller, c.tokenId);
        }

        if (action == ActionType.TRANSFER_TO_MIRROR) {
            // Token is being sent to a **non-origin chain** → mint mirror token
            (address receiver, uint256 tokenId, Genesis.SVGParams memory params, uint256 originChainId) =
                abi.decode(payload, (address, uint256, Genesis.SVGParams, uint256));

            beans.mintBridgeToken(receiver, tokenId, params, originChainId);

            emit TokenMirroredOnDestinationChain(receiver, tokenId, params, originChainId);
        }

        if (action == ActionType.TRANSFER_TO_ORIGIN) {
            // Token is being sent to **origin chain** → burn on mirror and transfer original
            (address receiver, uint256 tokenId) = abi.decode(payload, (address, uint256));

            beans.unlockToken(tokenId); // Unlock the token on origin chain
            IERC721A(i_beanHeadsContract).safeTransferFrom(address(this), receiver, tokenId);

            emit TokenTransferredCrossChain(receiver, tokenId);
        }

        if (action == ActionType.BATCH_BUY) {
            /// @notice Decode the message data for batch buying tokens.
            (address buyer, uint256[] memory tokenIds, uint256[] memory prices, address paymentToken) =
                abi.decode(payload, (address, uint256[], uint256[], address));

            if (tokenIds.length != prices.length) revert IBeanHeadsBridge__MismatchedArrayLengths();

            for (uint256 i = 0; i < tokenIds.length; i++) {
                // Approve the BeanHeads contract to spend the bridged token
                _safeApproveTokens(IERC20(paymentToken), prices[i]);
                beans.buyToken(buyer, tokenIds[i], paymentToken);
            }

            emit BatchTokenBoughtCrossChain(buyer, paymentToken);
        }

        if (action == ActionType.BATCH_SELL) {
            /// @notice Decode the message data for batch selling tokens.
            (
                PermitTypes.Sell[] memory sellRequests,
                bytes[] memory sellSigs,
                uint256[] memory permitDeadlines,
                bytes[] memory permitSigs
            ) = abi.decode(payload, (PermitTypes.Sell[], bytes[], uint256[], bytes[]));

            if (
                sellRequests.length != sellSigs.length || sellRequests.length != permitDeadlines.length
                    || sellRequests.length != permitSigs.length
            ) {
                revert IBeanHeadsBridge__MismatchedArrayLengths();
            }

            beans.batchSellTokensWithPermit(
                sellRequests,
                sellSigs, // sellSigs
                permitDeadlines,
                permitSigs
            );

            emit BatchTokensListedCrossChain(sellRequests);
        }

        if (action == ActionType.BATCH_CANCEL) {
            /// @notice Decode the message data for batch canceling token sales.
            (PermitTypes.Cancel[] memory cancelRequests, bytes[] memory cancelSigs) =
                abi.decode(payload, (PermitTypes.Cancel[], bytes[]));

            if (cancelRequests.length != cancelSigs.length) revert IBeanHeadsBridge__MismatchedArrayLengths();

            beans.batchCancelTokenSalesWithPermit(cancelRequests, cancelSigs);

            emit BatchTokenSaleCancelledCrossChain(cancelRequests);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sends a CCIP message to the destination chain
     * @param destChain The destination chain selector
     * @param message The EVM2AnyMessage to send
     * @return messageId The ID of the sent message
     */
    function _sendCCIP(uint64 destChain, Client.EVM2AnyMessage memory message) internal returns (bytes32) {
        uint256 ccipFee = i_router.getFee(destChain, message);

        if (ccipFee > s_linkToken.balanceOf(address(this))) revert IBeanHeadsBridge__InsufficientLinkBalance(ccipFee);

        s_linkToken.approve(address(i_router), ccipFee);

        return i_router.ccipSend(destChain, message);
    }

    /**
     * @notice Converts a USD-denominated price (1e18) to token amount based on Chainlink price feed and token decimals
     * @dev Assumes price feed returns 8 decimals, so adds 1e10 precision adjustment to make up to 1e18
     * @param token The ERC20 token address used for payment
     * @param usdAmount Amount in 18-decimal USD
     * @return tokenAmount Equivalent amount of `token` based on its USD price
     */
    function _getTokenAmountFromUsd(address token, uint256 usdAmount) internal view returns (uint256 tokenAmount) {
        address feedAddress = IBeanHeads(i_beanHeadsContract).getPriceFeed(token);
        if (feedAddress == address(0)) revert IBeanHeadsBridge__InvalidToken();

        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        (, int256 answer,,,) = priceFeed.latestRoundData();
        if (answer <= 0) revert IBeanHeadsBridge__InvalidOraclePrice(); // optional safety check

        uint256 price = uint256(answer) * ADDITIONAL_FEED_PRECISION; // Adjust for 1e10 precision
        uint8 tokenDecimals = IERC20Metadata(token).decimals();

        // Required token amount = usdAmount / tokenPrice
        uint256 tokenAmountIn18 = (usdAmount * PRECISION) / price; // Convert to 18 decimals

        if (tokenDecimals < 18) {
            return tokenAmountIn18 / (10 ** (18 - tokenDecimals));
        } else if (tokenDecimals > 18) {
            return tokenAmountIn18 * (10 ** (tokenDecimals - 18));
        } else {
            return tokenAmountIn18;
        }
    }

    /**
     * @notice Check if the user's payment token's allowance and balance are sufficient
     * @param token The ERC20 token address used for payment
     * @param amount The amount to check against the user's balance and allowance
     */
    function _checkPaymentTokenAllowanceAndBalance(IERC20 token, uint256 amount) internal view {
        if (token.allowance(msg.sender, address(this)) < amount) revert IBeanHeadsBridge__InsufficientAllowance();
        if (token.balanceOf(msg.sender) < amount) revert IBeanHeadsBridge__InsufficientPayment();
    }

    /**
     * @notice Safely approves the router to spend tokens
     * @param token The ERC20 token to approve
     * @param amount The amount to approve
     */
    function _safeApproveTokens(IERC20 token, uint256 amount) internal {
        // Reset approval to 0 first to prevent issues with some tokens
        token.safeApprove(address(i_router), 0);
        token.safeApprove(address(i_router), amount);
    }

    /**
     * @notice Wraps a token and amount into an EVMTokenAmount array for CCIP
     * @param token The ERC20 token address to wrap
     * @param amount The amount of the token to wrap
     * @return wrapped An array containing the wrapped token and amount
     */
    function _wrapToken(address token, uint256 amount) internal pure returns (Client.EVMTokenAmount[] memory wrapped) {
        wrapped = new Client.EVMTokenAmount[](1);
        wrapped[0] = Client.EVMTokenAmount({token: token, amount: amount});
    }

    /**
     * @notice Builds a CCIP message for sending to the destination chain
     * @param action The action type for the message
     * @param payload The payload data for the action
     * @param tokenAmounts The token amounts to include in the message
     * @param gasLimit The gas limit for the callback on the destination chain
     * @return message The constructed EVM2AnyMessage ready for sending
     */
    function _buildCCIPMessage(
        ActionType action,
        bytes memory payload,
        Client.EVMTokenAmount[] memory tokenAmounts,
        uint256 gasLimit
    ) internal view returns (Client.EVM2AnyMessage memory) {
        return Client.EVM2AnyMessage({
            receiver: abi.encode(s_remoteBridge),
            data: abi.encode(action, payload),
            tokenAmounts: tokenAmounts,
            feeToken: address(s_linkToken),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({
                    gasLimit: gasLimit // Set a default gas limit for the callback
                })
            )
        });
    }

    /**
     * @notice Determines the action type and payload for transferring a token
     * @param tokenId The ID of the token being transferred
     * @param receiver The address receiving the token
     * @param params The SVG parameters for the token
     * @return action The action type for the transfer
     * @return payload The encoded payload for the transfer action
     */
    function _getTransferAction(uint256 tokenId, address receiver, Genesis.SVGParams memory params)
        internal
        returns (ActionType action, bytes memory payload)
    {
        uint256 originChainId = IBeanHeads(i_beanHeadsContract).getOriginChainId(tokenId);
        if (block.chainid == originChainId) {
            // Origin chain sending → lock + send mirror
            IBeanHeads(i_beanHeadsContract).lockToken(tokenId);
            action = ActionType.TRANSFER_TO_MIRROR;
            payload = abi.encode(receiver, tokenId, params, originChainId);
        } else {
            // Non-origin chain sending → unlock + burn on mirror
            IBeanHeads(i_beanHeadsContract).burnToken(tokenId);
            action = ActionType.TRANSFER_TO_ORIGIN;
            payload = abi.encode(receiver, tokenId);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           INTERFACE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector; // Return the selector for ERC721Received
    }
}
