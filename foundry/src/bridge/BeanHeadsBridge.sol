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
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeadsBridge} from "src/interfaces/IBeanHeadsBridge.sol";

contract BeanHeadsBridge is CCIPReceiver, Ownable, IBeanHeadsBridge {
    using SafeERC20 for IERC20;

    IRouterClient private immutable i_router;
    address public s_remoteBridge;
    IERC20 private s_linkToken;
    address private immutable i_beanHeadsContract;

    /// @notice Modifier to ensure that the caller is the owner
    modifier onlyTokenOwner(uint256 tokenId) {
        if (IBeanHeads(i_beanHeadsContract).getOwnerOf(tokenId) != address(this)) {
            revert IBeanHeadsBridge__TokenNotDeposited(tokenId);
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
        // if (_newRemoteBridge == address(0)) revert IBeanHeadsBridge__InvalidRemoteAddress();
        s_remoteBridge = _newRemoteBridge;

        emit RemoteBridgeUpdated(_newRemoteBridge);
    }

    /// @notice Inherits from IBeanHeadsBridge
    function sendMintTokenRequest(
        uint64 _destinationChainSelector,
        address _receiver,
        Genesis.SVGParams calldata _params,
        uint256 _amount
    ) external payable returns (bytes32 messageId) {
        if (_amount == 0) revert IBeanHeadsBridge__InvalidAmount();

        uint256 mintPayment = IBeanHeads(i_beanHeadsContract).getMintPrice() * _amount;

        require(msg.value >= mintPayment, "Insufficient payment for minting");

        bytes memory mintGenesisCalldata = abi.encode(ActionType.MINT, _receiver, _params, _amount);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: address(0), // Address(0) indicates ETH
            amount: mintPayment
        });
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

        uint256 ccipFee = i_router.getFee(_destinationChainSelector, message);

        if (ccipFee > s_linkToken.balanceOf(address(this))) revert IBeanHeadsBridge__InsufficientLinkBalance(ccipFee);

        s_linkToken.approve(address(i_router), ccipFee);

        messageId = i_router.ccipSend(_destinationChainSelector, message);

        emit SentMintTokenRequest(messageId, _destinationChainSelector, _receiver, _amount);
    }

    /// @notice Inherits from IBeanHeadsBridge
    function sendSellTokenRequest(uint64 _destinationChainSelector, uint256 _tokenId, uint256 _price)
        external
        onlyTokenOwner(_tokenId)
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

        uint256 ccipFee = i_router.getFee(_destinationChainSelector, message);

        if (ccipFee > s_linkToken.balanceOf(address(this))) revert IBeanHeadsBridge__InsufficientLinkBalance(ccipFee);

        s_linkToken.approve(address(i_router), ccipFee);

        messageId = i_router.ccipSend(_destinationChainSelector, message);

        emit SentSellTokenRequest(messageId, _destinationChainSelector, msg.sender, _tokenId, _price);
    }

    /// @notice Inherits from IBeanHeadsBridge
    function sendBuyTokenRequest(uint64 _destinationChainSelector, uint256 _tokenId, uint256 _price)
        external
        payable
        returns (bytes32 messageId)
    {
        if (_price == 0) revert IBeanHeadsBridge__InvalidAmount();

        if (msg.value < _price) revert IBeanHeadsBridge__InsufficientPayment();

        bytes memory buyTokenCalldata = abi.encode(ActionType.BUY, msg.sender, _tokenId, _price);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
            token: address(0), // Address(0) indicates ETH
            amount: _price
        });
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

        uint256 ccipFee = i_router.getFee(_destinationChainSelector, message);

        if (ccipFee > s_linkToken.balanceOf(address(this))) revert IBeanHeadsBridge__InsufficientLinkBalance(ccipFee);

        s_linkToken.approve(address(i_router), ccipFee);

        messageId = i_router.ccipSend(_destinationChainSelector, message);

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

        uint256 ccipFee = i_router.getFee(_destinationChainSelector, message);

        if (ccipFee > s_linkToken.balanceOf(address(this))) revert IBeanHeadsBridge__InsufficientLinkBalance(ccipFee);

        s_linkToken.approve(address(i_router), ccipFee);

        messageId = i_router.ccipSend(_destinationChainSelector, message);

        emit CancelSellTokenRequest(messageId, _destinationChainSelector, msg.sender, _tokenId);
    }

    /// @notice Inherits from IBeanHeadsBridge
    function sendTransferTokenRequest(uint64 _destinationChainSelector, uint256 _tokenId, address _receiver)
        external
        onlyTokenOwner(_tokenId)
        returns (bytes32 messageId)
    {
        if (_receiver == address(0)) revert IBeanHeadsBridge__InvalidRemoteAddress();

        // Transfer NFT to the bridge contract
        IERC721A(address(i_beanHeadsContract)).safeTransferFrom(msg.sender, address(this), _tokenId);

        // Fetch the token attributes to recreate the token on the destination chain
        Genesis.SVGParams memory params = IBeanHeads(i_beanHeadsContract).getAttributesByTokenId(_tokenId);

        bytes memory transferCalldata = abi.encode(ActionType.TRANSFER, _receiver, params, _tokenId);

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

        uint256 ccipFee = i_router.getFee(_destinationChainSelector, message);

        if (ccipFee > s_linkToken.balanceOf(address(this))) revert IBeanHeadsBridge__InsufficientLinkBalance(ccipFee);

        s_linkToken.approve(address(i_router), ccipFee);

        messageId = i_router.ccipSend(_destinationChainSelector, message);

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
            (address receiver, Genesis.SVGParams memory params, uint256 amount) =
                abi.decode(rest, (address, Genesis.SVGParams, uint256));

            IBeanHeads(i_beanHeadsContract).mintGenesis{value: msg.value}(receiver, params, amount);

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
            (address buyer, uint256 buyTokenId, uint256 buyPrice) = abi.decode(rest, (address, uint256, uint256));

            // Ensure the bridge owns the token
            if (IBeanHeads(i_beanHeadsContract).getOwnerOf(buyTokenId) != address(this)) {
                revert IBeanHeadsBridge__TokenNotDeposited(buyTokenId);
            }

            IBeanHeads(i_beanHeadsContract).buyToken{value: msg.value}(buyTokenId, buyPrice);
            IERC721A(address(i_beanHeadsContract)).safeTransferFrom(address(this), buyer, buyTokenId);

            emit TokenBoughtCrossChain(buyer, buyTokenId, buyPrice);
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
            (address receiver, uint256 tokenId, Genesis.SVGParams memory params) =
                abi.decode(rest, (address, uint256, Genesis.SVGParams));

            // Mint the mirror token on the destination chain
            IBeanHeads(i_beanHeadsContract).mintGenesis{value: msg.value}(receiver, params, 1);

            emit TokenTransferredCrossChain(receiver, tokenId);
        }
    }
}
