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
import {IBeanHeadsBridge} from "src/interfaces/IBeanHeadsBridge.sol";
import {OracleLib} from "src/libraries/OracleLib.sol";

contract BeanHeadsBridge is CCIPReceiver, Ownable, IBeanHeadsBridge, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using OracleLib for AggregatorV3Interface;

    IRouterClient private immutable i_router;
    address public s_remoteBridge;
    IERC20 private s_linkToken;
    address private immutable i_beanHeadsContract;

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;

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

    /// @notice Inherits from IBeanHeadsBridge
    function setRemoteBridge(address _newRemoteBridge) external onlyOwner {
        if (_newRemoteBridge == address(0)) revert IBeanHeadsBridge__InvalidRemoteAddress();
        s_remoteBridge = _newRemoteBridge;
        remoteBridgeAddresses[_newRemoteBridge] = true;

        emit RemoteBridgeUpdated(_newRemoteBridge);
    }

    /// @notice Inherits from IBeanHeadsBridge
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

        uint256 allowance = token.allowance(msg.sender, address(this));
        uint256 balance = token.balanceOf(msg.sender);
        if (allowance < mintPayment) revert IBeanHeadsBridge__InsufficientAllowance();
        if (balance < mintPayment) revert IBeanHeadsBridge__InsufficientPayment();

        bytes memory mintGenesisCalldata = abi.encode(ActionType.MINT, _receiver, _params, _paymentToken, _amount);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({token: address(0), amount: mintPayment});
        tokenAmounts[0] = tokenAmount;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_remoteBridge),
            data: mintGenesisCalldata,
            tokenAmounts: tokenAmounts,
            feeToken: address(s_linkToken),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({
                    gasLimit: 200_000 // Set a default gas limit for the callback
                })
            )
        });

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentMintTokenRequest(messageId, _destinationChainSelector, _receiver, _amount);
    }

    /// @notice Inherits from IBeanHeadsBridge
    function sendSellTokenRequest(uint64 _destinationChainSelector, uint256 _tokenId, uint256 _price)
        external
        onlyTokenOwner(_tokenId)
        onlyRegisteredRemoteBridge
        returns (bytes32 messageId)
    {
        if (_price == 0) revert IBeanHeadsBridge__InvalidAmount();

        bytes memory sellTokenCalldata = abi.encode(ActionType.SELL, msg.sender, _tokenId, _price);

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

    /// @notice Inherits from IBeanHeadsBridge
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

        uint256 allowance = token.allowance(msg.sender, address(this));
        uint256 balance = token.balanceOf(msg.sender);
        if (allowance < _price) revert IBeanHeadsBridge__InsufficientAllowance();
        if (balance < _price) revert IBeanHeadsBridge__InsufficientPayment();

        bytes memory buyTokenCalldata = abi.encode(ActionType.BUY, msg.sender, _tokenId, _paymentToken);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({token: address(0), amount: _price});
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

        messageId = _sendCCIP(_destinationChainSelector, message);

        emit SentBuyTokenRequest(messageId, _destinationChainSelector, msg.sender, _tokenId, _price);
    }

    /**
     * @notice Sends a cancel token sale request to the remote bridge.
     * @param _destinationChainSelector The target chain selector for the cancel request.
     * @param _tokenId The ID of the token to cancel the sale for.
     * @return messageId The ID of the sent message.
     */
    function sendCancelTokenSaleRequest(uint64 _destinationChainSelector, uint256 _tokenId)
        external
        onlyTokenOwner(_tokenId)
        onlyRegisteredRemoteBridge
        returns (bytes32 messageId)
    {
        if (_tokenId == 0) revert IBeanHeadsBridge__InvalidAmount();

        bytes memory cancelTokenCalldata = abi.encode(ActionType.CANCEL, msg.sender, _tokenId);

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

    /// @notice Inherits from IBeanHeadsBridge
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

        bytes memory transferCalldata = abi.encode(ActionType.TRANSFER, _receiver, params, _tokenId, paymentToken);

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

    /// @notice Inherits from IBeanHeadsBridge
    function depositLink(uint256 amount) external onlyOwner {
        if (amount == 0) revert IBeanHeadsBridge__InvalidAmount();
        s_linkToken.transferFrom(msg.sender, address(this), amount);
    }

    /// @notice Inherits from IBeanHeadsBridge
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
            (address receiver, Genesis.SVGParams memory params, address paymentToken, uint256 amount) =
                abi.decode(rest, (address, Genesis.SVGParams, address, uint256));

            IBeanHeads(i_beanHeadsContract).mintGenesis(receiver, params, amount, paymentToken);

            emit TokenMintedCrossChain(receiver, params, amount);
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
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        if (price <= 0) revert IBeanHeadsBridge__InvalidOraclePrice(); // optional safety check

        uint8 decimals = IERC20Metadata(token).decimals();
        uint256 scale = 10 ** uint256(decimals);

        tokenAmount = (usdAmount * scale * ADDITIONAL_FEED_PRECISION) / uint256(price);
    }
}
