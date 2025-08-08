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
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {IBeanHeadsBridge} from "src/interfaces/IBeanHeadsBridge.sol";
import {OracleLib} from "src/libraries/OracleLib.sol";
import {console} from "forge-std/console.sol";

contract BeanHeadsBridge is CCIPReceiver, Ownable, IBeanHeadsBridge, ReentrancyGuard {
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

    /// @notice Modifier to ensure that the caller is the owner
    modifier onlyTokenOwner(uint256 tokenId) {
        if (IBeanHeads(i_beanHeadsContract).getOwnerOf(tokenId) != address(this)) {
            revert IBeanHeadsBridge__TokenNotDeposited(tokenId);
        }
        _;
    }

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
    function sendSellTokenRequest(uint64 _destinationChainSelector, uint256 _tokenId, uint256 _price)
        external
        onlyRegisteredRemoteBridge
        returns (bytes32 messageId)
    {
        if (_price == 0) revert IBeanHeadsBridge__InvalidAmount();

        bytes memory encodeSellPayload = abi.encode(msg.sender, _tokenId, _price);
        bytes memory sellTokenCalldata = abi.encode(ActionType.SELL, encodeSellPayload);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_remoteBridge),
            data: sellTokenCalldata,
            tokenAmounts: new Client.EVMTokenAmount[](0), // No token transfers in this message
            feeToken: address(s_linkToken),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({
                    gasLimit: 200_000 // Set a default gas limit for the callback
                })
            )
        });

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentSellTokenRequest(messageId, _destinationChainSelector, msg.sender, _tokenId, _price);
    }

    /// @inheritdoc IBeanHeadsBridge
    function sendBuyTokenRequest(uint64 _destinationChainSelector, uint256 _tokenId, address _paymentToken)
        external
        onlyRegisteredRemoteBridge
        nonReentrant
        returns (bytes32 messageId)
    {
        if (!IBeanHeads(i_beanHeadsContract).isTokenForSale(_tokenId)) {
            revert IBeanHeadsBridge__TokenIsNotForSale();
        }

        uint256 _rawPrice = IBeanHeads(i_beanHeadsContract).getTokenSalePrice(_tokenId);

        if (!IBeanHeads(i_beanHeadsContract).isTokenAllowed(_paymentToken)) {
            revert IBeanHeadsBridge__TokenNotAllowed(_paymentToken);
        }

        IERC20 token = IERC20(_paymentToken);
        uint256 _price = _getTokenAmountFromUsd(_paymentToken, _rawPrice);

        _checkPaymentTokenAllowanceAndBalance(token, _price);

        bytes memory encodeBuyPayload = abi.encode(msg.sender, _tokenId, _price);
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
    function sendCancelTokenSaleRequest(uint64 _destinationChainSelector, uint256 _tokenId)
        external
        onlyTokenOwner(_tokenId)
        onlyRegisteredRemoteBridge
        returns (bytes32 messageId)
    {
        if (_tokenId == 0) revert IBeanHeadsBridge__InvalidAmount();

        bytes memory encodeCancelPayload = abi.encode(msg.sender, _tokenId);
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

        emit CancelSellTokenRequest(messageId, _destinationChainSelector, msg.sender, _tokenId);
    }

    /// @inheritdoc IBeanHeadsBridge
    function sendTransferTokenRequest(
        uint64 _destinationChainSelector,
        uint256 _tokenId,
        address _receiver,
        address paymentToken
    ) external onlyTokenOwner(_tokenId) onlyRegisteredRemoteBridge returns (bytes32 messageId) {
        if (_receiver == address(0)) revert IBeanHeadsBridge__InvalidRemoteAddress();

        // Transfer NFT to the bridge contract
        IERC721A(address(i_beanHeadsContract)).safeTransferFrom(msg.sender, address(this), _tokenId);

        // Fetch the token attributes to recreate the token on the destination chain
        Genesis.SVGParams memory params = IBeanHeads(i_beanHeadsContract).getAttributesByTokenId(_tokenId);

        bytes memory encodeTransferPayload = abi.encode(_receiver, _tokenId, params, paymentToken);
        bytes memory transferCalldata = abi.encode(ActionType.TRANSFER, encodeTransferPayload);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_remoteBridge),
            data: transferCalldata,
            tokenAmounts: new Client.EVMTokenAmount[](0), // No token transfers in this message
            feeToken: address(s_linkToken),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({
                    gasLimit: 200_000 // Set a default gas limit for the callback
                })
            )
        });

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentTransferTokenRequest(messageId, _destinationChainSelector, _receiver, _tokenId);
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
            (address seller, uint256 tokenId, uint256 price) = abi.decode(rest, (address, uint256, uint256));

            // Ensure the bridge owns the token
            if (IBeanHeads(i_beanHeadsContract).getOwnerOf(tokenId) != address(this)) {
                revert IBeanHeadsBridge__TokenNotDeposited(tokenId);
            }

            IBeanHeads(i_beanHeadsContract).sellToken(tokenId, price);

            emit TokenListedCrossChain(seller, tokenId, price);
        }

        if (action == ActionType.BUY) {
            /// @notice Decode the message data for buying a token.
            (address buyer, uint256 buyTokenId, address paymentToken) = abi.decode(rest, (address, uint256, address));

            // Ensure the bridge owns the token
            if (IBeanHeads(i_beanHeadsContract).getOwnerOf(buyTokenId) != address(this)) {
                revert IBeanHeadsBridge__TokenNotDeposited(buyTokenId);
            }

            IBeanHeads(i_beanHeadsContract).buyToken(buyTokenId, paymentToken);
            IERC721A(address(i_beanHeadsContract)).safeTransferFrom(address(this), buyer, buyTokenId);

            emit TokenBoughtCrossChain(buyer, buyTokenId);
        }

        if (action == ActionType.CANCEL) {
            /// @notice Decode the message data for canceling a token sale.
            (address owner, uint256 cancelTokenId) = abi.decode(rest, (address, uint256));

            // Ensure the bridge owns the token
            if (IBeanHeads(i_beanHeadsContract).getOwnerOf(cancelTokenId) != address(this)) {
                revert IBeanHeadsBridge__TokenNotDeposited(cancelTokenId);
            }

            IBeanHeads(i_beanHeadsContract).cancelTokenSale(cancelTokenId);

            emit TokenSaleCancelled(owner, cancelTokenId);
        }

        if (action == ActionType.TRANSFER) {
            (address receiver, uint256 tokenId, Genesis.SVGParams memory params, address paymentToken) =
                abi.decode(rest, (address, uint256, Genesis.SVGParams, address));

            // Mint the mirror token on the destination chain
            IBeanHeads(i_beanHeadsContract).mintGenesis(receiver, params, 1, paymentToken);

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
}
