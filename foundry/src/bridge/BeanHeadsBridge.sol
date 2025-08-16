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

contract BeanHeadsBridge is CCIPReceiver, Ownable, IBeanHeadsBridge, ReentrancyGuard, IERC1271 {
    using SafeERC20 for IERC20;
    using OracleLib for AggregatorV3Interface;

    IRouterClient private immutable i_router;
    address public s_remoteBridge;
    IERC20 private s_linkToken;
    address private immutable i_beanHeadsContract;

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;

    /// @notice Mapping to track the remote bridge address
    mapping(address remoteBridge => bool isRegistered) public remoteBridgeAddresses;

    /// @notice Allowlist of digests that this bridge approves once
    mapping(bytes32 digest => bool isApproved) private s_approvedDigests;

    /// @notice Modifier to ensure that the remote bridge is registered
    modifier onlyRegisteredRemoteBridge() {
        if (!remoteBridgeAddresses[s_remoteBridge]) {
            revert IBeanHeadsBridge__InvalidRemoteAddress();
        }
        _;
    }

    constructor(address router, address remote, address initialOwner, address linkToken, address beanHeads)
        CCIPReceiver(router)
        Ownable(initialOwner)
    {
        i_router = IRouterClient(router);
        s_remoteBridge = remote;
        s_linkToken = IERC20(linkToken);
        i_beanHeadsContract = beanHeads;
    }

    /// @inheritdoc IBeanHeadsBridge
    function setRemoteBridge(address _newRemoteBridge) external onlyOwner {
        if (_newRemoteBridge == address(0)) revert IBeanHeadsBridge__InvalidRemoteAddress();
        s_remoteBridge = _newRemoteBridge;
        remoteBridgeAddresses[_newRemoteBridge] = true;

        emit RemoteBridgeUpdated(_newRemoteBridge);
    }

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
        bytes memory mintGenesisCalldata = abi.encode(ActionType.MINT, encodeMintPayload);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({token: _paymentToken, amount: mintPayment});
        tokenAmounts[0] = tokenAmount;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_remoteBridge),
            data: mintGenesisCalldata,
            tokenAmounts: tokenAmounts,
            feeToken: address(s_linkToken),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({
                    gasLimit: 500_000 // Set a default gas limit for the callback
                })
            )
        });

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
        bytes memory sellTokenCalldata = abi.encode(ActionType.SELL, encodeSellPayload);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_remoteBridge),
            data: sellTokenCalldata,
            tokenAmounts: new Client.EVMTokenAmount[](0), // No token transfers in this message
            feeToken: address(s_linkToken),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({
                    gasLimit: 300_000 // Set a default gas limit for the callback
                })
            )
        });

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentSellTokenRequest(messageId, _destinationChainSelector, s.owner, s.tokenId, s.price);
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
        bytes memory buyTokenCalldata = abi.encode(ActionType.BUY, encodeBuyPayload);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({token: _paymentToken, amount: _price});
        tokenAmounts[0] = tokenAmount;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_remoteBridge),
            data: buyTokenCalldata,
            tokenAmounts: tokenAmounts,
            feeToken: address(s_linkToken),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({
                    gasLimit: 200_000 // Set a default gas limit for the callback
                })
            )
        });

        // Approve router to spend the tokens
        token.safeApprove(address(i_router), _price);

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentBuyTokenRequest(messageId, _destinationChainSelector, msg.sender, _tokenId, _price);
    }

    /// @inheritdoc IBeanHeadsBridge
    function sendCancelTokenSaleRequest(
        uint64 _destinationChainSelector,
        PermitTypes.Cancel calldata c,
        bytes calldata cancelSig
    ) external onlyRegisteredRemoteBridge returns (bytes32 messageId) {
        bytes memory encodeCancelPayload = abi.encode(c, cancelSig);
        bytes memory cancelTokenCalldata = abi.encode(ActionType.CANCEL, encodeCancelPayload);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_remoteBridge),
            data: cancelTokenCalldata,
            tokenAmounts: new Client.EVMTokenAmount[](0), // No token transfers in this message
            feeToken: address(s_linkToken),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({
                    gasLimit: 200_000 // Set a default gas limit for the callback
                })
            )
        });

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit CancelSellTokenRequest(messageId, _destinationChainSelector, c.seller, c.tokenId);
    }

    /// @inheritdoc IBeanHeadsBridge
    function sendTransferTokenRequest(uint64 _destinationChainSelector, uint256 _tokenId, address _receiver)
        external
        onlyRegisteredRemoteBridge
        returns (bytes32 messageId)
    {
        if (_receiver == address(0)) revert IBeanHeadsBridge__InvalidRemoteAddress();

        uint256 originChainId = block.chainid;

        // Transfer NFT to the bridge contract
        IERC721A(address(i_beanHeadsContract)).safeTransferFrom(msg.sender, address(this), _tokenId);

        // Lock the token to prevent re-entrancy
        IBeanHeads(i_beanHeadsContract).lockToken(_tokenId);

        // Fetch the token attributes to recreate the token on the destination chain
        Genesis.SVGParams memory params = IBeanHeads(i_beanHeadsContract).getAttributesByTokenId(_tokenId);

        bytes memory encodeTransferPayload = abi.encode(_receiver, _tokenId, params, originChainId);
        bytes memory transferCalldata = abi.encode(ActionType.TRANSFER, encodeTransferPayload);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_remoteBridge),
            data: transferCalldata,
            tokenAmounts: new Client.EVMTokenAmount[](0), // No token transfers in this message
            feeToken: address(s_linkToken),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({
                    gasLimit: 500_000 // Set a default gas limit for the callback
                })
            )
        });

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentTransferTokenRequest(messageId, _destinationChainSelector, _receiver, _tokenId);
    }

    function isValidSignature(bytes32 hash, bytes calldata) external view override returns (bytes4) {
        if (msg.sender != i_beanHeadsContract) return bytes4(0);

        return s_approvedDigests[hash] ? IERC1271.isValidSignature.selector : bytes4(0);
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

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        address sender = abi.decode(message.sender, (address));

        if (sender != s_remoteBridge) revert IBeanHeadsBridge__UnauthorizedSender(sender);

        // Decode the action type from the message data
        (ActionType action, bytes memory rest) = abi.decode(message.data, (ActionType, bytes));

        if (action == ActionType.MINT) {
            /// @notice Decode the message data for minting a Genesis token.
            (address receiver, Genesis.SVGParams memory params, uint256 quantity) =
                abi.decode(rest, (address, Genesis.SVGParams, uint256));

            address bridgedToken = message.destTokenAmounts[0].token;
            uint256 bridgedAmount = message.destTokenAmounts[0].amount;

            // Approve the BeanHeads contract to spend the bridged token
            IERC20(bridgedToken).safeApprove(i_beanHeadsContract, 0);
            IERC20(bridgedToken).safeApprove(i_beanHeadsContract, bridgedAmount);

            IBeanHeads(i_beanHeadsContract).mintGenesis(receiver, params, quantity, bridgedToken);

            emit TokenMintedCrossChain(receiver, params, quantity);
        }

        if (action == ActionType.SELL) {
            /// @notice Decode the message data for selling a token.
            (PermitTypes.Sell memory s, bytes memory sellSig, uint256 permitDeadline, bytes memory permitSig) =
                abi.decode(rest, (PermitTypes.Sell, bytes, uint256, bytes));

            IBeanHeads beans = IBeanHeads(i_beanHeadsContract);

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
                abi.decode(rest, (address, uint256, address, uint256));

            price = message.destTokenAmounts[0].amount;
            paymentToken = message.destTokenAmounts[0].token;

            IERC20(paymentToken).safeApprove(i_beanHeadsContract, 0);
            IERC20(paymentToken).safeApprove(i_beanHeadsContract, price);

            IBeanHeads(i_beanHeadsContract).buyToken(buyer, buyTokenId, paymentToken);

            // IERC721A(i_beanHeadsContract).transferFrom(address(this), buyer, buyTokenId);

            emit TokenBoughtCrossChain(buyer, buyTokenId);
        }

        if (action == ActionType.CANCEL) {
            /// @notice Decode the message data for canceling a token sale.
            (PermitTypes.Cancel memory c, bytes memory cancelSig) = abi.decode(rest, (PermitTypes.Cancel, bytes));

            IBeanHeads beans = IBeanHeads(i_beanHeadsContract);

            beans.cancelTokenSaleWithPermit(c, cancelSig);

            emit TokenSaleCancelled(c.seller, c.tokenId);
        }

        if (action == ActionType.TRANSFER) {
            (address receiver, uint256 tokenId, Genesis.SVGParams memory params, uint256 originChainId) =
                abi.decode(rest, (address, uint256, Genesis.SVGParams, uint256));

            if (block.chainid != originChainId) {
                // Mint the mirror token on the destination chain
                IBeanHeads(i_beanHeadsContract).mintBridgeToken(receiver, tokenId, params);

                emit TokenMirroredOnDestinationChain(receiver, tokenId, params, originChainId);
            } else {
                returnToSourceChain(tokenId);

                // If the token is from the same chain, transfer it directly
                IERC721A(i_beanHeadsContract).safeTransferFrom(address(this), receiver, tokenId);

                IBeanHeads(i_beanHeadsContract).unlockToken(tokenId);

                emit TokenReturnedToSourceChain(tokenId);
            }

            emit TokenTransferredCrossChain(receiver, tokenId);
        }
    }

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

    function _approveDigest(bytes32 hash) internal {
        s_approvedDigests[hash] = true;
    }

    function _clearDigest(bytes32 hash) internal {
        s_approvedDigests[hash] = false;
    }

    function returnToSourceChain(uint256 tokenId) internal {
        IBeanHeads beans = IBeanHeads(i_beanHeadsContract);

        beans.burn(tokenId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector; // Return the selector for ERC721Received
    }
}
