// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Client} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC721A} from "ERC721A/IERC721A.sol";
import {IRouterClient} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeadsBridge} from "src/interfaces/IBeanHeadsBridge.sol";
import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {PermitTypes} from "src/types/PermitTypes.sol";
import {OracleLib} from "src/libraries/OracleLib.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {console2} from "forge-std/console2.sol";

abstract contract BeanHeadsBridgeBase is IBeanHeadsBridge {
    using SafeERC20 for IERC20;
    using OracleLib for AggregatorV3Interface;

    /*//////////////////////////////////////////////////////////////
                             GLOBAL STATES
    //////////////////////////////////////////////////////////////*/

    IRouterClient public immutable i_router;
    address public s_remoteBridge;
    uint64 public s_destChain;
    IERC20 public s_linkToken;
    IERC20 public s_usdcToken;
    address public immutable i_beanHeadsContract;

    uint256 public constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant GAS_LIMIT_TRANSFER = 500_000;
    uint256 public constant GAS_LIMIT_MINT = 3_000_000;
    uint256 public constant GAS_LIMIT_BUY = 500_000;
    uint256 public constant GAS_LIMIT_SELL = 600_000;

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping to track the remote bridge address
    mapping(address remoteBridge => bool isRegistered) public remoteBridgeAddresses;

    /*//////////////////////////////////////////////////////////////
                           MESSAGE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _sendMintTokenRequest(
        uint64 _destinationChainSelector,
        address _receiver,
        Genesis.SVGParams calldata _params,
        uint256 _amount,
        address _paymentToken
    ) internal returns (bytes32 messageId) {
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
        token.safeApprove(address(i_router), 0);
        token.safeApprove(address(i_router), mintPayment);

        // Approve BeanHeads contract to spend the tokens
        token.safeApprove(address(i_beanHeadsContract), 0);
        token.safeApprove(address(i_beanHeadsContract), mintPayment);

        messageId = _sendCCIP(_destinationChainSelector, message);
    }

    function _sendSellTokenRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Sell calldata s,
        bytes calldata sellSig,
        uint256 permitDeadline,
        bytes calldata permitSig
    ) internal returns (bytes32 messageId) {
        if (s.price == 0) revert IBeanHeadsBridge__InvalidAmount();

        bytes memory encodeSellPayload = abi.encode(s, sellSig, permitDeadline, permitSig);

        Client.EVM2AnyMessage memory message = _buildCCIPMessage(
            ActionType.SELL,
            encodeSellPayload,
            new Client.EVMTokenAmount[](0), // No token transfers in this message
            GAS_LIMIT_SELL
        );

        messageId = _sendCCIP(_destinationChainSelector, message);
    }

    function _sendBuyTokenRequest(
        uint64 _destinationChainSelector,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _price
    ) internal returns (bytes32 messageId) {
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
    }

    function _sendCancelTokenSaleRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Cancel calldata c,
        bytes calldata cancelSig
    ) internal returns (bytes32 messageId) {
        bytes memory encodeCancelPayload = abi.encode(c, cancelSig);

        Client.EVM2AnyMessage memory message = _buildCCIPMessage(
            ActionType.CANCEL,
            encodeCancelPayload,
            new Client.EVMTokenAmount[](0), // No token transfers in this message
            GAS_LIMIT_SELL
        );

        messageId = _sendCCIP(_destinationChainSelector, message);
    }

    function _sendTransferTokenRequest(uint64 _destinationChainSelector, uint256 _tokenId, address _receiver)
        internal
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
    }

    function _sendBatchSellTokenRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Sell[] calldata _sellRequests,
        bytes[] calldata _sellSigs,
        uint256[] calldata _permitDeadlines,
        bytes[] calldata _permitSigs
    ) internal returns (bytes32 messageId) {
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
    }

    function _sendBatchBuyTokenRequest(
        uint64 _destinationChainSelector,
        uint256[] calldata _tokenIds,
        uint256[] calldata _prices,
        address _paymentToken
    ) internal returns (bytes32 messageId) {
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

        bytes memory encodeBuyPayload = abi.encode(msg.sender, _tokenIds, _prices, _paymentToken, totalPrice);

        Client.EVMTokenAmount[] memory tokenAmounts = _wrapToken(_paymentToken, totalPrice);

        Client.EVM2AnyMessage memory message =
            _buildCCIPMessage(ActionType.BATCH_BUY, encodeBuyPayload, tokenAmounts, GAS_LIMIT_BUY);

        // Approve router to spend the tokens
        token.safeApprove(address(i_router), totalPrice);

        messageId = _sendCCIP(_destinationChainSelector, message);
    }

    function _sendBatchCancelTokenSaleRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Cancel[] calldata _cancelRequests,
        bytes[] calldata _cancelSigs
    ) internal returns (bytes32 messageId) {
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
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/
    function setRemoteBridge(address _newRemoteBridge, bool allowed) public virtual {
        if (_newRemoteBridge == address(0)) revert IBeanHeadsBridge__InvalidRemoteAddress();
        s_remoteBridge = _newRemoteBridge;

        remoteBridgeAddresses[_newRemoteBridge] = allowed;

        emit RemoteBridgeUpdated(_newRemoteBridge);
    }

    function depositLink(uint256 amount) public virtual {
        if (amount == 0) revert IBeanHeadsBridge__InvalidAmount();
        s_linkToken.transferFrom(msg.sender, address(this), amount);
    }

    function withdrawLink(uint256 amount) public virtual {
        if (amount == 0) revert IBeanHeadsBridge__InvalidAmount();
        uint256 contractBalance = s_linkToken.balanceOf(address(this));
        if (amount > contractBalance) revert IBeanHeadsBridge__InsufficientLinkBalance(contractBalance);
        s_linkToken.safeTransfer(msg.sender, amount);
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
}
