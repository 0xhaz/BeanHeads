// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {IERC721A} from "ERC721A/interfaces/IERC721A.sol";
import {ERC721PermitBase, IERC721Permit, ECDSA} from "src/abstracts/ERC721PermitBase.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {IBeanHeadsMarketplaceSig} from "src/interfaces/IBeanHeadsMarketplaceSig.sol";
import {PermitTypes} from "src/types/PermitTypes.sol";
import {ReentrancyLib} from "src/libraries/ReentrancyLib.sol";

contract BeanHeadsMarketplaceSigFacet is ERC721PermitBase, IBeanHeadsMarketplaceSig {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice Modifier to check if the token exists
    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            _revert(IBeanHeadsMarketplaceSig__TokenDoesNotExist.selector);
        }
        _;
    }

    /// @notice Reentrancy guard modifier
    modifier nonReentrant() {
        ReentrancyLib.enforceNotEntered();
        _;
        ReentrancyLib.resetStatus();
    }

    /// @inheritdoc IBeanHeadsMarketplaceSig
    function sellTokenWithPermit(
        PermitTypes.Sell calldata s,
        bytes calldata sellSig,
        uint256 permitDeadline,
        bytes calldata permitSig
    ) public tokenExists(s.tokenId) {
        if (block.timestamp > s.deadline) _revert(IPermit__ERC2612ExpiredSignature.selector);
        if (s.price <= 0) {
            _revert(IBeanHeadsMarketplaceSig__PriceMustBeGreaterThanZero.selector);
        }

        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        uint256 nonce = ds.tokenNonces[s.tokenId];
        if (nonce != s.nonce) _revert(IPermit__InvalidNonce.selector);

        _verifySellSig(s, sellSig);

        unchecked {
            ds.tokenNonces[s.tokenId] = nonce + 1;
        }

        // consume ERC-4494 permit so this contract can pull the NFT
        IERC721Permit(address(this)).permit(address(this), s.tokenId, permitDeadline, permitSig);

        // escrow and list
        /// @dev This is a self-external call to the ERC721 contract
        IERC721A(address(this)).safeTransferFrom(s.owner, address(this), s.tokenId);
        ds.tokenIdToListing[s.tokenId] = BHStorage.Listing({seller: s.owner, price: s.price, isActive: true});

        ds.activeListings.add(s.tokenId);

        emit TokenListedCrossChain(s.owner, s.tokenId, s.price);
    }

    /// @inheritdoc IBeanHeadsMarketplaceSig
    function batchSellTokensWithPermit(
        PermitTypes.Sell[] calldata sellRequests,
        bytes[] calldata sellSigs,
        uint256[] calldata permitDeadlines,
        bytes[] calldata permitSigs
    ) external nonReentrant {
        if (
            sellRequests.length != sellSigs.length || sellRequests.length != permitDeadlines.length
                || sellRequests.length != permitSigs.length
        ) {
            _revert(IBeanHeadsMarketplaceSig__MismatchedArrayLengths.selector);
        }

        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        for (uint256 i = 0; i < sellRequests.length; i++) {
            PermitTypes.Sell calldata s = sellRequests[i];
            BHStorage.Listing storage listing = ds.tokenIdToListing[s.tokenId];

            if (!_exists(s.tokenId)) continue;
            if (listing.isActive) continue;
            if (block.timestamp > s.deadline) continue;
            if (s.price <= 0) continue;
            if (ds.tokenNonces[s.tokenId] != s.nonce) continue;

            _verifySellSig(s, sellSigs[i]);

            unchecked {
                ds.tokenNonces[s.tokenId]++;
            }

            IERC721Permit(address(this)).permit(address(this), s.tokenId, permitDeadlines[i], permitSigs[i]);
        }

        for (uint256 i = 0; i < sellRequests.length; i++) {
            PermitTypes.Sell calldata s = sellRequests[i];
            if (!_exists(s.tokenId)) continue;

            // escrow and list
            IERC721A(address(this)).transferFrom(s.owner, address(this), s.tokenId);
            ds.tokenIdToListing[s.tokenId] = BHStorage.Listing({seller: s.owner, price: s.price, isActive: true});

            emit TokenListedCrossChain(s.owner, s.tokenId, s.price);
        }
    }

    /// @inheritdoc IBeanHeadsMarketplaceSig
    function buyTokenWithPermit(
        PermitTypes.Buy calldata b,
        bytes calldata buySig,
        uint256 permitValue,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant tokenExists(b.tokenId) {
        if (block.timestamp > b.deadline) _revert(IPermit__ERC2612ExpiredSignature.selector);

        _verifyBuySig(b, buySig);

        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        BHStorage.Listing storage listing = ds.tokenIdToListing[b.tokenId];

        if (!listing.isActive) _revert(IBeanHeadsMarketplaceSig__TokenNotForSale.selector);
        if (!ds.allowedTokens[b.paymentToken]) {
            _revert(IBeanHeadsMarketplaceSig__TokenNotAllowed.selector);
        }
        if (ds.tokenNonces[b.tokenId] != b.listingNonce) _revert(IPermit__InvalidNonce.selector);

        PermitTypes.BuyLocals memory L = _calculatePaymentInfo(b, listing.price);

        _handlePaymentAndPermit(b, permitValue, permitDeadline, v, r, s, L);

        _distributePayment(IERC20(b.paymentToken), listing.seller, L);

        ds.tokenIdToPaymentToken[b.tokenId] = b.paymentToken;
        _safeTransfer(address(this), b.recipient, b.tokenId, "");

        // Clear the listing
        listing.seller = address(0);
        listing.price = 0;
        listing.isActive = false;
        unchecked {
            ds.tokenNonces[b.tokenId] = b.listingNonce + 1;
        }

        ds.activeListings.remove(b.tokenId);

        emit TokenSoldCrossChain(b.recipient, listing.seller, b.tokenId, L.adjustedPrice);
    }

    /// @inheritdoc IBeanHeadsMarketplaceSig
    function cancelTokenSaleWithPermit(PermitTypes.Cancel calldata c, bytes calldata cancelSig)
        public
        tokenExists(c.tokenId)
    {
        if (block.timestamp > c.deadline) _revert(IPermit__ERC2612ExpiredSignature.selector);

        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        BHStorage.Listing storage listing = ds.tokenIdToListing[c.tokenId];

        if (!listing.isActive) _revert(IBeanHeadsMarketplaceSig__TokenNotForSale.selector);
        if (listing.seller != c.seller) _revert(IBeanHeadsMarketplaceSig__NotOwner.selector);
        if (ds.tokenNonces[c.tokenId] != c.listingNonce) _revert(IPermit__InvalidNonce.selector);

        _verifyCancelSig(c, cancelSig);

        _safeTransfer(address(this), c.seller, c.tokenId, "");
        listing.isActive = false;
        listing.price = 0;
        listing.seller = address(0);

        emit TokenSaleCancelledCrossChain(c.seller, c.tokenId);

        unchecked {
            ds.tokenNonces[c.tokenId] = c.listingNonce + 1;
        }
    }

    /// @inheritdoc IBeanHeadsMarketplaceSig
    function batchCancelTokenSalesWithPermit(PermitTypes.Cancel[] calldata cancelRequests, bytes[] calldata cancelSigs)
        external
    {
        if (cancelRequests.length != cancelSigs.length) {
            _revert(IBeanHeadsMarketplaceSig__MismatchedArrayLengths.selector);
        }

        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        for (uint256 i = 0; i < cancelRequests.length; i++) {
            PermitTypes.Cancel calldata c = cancelRequests[i];
            BHStorage.Listing storage listing = ds.tokenIdToListing[c.tokenId];

            if (!_exists(c.tokenId)) continue;
            if (!listing.isActive) continue;
            if (block.timestamp > c.deadline) continue;
            if (ds.tokenNonces[c.tokenId] != c.listingNonce) continue;
            if (listing.seller != c.seller) continue;

            _verifyCancelSig(c, cancelSigs[i]);

            _safeTransfer(address(this), c.seller, c.tokenId, "");
            listing.isActive = false;
            listing.price = 0;
            listing.seller = address(0);

            emit TokenSaleCancelledCrossChain(c.seller, c.tokenId);

            unchecked {
                ds.tokenNonces[c.tokenId] = c.listingNonce + 1;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERFACE OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.supportedInterfaces[interfaceId];
    }

    /// @notice Required by ERC721Receiver interface
    /// @dev This function is called when a contract is the recipient of an ERC721 transfer
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector; // Return the selector for ERC721Received
    }
}
