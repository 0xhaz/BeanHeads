// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC721Permit} from "src/interfaces/IERC721Permit.sol";

import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {BeanHeadsBase} from "src/abstracts/BeanHeadsBase.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";

/**
 * @dev Implementation of ERC721 Permit extension allowing approvals to be made via signatures.
 * as defined in https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 */
abstract contract ERC721PermitBase is IERC721Permit, EIP712, BeanHeadsBase {
    /// @dev Permit deadline has expired
    error IPermit__ERC2612ExpiredSignature(uint256 deadline);
    /// @dev Mismatched signature
    error IPermit__ERC2612InvalidSigner(address signer, address owner);
    /// @dev Invalid nonce for permit
    error IPermit__InvalidNonce(uint256 expected, uint256 actual);

    /// solhint-disable var-name-mixedcase
    /// Cache the domain separator as an immutable value, but also store the chain id that it corresponds to
    /// in order to invalidate the cached domain separator when the chain id changes.

    bytes32 private immutable CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable CACHE_CHAIN_ID;
    bytes32 private immutable HASHED_NAME;
    bytes32 private immutable HASHED_VERSION;
    address private immutable CACHED_THIS;

    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter,
     * and setting `version` to "1".
     * @notice Using the same `name` that is defined in the ERC721 contract.
     */
    constructor(address _diamondAddress) EIP712("BeanHeads", "1") {
        HASHED_NAME = keccak256(bytes("BeanHeads"));
        HASHED_VERSION = keccak256(bytes("1"));
        CACHE_CHAIN_ID = block.chainid;
        CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(_diamondAddress);
        CACHED_THIS = _diamondAddress;
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
    function _hashTypedDataV4(bytes32 _structHash) internal view override returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(domainSeparatorV4(), _structHash);
    }

    function eip712Domain()
        public
        view
        override
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

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return domainSeparatorV4();
    }

    function permit(address spender, uint256 tokenId, uint256 deadline, bytes memory sig) external override {
        _permit(spender, tokenId, deadline, sig);
    }

    function nonces(uint256 tokenId) external view override returns (uint256) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.tokenNonces[tokenId];
    }

    function _permit(address spender, uint256 tokenId, uint256 deadline, bytes memory sig) internal virtual {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= deadline) {
            revert IPermit__ERC2612ExpiredSignature(deadline);
        }

        address owner = ownerOf(tokenId);
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        uint256 nonce = ds.tokenNonces[tokenId];

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonce, deadline));
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

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function domainSeparatorV4() internal view returns (bytes32) {
        return (address(this) == CACHED_THIS && block.chainid == CACHE_CHAIN_ID)
            ? CACHED_DOMAIN_SEPARATOR
            : _buildDomainSeparator(CACHED_THIS);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _isValidContractERC1271Signature(address signer, bytes32 digest, bytes memory sig)
        internal
        view
        returns (bool)
    {
        (bool success, bytes memory result) =
            signer.staticcall(abi.encodeWithSelector(IERC1271.isValidSignature.selector, digest, sig));

        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }

    function _buildDomainSeparator(address _diamondAddress) private view returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, HASHED_NAME, HASHED_VERSION, block.chainid, _diamondAddress));
    }
}
