// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {BHStorage} from "src/libraries/BHStorage.sol";
import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeadsMint} from "src/interfaces/IBeanHeadsMint.sol";
import {OracleLib} from "src/libraries/OracleLib.sol";
import {BeanHeadsBase} from "src/abstracts/BeanHeadsBase.sol";

contract BeanHeadsMintFacet is IBeanHeadsMint, BeanHeadsBase {
    using SafeERC20 for IERC20;
    using OracleLib for AggregatorV3Interface;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Modifier to check if the token exists
    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            _revert(IBeanHeadsMint__TokenDoesNotExist.selector);
        }
        _;
    }

    /// @notice Modifier to allow only bridge access
    modifier onlyBridge() {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        if (!ds.authorizedBridges[msg.sender]) {
            _revert(IBeanHeadsMint__UnauthorizedBridge.selector);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IBeanHeadsMint
    function mintGenesis(address _to, Genesis.SVGParams calldata _params, uint256 _amount, address _paymentToken)
        external
        returns (uint256 _tokenId)
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (_amount == 0) _revert(IBeanHeadsMint__InvalidAmount.selector);
        if (!ds.allowedTokens[_paymentToken]) _revert(IBeanHeadsMint__TokenNotAllowed.selector);

        IERC20 token = IERC20(_paymentToken);
        uint256 rawPrice = ds.mintPriceUsd * _amount;
        uint256 adjustedPrice = _getTokenAmountFromUsd(_paymentToken, rawPrice);

        _checkPaymentTokenAllowanceAndBalance(token, adjustedPrice);

        _tokenId = _nextTokenId();

        // Transfer tokens from the minter to the contract
        token.safeTransferFrom(msg.sender, address(this), adjustedPrice);

        _safeMint(_to, _amount);
        for (uint256 i; i < _amount; i++) {
            uint256 currentTokenId = _tokenId + i;

            // Store the token parameters
            ds.tokenIdToParams[currentTokenId] = _params;
            // Initialize the token's listing and payment token
            ds.tokenIdToListing[currentTokenId] = BHStorage.Listing({seller: address(0), price: 0, isActive: false});
            // Set the payment token and generation
            ds.tokenIdToPaymentToken[currentTokenId] = _paymentToken;
            ds.tokenIdToGeneration[currentTokenId] = 1;

            ds.tokenIdToOrigin[currentTokenId] = block.chainid;
        }

        emit MintedGenesis(_to, _tokenId);
    }

    /// @inheritdoc IBeanHeadsMint
    function mintBridgeToken(address _to, uint256 _tokenId, Genesis.SVGParams calldata _params, uint256 _originChainId)
        external
        onlyBridge
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (_exists(_tokenId)) {
            // If token already exists, contract will unlock and transfer it
            if (!ds.lockedTokens[_tokenId]) {
                _revert(IBeanHeadsMint__NotLocked.selector);
            }

            ds.lockedTokens[_tokenId] = false;

            // Transfer the token to the new owner
            address currentOwner = _ownerOf(_tokenId);
            if (currentOwner != address(0)) {
                _safeTransfer(currentOwner, _to, _tokenId, "");
            }

            emit ReturnedToSource(_to, _tokenId);
            return;
        }

        uint256 existingOrigin = ds.tokenIdToOrigin[_tokenId];

        if (existingOrigin != 0 && existingOrigin != _originChainId) {
            // If the token is already minted on another chain, revert
            _revert(IBeanHeadsMint__MultiHopNotAllowed.selector);
        }

        if (existingOrigin == 0) {
            ds.tokenIdToOrigin[_tokenId] = _originChainId;
        }

        // mint the token on destination chain
        _mintWithId(_to, _tokenId);
        ds.tokenIdToParams[_tokenId] = _params;

        emit MintedGenesis(_to, _tokenId);
    }

    /// @inheritdoc IBeanHeadsMint
    function unlockToken(uint256 _tokenId) external onlyBridge {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (!_exists(_tokenId)) _revert(IBeanHeadsMint__TokenDoesNotExist.selector);
        if (!ds.lockedTokens[_tokenId]) _revert(IBeanHeadsMint__NotLocked.selector);

        ds.lockedTokens[_tokenId] = false; // Unlock the token
    }

    /// @inheritdoc IBeanHeadsMint
    function lockToken(uint256 _tokenId) external onlyBridge {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (!_exists(_tokenId)) _revert(IBeanHeadsMint__TokenDoesNotExist.selector);
        if (ds.lockedTokens[_tokenId]) _revert(IBeanHeadsMint__AlreadyLocked.selector);

        ds.lockedTokens[_tokenId] = true; // Lock the token
    }

    /// @inheritdoc IBeanHeadsMint
    function burnToken(uint256 _tokenId) external tokenExists(_tokenId) onlyBridge {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (msg.sender != ownerOf(_tokenId)) {
            _revert(IBeanHeadsMint__NotOwner.selector);
        }

        if (ds.tokenIdToOrigin[_tokenId] == block.chainid) {
            _revert(IBeanHeadsMint__CannotBurnOriginToken.selector);
        }

        _burn(_tokenId, true);

        delete ds.tokenIdToParams[_tokenId];
        delete ds.tokenIdToListing[_tokenId];
        delete ds.tokenIdToPaymentToken[_tokenId];
        delete ds.tokenIdToOrigin[_tokenId];
        delete ds.lockedTokens[_tokenId];

        emit TokenBurned(msg.sender, _tokenId);
    }

    /// @inheritdoc ERC721AUpgradeable
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(IBeanHeadsMint, ERC721AUpgradeable)
    {
        if (msg.sender != from && !isApprovedForAll(from, msg.sender) && getApproved(tokenId) != msg.sender) {
            _revert(IBeanHeadsMint__NotOwnerOrApproved.selector);
        }
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @inheritdoc ERC721AUpgradeable
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IBeanHeadsMint, ERC721AUpgradeable)
    {
        if (msg.sender != from && !isApprovedForAll(from, msg.sender) && getApproved(tokenId) != msg.sender) {
            _revert(IBeanHeadsMint__NotOwnerOrApproved.selector);
        }
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @inheritdoc ERC721AUpgradeable
    function approve(address to, uint256 tokenId) public payable override(IBeanHeadsMint, ERC721AUpgradeable) {
        if (msg.sender != ownerOf(tokenId)) {
            _revert(IBeanHeadsMint__NotOwner.selector);
        }
        super.approve(to, tokenId);
    }

    /// @inheritdoc ERC721AUpgradeable
    function name() public view override(IBeanHeadsMint, ERC721AUpgradeable) returns (string memory) {
        return ERC721AUpgradeable.name();
    }

    /// @inheritdoc ERC721AUpgradeable
    function symbol() public view override(IBeanHeadsMint, ERC721AUpgradeable) returns (string memory) {
        return ERC721AUpgradeable.symbol();
    }

    /// @inheritdoc ERC721AUpgradeable
    function balanceOf(address owner) public view override(IBeanHeadsMint, ERC721AUpgradeable) returns (uint256) {
        return ERC721AUpgradeable.balanceOf(owner);
    }

    /// @inheritdoc IBeanHeadsMint
    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    /// @inheritdoc IBeanHeadsMint
    function getOwnerOf(uint256 _tokenId) external view tokenExists(_tokenId) returns (address) {
        return _ownerOf(_tokenId);
    }

    /// @inheritdoc IBeanHeadsMint
    function getTotalSupply() external view returns (uint256) {
        return _totalMinted();
    }
}
