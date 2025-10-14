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
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {BeanHeadsBridgeBase} from "src/abstracts/BeanHeadsBridgeBase.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeadsBridge} from "src/interfaces/IBeanHeadsBridge.sol";
import {PermitTypes} from "src/types/PermitTypes.sol";

contract BeanHeadsBridge is BeanHeadsBridgeBase, CCIPReceiver, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

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
    constructor(address router, address initialOwner, address linkToken, address usdcToken, address beanHeads)
        CCIPReceiver(router)
        Ownable(initialOwner)
    {
        i_router = IRouterClient(router);
        s_linkToken = IERC20(linkToken);
        s_usdcToken = IERC20(usdcToken);
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
        messageId = _sendMintTokenRequest(_destinationChainSelector, _receiver, _params, _amount, _paymentToken);

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
        messageId = _sendSellTokenRequest(_destinationChainSelector, s, sellSig, permitDeadline, permitSig);

        emit SentSellTokenRequest(messageId, _destinationChainSelector, s.owner, s.tokenId, s.price);
    }

    function sendBatchSellTokenRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Sell[] calldata _sellRequests,
        bytes[] calldata _sellSigs,
        uint256[] calldata _permitDeadlines,
        bytes[] calldata _permitSigs
    ) external onlyRegisteredRemoteBridge returns (bytes32 messageId) {
        messageId = _sendBatchSellTokenRequest(
            _destinationChainSelector, _sellRequests, _sellSigs, _permitDeadlines, _permitSigs
        );

        emit SentBatchSellTokensRequest(_sellRequests);
    }

    /// @inheritdoc IBeanHeadsBridge
    function sendBuyTokenRequest(
        uint64 _destinationChainSelector,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _price
    ) external onlyRegisteredRemoteBridge nonReentrant returns (bytes32 messageId) {
        messageId = _sendBuyTokenRequest(_destinationChainSelector, _tokenId, _paymentToken, _price);

        emit SentBuyTokenRequest(messageId, _destinationChainSelector, msg.sender, _tokenId, _price);
    }

    function sendBatchBuyTokenRequest(
        uint64 _destinationChainSelector,
        uint256[] calldata _tokenIds,
        uint256[] calldata _prices,
        address _paymentToken
    ) external onlyRegisteredRemoteBridge nonReentrant returns (bytes32 messageId) {
        messageId = _sendBatchBuyTokenRequest(_destinationChainSelector, _tokenIds, _prices, _paymentToken);

        emit SentBatchBuyTokensRequest(messageId, _destinationChainSelector, msg.sender);
    }

    /// @inheritdoc IBeanHeadsBridge
    function sendCancelTokenSaleRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Cancel calldata c,
        bytes calldata cancelSig
    ) external onlyRegisteredRemoteBridge returns (bytes32 messageId) {
        messageId = _sendCancelTokenSaleRequest(_destinationChainSelector, c, cancelSig);

        emit CancelSellTokenRequest(messageId, _destinationChainSelector, c.seller, c.tokenId);
    }

    function sendBatchCancelTokenSaleRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Cancel[] calldata _cancelRequests,
        bytes[] calldata _cancelSigs
    ) external onlyRegisteredRemoteBridge returns (bytes32 messageId) {
        messageId = _sendBatchCancelTokenSaleRequest(_destinationChainSelector, _cancelRequests, _cancelSigs);

        emit CancelBatchSellTokenRequest(_cancelRequests);
    }

    /// @inheritdoc IBeanHeadsBridge
    function sendTransferTokenRequest(uint64 _destinationChainSelector, uint256 _tokenId, address _receiver)
        external
        onlyRegisteredRemoteBridge
        returns (bytes32 messageId)
    {
        messageId = _sendTransferTokenRequest(_destinationChainSelector, _tokenId, _receiver);

        emit SentTransferTokenRequest(messageId, _destinationChainSelector, _receiver, _tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IBeanHeadsBridge
    function setRemoteBridge(address _newRemoteBridge, bool allowed) public override onlyOwner {
        super.setRemoteBridge(_newRemoteBridge, allowed);
    }

    /// @inheritdoc IBeanHeadsBridge
    function depositLink(uint256 amount) public override onlyOwner {
        super.depositLink(amount);
    }

    /// @inheritdoc IBeanHeadsBridge
    function withdrawLink(uint256 amount) public override onlyOwner {
        super.withdrawLink(amount);
    }

    /*//////////////////////////////////////////////////////////////
                           CALLBACK FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        address sender = abi.decode(message.sender, (address));

        if (sender != s_remoteBridge) {
            revert IBeanHeadsBridge__UnauthorizedSender(sender);
        }

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
            (
                address buyer,
                uint256[] memory tokenIds,
                uint256[] memory prices,
                address paymentToken,
                uint256 totalPrice
            ) = abi.decode(payload, (address, uint256[], uint256[], address, uint256));

            if (tokenIds.length != prices.length) {
                revert IBeanHeadsBridge__MismatchedArrayLengths();
            }

            paymentToken = message.destTokenAmounts[0].token;
            uint256 bridgedAmount = message.destTokenAmounts[0].amount;

            if (bridgedAmount != totalPrice) {
                revert IBeanHeadsBridge__InvalidAmount();
            }

            _safeApproveTokens(IERC20(paymentToken), type(uint256).max);

            beans.batchBuyTokens(buyer, tokenIds, paymentToken);

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

            beans.batchSellTokensWithPermit(sellRequests, sellSigs, permitDeadlines, permitSigs);

            emit BatchTokensListedCrossChain(sellRequests);
        }

        if (action == ActionType.BATCH_CANCEL) {
            /// @notice Decode the message data for batch canceling token sales.
            (PermitTypes.Cancel[] memory cancelRequests, bytes[] memory cancelSigs) =
                abi.decode(payload, (PermitTypes.Cancel[], bytes[]));

            if (cancelRequests.length != cancelSigs.length) {
                revert IBeanHeadsBridge__MismatchedArrayLengths();
            }

            beans.batchCancelTokenSalesWithPermit(cancelRequests, cancelSigs);

            emit BatchTokenSaleCancelledCrossChain(cancelRequests);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           INTERFACE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector; // Return the selector for ERC721Received
    }
}
