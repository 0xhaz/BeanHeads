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
import {BHStorage} from "src/libraries/BHStorage.sol";
import {IBeanHeadsMarketplaceSig} from "src/interfaces/IBeanHeadsMarketplaceSig.sol";
import {PermitTypes} from "src/types/PermitTypes.sol";
import {ReentrancyLib} from "src/libraries/ReentrancyLib.sol";

contract BeanHeadsMarketplaceSigFacet is ERC721PermitBase, IBeanHeadsMarketplaceSig {
    using SafeERC20 for IERC20;

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

        bytes32 structHash =
            keccak256(abi.encode(PermitTypes.SELL_TYPEHASH, s.owner, s.tokenId, s.price, nonce, s.deadline));
        bytes32 digest = _hashTypedDataV4(structHash);

        (address signer,,) = ECDSA.tryRecover(digest, sellSig);
        bool ok = signer == s.owner || _isValidContractERC1271Signature(s.owner, digest, sellSig);
        if (!ok) _revert(IPermit__ERC2612InvalidSigner.selector);

        unchecked {
            ds.tokenNonces[s.tokenId] = nonce + 1;
        }

        // consume ERC-4494 permit so this contract can pull the NFT
        IERC721Permit(address(this)).permit(address(this), s.tokenId, permitDeadline, permitSig);

        // escrow and list
        /// @dev This is a self-external call to the ERC721 contract
        IERC721A(address(this)).safeTransferFrom(s.owner, address(this), s.tokenId);
        ds.tokenIdToListing[s.tokenId] = BHStorage.Listing({seller: s.owner, price: s.price, isActive: true});

        emit TokenListedCrossChain(s.owner, s.tokenId, s.price);
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

        PermitTypes.BuyLocals memory L;
        L.priceUsd = listing.price;
        if (L.priceUsd > b.maxPriceUsd) _revert(IBeanHeadsMarketplaceSig__PriceExceedsMax.selector);

        L.adjustedPrice = _getTokenAmountFromUsd(b.paymentToken, L.priceUsd);

        IERC20 token = IERC20(b.paymentToken);
        uint256 bal = token.balanceOf(address(this));

        if (bal < L.adjustedPrice) {
            uint256 need = L.adjustedPrice - bal;
            _tryPermitOrCheck(IERC20Permit(b.paymentToken), token, b.buyer, permitValue, permitDeadline, v, r, s, need);

            // Transfer funds in, split royalties and transfer NFT to recipient
            token.safeTransferFrom(b.buyer, address(this), need);
        }

        (L.royaltyReceiver, L.royaltyUsd) = _royaltyInfo(b.tokenId, L.priceUsd);
        L.royaltyAmount = _getTokenAmountFromUsd(b.paymentToken, L.royaltyUsd);
        L.sellerAmount = L.adjustedPrice - L.royaltyAmount;

        if (L.royaltyAmount > 0) {
            token.safeTransfer(L.royaltyReceiver, L.royaltyAmount);
            emit RoyaltyPaidCrossChain(L.royaltyReceiver, b.tokenId, L.priceUsd, L.royaltyAmount);
        }

        token.safeTransfer(listing.seller, L.sellerAmount);

        ds.tokenIdToPaymentToken[b.tokenId] = b.paymentToken;
        _safeTransfer(address(this), b.recipient, b.tokenId, "");

        emit TokenSoldCrossChain(b.recipient, listing.seller, b.tokenId, L.adjustedPrice);

        // Clear the listing
        listing.seller = address(0);
        listing.price = 0;
        listing.isActive = false;
        unchecked {
            ds.tokenNonces[b.tokenId] = b.listingNonce + 1;
        }
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

        bytes32 structHash =
            keccak256(abi.encode(PermitTypes.CANCEL_TYPEHASH, c.seller, c.tokenId, c.listingNonce, c.deadline));
        bytes32 digest = _hashTypedDataV4(structHash);
        (address signer,,) = ECDSA.tryRecover(digest, cancelSig);
        bool ok = signer == c.seller || _isValidContractERC1271Signature(c.seller, digest, cancelSig);
        if (!ok) _revert(IPermit__ERC2612InvalidSigner.selector);

        _safeTransfer(address(this), c.seller, c.tokenId, "");
        listing.isActive = false;
        listing.price = 0;
        listing.seller = address(0);

        emit TokenSaleCancelledCrossChain(c.seller, c.tokenId);

        unchecked {
            ds.tokenNonces[c.tokenId] = c.listingNonce + 1;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ROYALTY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns the royalty information for a sale
     * @param salePrice The sale price of the token
     * @return receiver The address that will receive the royalty
     * @return royaltyAmount The amount of royalty to be paid
     */
    function _royaltyInfo(uint256 tokenId, uint256 salePrice)
        private
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        return IERC2981(ds.royaltyContract).royaltyInfo(tokenId, salePrice);
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

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies the buy signature
     * @param b The buy parameters
     * @param buySig  The signature for the buy permit
     */
    function _verifyBuySig(PermitTypes.Buy calldata b, bytes calldata buySig) internal view {
        bytes32 structHash = keccak256(
            abi.encode(
                PermitTypes.BUY_TYPEHASH,
                b.buyer,
                b.paymentToken,
                b.recipient,
                b.tokenId,
                b.maxPriceUsd,
                b.listingNonce,
                b.deadline
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        (address signer,,) = ECDSA.tryRecover(digest, buySig);
        bool ok = signer == b.buyer || _isValidContractERC1271Signature(b.buyer, digest, buySig);
        if (!ok) _revert(IPermit__ERC2612InvalidSigner.selector);
    }

    /**
     * @notice Tries to permit or checks the allowance and balance of the payment token
     * @param permitToken The token that supports ERC-20 permits
     * @param token The token to check the allowance and balance for
     * @param owner The owner of the tokens
     * @param value The value for the permit
     * @param deadline The deadline for the permit
     * @param v The v component of the ECDSA signature
     * @param r The r component of the ECDSA signature
     * @param s The s component of the ECDSA signature
     * @param amountToSpend The amount to spend from the token
     */
    function _tryPermitOrCheck(
        IERC20Permit permitToken,
        IERC20 token,
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 amountToSpend
    ) internal {
        try permitToken.permit(owner, address(this), value, deadline, v, r, s) {
            // Permit was successful, continue
        } catch {
            _checkPaymentPermitTokenAllowanceAndBalance(token, owner, amountToSpend);
        }
    }
}
