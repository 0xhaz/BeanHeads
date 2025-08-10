// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

import {ERC721PermitBase, IERC721Permit, ECDSA} from "src/abstracts/ERC721PermitBase.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {IBeanHeads, IBeanHeadsMarketplace} from "src/interfaces/IBeanHeads.sol";
import {PermitTypes} from "src/libraries/PermitTypes.sol";
import {ReentrancyLib} from "src/libraries/ReentrancyLib.sol";

contract BeanHeadsMarketplaceSigFacet is ERC721PermitBase {
    using SafeERC20 for IERC20;

    /// @notice Modifier to check if the token exists
    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            _revert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__TokenDoesNotExist.selector);
        }
        _;
    }

    /// @notice Reentrancy guard modifier
    modifier nonReentrant() {
        ReentrancyLib.enforceNotEntered();
        _;
        ReentrancyLib.resetStatus();
    }

    constructor(address diamondAddress) ERC721PermitBase(diamondAddress) {}

    function sellTokenWithPermit(
        PermitTypes.Sell calldata s,
        bytes calldata sellSig,
        uint256 permitDeadline,
        bytes calldata permitSig
    ) external {
        if (block.timestamp > s.deadline) _revert(IPermit__ERC2612ExpiredSignature.selector);
        if (s.price <= 0) {
            _revert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__PriceMustBeGreaterThanZero.selector);
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
        safeTransferFrom(s.owner, address(this), s.tokenId);
        ds.tokenIdToListing[s.tokenId] = BHStorage.Listing({seller: s.owner, price: s.price, isActive: true});

        emit IBeanHeadsMarketplace.SetTokenPrice(s.owner, s.tokenId, s.price);
    }

    function buyTokenWithPermit(
        PermitTypes.Buy calldata b,
        bytes calldata buySig,
        uint256 permitValue,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant tokenExists(b.tokenId) {
        if (block.timestamp > b.deadline) _revert(IPermit__ERC2612ExpiredSignature.selector);

        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        BHStorage.Listing storage listing = ds.tokenIdToListing[b.tokenId];

        if (!listing.isActive) _revert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__TokenNotForSale.selector);
        if (!ds.allowedTokens[b.paymentToken]) {
            _revert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__TokenNotAllowed.selector);
        }
        if (ds.tokenNonces[b.tokenId] != b.listingNonce) _revert(IPermit__InvalidNonce.selector);

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

        uint256 priceUsd = listing.price;
        uint256 adjustedPrice = _getTokenAmountFromUsd(b.paymentToken, priceUsd);
        if (priceUsd > b.maxPriceUsd) {
            _revert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__PriceExceedsMax.selector);
        }

        IERC20 token = IERC20(b.paymentToken);
        try IERC20Permit(b.paymentToken).permit(b.buyer, address(this), permitValue, permitDeadline, v, r, s) {
            // Permit was successful, continue
        } catch {
            _checkPaymentTokenAllowanceAndBalance(token, adjustedPrice);
        }

        // Transfer funds in, split royalties and transfer NFT to recipient
        token.safeTransferFrom(b.buyer, address(this), adjustedPrice);

        (address royaltyReceiver, uint256 royaltyAmount) = _royaltyInfo(b.tokenId, adjustedPrice);
        uint256 royaltyAmt = _getTokenAmountFromUsd(b.paymentToken, royaltyAmount);
        uint256 sellerAmount = adjustedPrice - royaltyAmt;

        if (royaltyAmt > 0) {
            token.safeTransfer(royaltyReceiver, royaltyAmt);
            emit IBeanHeadsMarketplace.RoyaltyPaid(royaltyReceiver, b.tokenId, priceUsd, royaltyAmt);
        }

        token.safeTransfer(listing.seller, sellerAmount);

        ds.tokenIdToPaymentToken[b.tokenId] = b.paymentToken;
        _safeTransfer(address(this), b.recipient, b.tokenId, "");

        emit IBeanHeadsMarketplace.TokenSold(b.recipient, listing.seller, b.tokenId, adjustedPrice);

        // Clear the listing
        listing.seller = address(0);
        listing.price = 0;
        listing.isActive = false;
        unchecked {
            ds.tokenNonces[b.tokenId] = b.listingNonce + 1;
        }
    }

    function cancelTokenSaleWithPermit(PermitTypes.Cancel calldata c, bytes calldata cancelSig)
        external
        tokenExists(c.tokenId)
    {
        if (block.timestamp > c.deadline) _revert(IPermit__ERC2612ExpiredSignature.selector);

        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        BHStorage.Listing storage listing = ds.tokenIdToListing[c.tokenId];

        if (!listing.isActive) _revert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__TokenNotForSale.selector);

        if (listing.seller != c.seller) _revert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__NotOwner.selector);
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

        emit IBeanHeadsMarketplace.TokenSaleCancelled(c.seller, c.tokenId);

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

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.supportedInterfaces[interfaceId];
    }

    /// @notice Inherits from IERC721Receiver interface
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector; // Return the selector for ERC721Received
    }
}
