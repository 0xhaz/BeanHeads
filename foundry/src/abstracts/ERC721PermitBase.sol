// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC721Permit} from "src/interfaces/IERC721Permit.sol";
import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721A} from "ERC721A/interfaces/IERC721A.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {BeanHeadsBase} from "src/abstracts/BeanHeadsBase.sol";
import {PermitTypes} from "src/types/PermitTypes.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {IBeanHeads, IBeanHeadsMarketplaceSig} from "src/interfaces/IBeanHeads.sol";

/**
 * @dev Implementation of ERC721 Permit extension allowing approvals to be made via signatures.
 * as defined in https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 */
abstract contract ERC721PermitBase is IERC721Permit, BeanHeadsBase {
    using SafeERC20 for IERC20;

    /// @dev Permit deadline has expired

    error IPermit__ERC2612ExpiredSignature(uint256 deadline);
    /// @dev Mismatched signature
    error IPermit__ERC2612InvalidSigner(address signer, address owner);
    /// @dev Invalid nonce for permit
    error IPermit__InvalidNonce(uint256 expected, uint256 actual);

    /// solhint-disable var-name-mixedcase
    /// Cache the domain separator as an immutable value, but also store the chain id that it corresponds to
    /// in order to invalidate the cached domain separator when the chain id changes.

    /// EIP-712 / 4494 constants
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private _NAME_HASH = keccak256(bytes("BeanHeads"));
    bytes32 private _VERSION_HASH = keccak256(bytes("1"));

    /// ERC-4494 Permit struct
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    /*//////////////////////////////////////////////////////////////
                                EIP-712 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the EIP-712 domain separator for this contract
     * @return fields The fields of the domain
     * @return name The name of the contract
     * @return version The version of the contract
     * @return chainId The chain ID of the current network
     * @return verifyingContract The address of this contract
     * @return salt A salt value (not used)
     * @return extensions An empty array (no extensions)
     */
    function eip712Domain()
        public
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            "BeanHeads",
            "1",
            block.chainid,
            address(this),
            bytes32(0), // salt is not used
            new uint256[](0) // no extensions
        );
    }

    /**
     * @notice Returns the domain separator for the current chain
     * @return The bytes32 representation of the domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _NAME_HASH, _VERSION_HASH, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 _structHash) internal view returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), _structHash);
    }

    /*//////////////////////////////////////////////////////////////
                                ERC-4494
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the nonce of an NFT - useful for creating permits
     * @param tokenId The index of the NFT to get the nonce of
     * @return The uint256 representation of the nonce
     */
    function nonces(uint256 tokenId) external view returns (uint256) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.tokenNonces[tokenId];
    }

    /**
     * @notice Function to approve by way of owner signature
     * @param spender The address to approve
     * @param tokenId The index of the NFT to approve the spender on
     * @param deadline A timestamp expiry for the permit
     * @param sig A traditional or EIP-2098 signature
     */
    function permit(address spender, uint256 tokenId, uint256 deadline, bytes memory sig) external {
        _permit(spender, tokenId, deadline, sig);
    }

    function _permit(address spender, uint256 tokenId, uint256 deadline, bytes memory sig) internal virtual {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= deadline) {
            revert IPermit__ERC2612ExpiredSignature(deadline);
        }

        address owner = ownerOf(tokenId);
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        uint256 nonce = ds.tokenNonces[tokenId];

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, spender, tokenId, nonce, deadline));
        bytes32 digest = _hashTypedDataV4(structHash);

        (address recovered,,) = ECDSA.tryRecover(digest, sig);
        bool ok = (recovered != address(0) && (recovered == owner || isApprovedForAll(owner, recovered)))
        // Accept ERC1271 owner contract wallet
        || _isValidContractERC1271Signature(owner, digest, sig);

        require(ok, "ERC721Permit: Invalid signature");
        // bump nonce after successful verification
        unchecked {
            ds.tokenNonces[tokenId] = nonce + 1;
        }

        _approve(spender, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks if the spender is approved or the owner of the token
     * @param spender The address to check
     * @param tokenId The ID of the token
     * @return bool indicating if the spender is approved or owner
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @notice Checks if the signature is valid for a contract using ERC-1271
     * @param signer The address of the signer
     * @param digest The hash of the message
     * @param sig The signature to verify
     * @return bool indicating if the signature is valid
     */
    function _isValidContractERC1271Signature(address signer, bytes32 digest, bytes memory sig)
        internal
        view
        returns (bool)
    {
        if (signer.code.length == 0) return false; // Not a contract
        (bool success, bytes memory result) =
            signer.staticcall(abi.encodeWithSelector(IERC1271.isValidSignature.selector, digest, sig));

        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }

    /**
     * @notice Checks the allowance and balance of a payment token
     * @param token The ERC20 token to check
     * @param owner The address of the token owner
     * @param amount The amount to check
     */
    function _checkPaymentPermitTokenAllowanceAndBalance(IERC20 token, address owner, uint256 amount) internal view {
        if (token.allowance(owner, address(this)) < amount) {
            _revert(IBeanHeadsBase__InsufficientAllowance.selector);
        }
        if (token.balanceOf(owner) < amount) {
            _revert(IBeanHeadsBase__InsufficientPayment.selector);
        }
    }

    function _executeCancelWithPermit(PermitTypes.Cancel calldata c) internal {
        if (block.timestamp > c.deadline) _revert(IPermit__ERC2612ExpiredSignature.selector);

        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        unchecked {
            ds.tokenNonces[c.tokenId]++;
        }

        IERC721A(address(this)).transferFrom(address(this), c.seller, c.tokenId);

        ds.tokenIdToListing[c.tokenId] = BHStorage.Listing({seller: address(0), price: 0, isActive: false});

        emit IBeanHeadsMarketplaceSig.TokenSaleCancelledCrossChain(c.seller, c.tokenId);
    }

    /**
     * @notice Verifies the sell signature
     * @param s The sell parameters
     * @param sellSig The signature for the sell permit
     */
    function _verifySellSig(PermitTypes.Sell calldata s, bytes calldata sellSig) internal view {
        bytes32 structHash =
            keccak256(abi.encode(PermitTypes.SELL_TYPEHASH, s.owner, s.tokenId, s.price, s.nonce, s.deadline));
        bytes32 digest = _hashTypedDataV4(structHash);
        (address signer,,) = ECDSA.tryRecover(digest, sellSig);
        bool ok = signer == s.owner || _isValidContractERC1271Signature(s.owner, digest, sellSig);
        if (!ok) _revert(IPermit__ERC2612InvalidSigner.selector);
    }

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
     * @notice Verifies the cancel signature
     * @param c The cancel parameters
     * @param cancelSig The signature for the cancel permit
     */
    function _verifyCancelSig(PermitTypes.Cancel calldata c, bytes calldata cancelSig) internal view {
        bytes32 structHash =
            keccak256(abi.encode(PermitTypes.CANCEL_TYPEHASH, c.seller, c.tokenId, c.listingNonce, c.deadline));
        bytes32 digest = _hashTypedDataV4(structHash);
        (address signer,,) = ECDSA.tryRecover(digest, cancelSig);
        bool ok = signer == c.seller || _isValidContractERC1271Signature(c.seller, digest, cancelSig);
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

    /**
     * @notice Calculates the payment information for a buy request
     * @param b The buy parameters
     * @param priceUsd The price in USD
     * @return L The calculated payment information
     */
    function _calculatePaymentInfo(PermitTypes.Buy calldata b, uint256 priceUsd)
        internal
        view
        returns (PermitTypes.BuyLocals memory L)
    {
        if (priceUsd > b.maxPriceUsd) {
            _revert(IBeanHeadsMarketplaceSig.IBeanHeadsMarketplaceSig__PriceExceedsMax.selector);
        }

        L.priceUsd = priceUsd;
        L.adjustedPrice = _getTokenAmountFromUsd(b.paymentToken, priceUsd);
        (L.royaltyReceiver, L.royaltyUsd) = _royaltyInfo(b.tokenId, priceUsd);
        L.royaltyAmount = _getTokenAmountFromUsd(b.paymentToken, L.royaltyUsd);
        L.sellerAmount = L.adjustedPrice - L.royaltyAmount;

        return L;
    }

    /**
     * @notice Handles the payment and permit for a buy request
     * @param b The buy parameters
     * @param permitValue The value for the permit
     * @param permitDeadline The deadline for the permit
     * @param v The v component of the ECDSA signature
     * @param r The r component of the ECDSA signature
     * @param s The s component of the ECDSA signature
     * @param L The calculated payment information
     */
    function _handlePaymentAndPermit(
        PermitTypes.Buy calldata b,
        uint256 permitValue,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        PermitTypes.BuyLocals memory L
    ) internal {
        IERC20 token = IERC20(b.paymentToken);
        uint256 bal = token.balanceOf(address(this));

        if (bal < L.adjustedPrice) {
            uint256 need = L.adjustedPrice - bal;

            _tryPermitOrCheck(IERC20Permit(b.paymentToken), token, b.buyer, permitValue, permitDeadline, v, r, s, need);

            token.safeTransferFrom(b.buyer, address(this), need);
        }
    }

    /**
     * @notice Distributes the payment to the seller and royalty receiver
     * @param token The payment token
     * @param seller The address of the seller
     * @param L The calculated payment information
     */
    function _distributePayment(IERC20 token, address seller, PermitTypes.BuyLocals memory L) internal {
        if (L.royaltyAmount > 0) {
            token.safeTransfer(L.royaltyReceiver, L.royaltyAmount);
            emit IBeanHeadsMarketplaceSig.RoyaltyPaidCrossChain(
                L.royaltyReceiver, L.priceUsd, L.priceUsd, L.royaltyAmount
            );
        }

        token.safeTransfer(seller, L.sellerAmount);
    }
}
