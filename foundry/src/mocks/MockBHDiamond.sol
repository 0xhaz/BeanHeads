// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
// pragma solidity ^0.8.24;

// import {Test, console} from "forge-std/Test.sol";

// import {ERC721A} from "ERC721A/ERC721A.sol";
// import {IERC721A} from "ERC721A/interfaces/IERC721A.sol";

// import {BeanHeadsMarketplaceSigFacet} from "src/facets/BeanHeads/BeanHeadsMarketplaceSigFacet.sol";
// import {IERC721Permit, ECDSA} from "src/abstracts/ERC721PermitBase.sol";
// import {BHStorage} from "src/libraries/BHStorage.sol";
// import {PermitTypes} from "src/types/PermitTypes.sol";

// /**
//  * Mock "Diamond" that combines:
//  * - ERC721A (token logic + storage)
//  * - ERC4494 permit (writes _approve)
//  * - BeanHeadsMarketplaceSigFacet (uses _approve)
//  * - BHStorage (storage for bean heads)
//  */
// contract MockBeanHeadsDiamond is ERC712A, BeanHeadsMarketplaceSigFacet {
//     // --- EIP-712 doamin for ERC-4494 (permit) ---
//     bytes32 private immutable _HASHED_NAME;
//     bytes32 private immutable _HASHED_VERSION;
//     bytes32 private immutable _TYPE_HASH;

//     mapping(uint256 => uint256) private _nonces;

//     constructor(string memory name_, string memory symbol_) ERC712A(name_, symbol_) {
//         _HASHED_NAME = keccak256(bytes(name_));
//         _HASHED_VERSION = keccak256(bytes("1"));
//         _TYPE_HASH = keccak256(
//             abi.encodePacked("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
//         );

//         // Enable interfaces for the facet
//         BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
//         ds.supportedInterfaces[type(IERC721A).interfaceId] = true;
//         ds.supportedInterfaces[this.supportsInterface.selector] = true;
//     }

//     function nonces(uint256 tokenId) public view returns (uint256) {
//         return _nonces[tokenId];
//     }

//     function DOMAIN_SEPARATOR() public view returns (bytes32) {
//         return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, block.chainid, address(this)));
//     }

//     // ERC-4494: permit
//     function permit(address spender, uint256 tokenId, uint256 deadline, bytes calldata sig) external {
//         require(block.timestamp <= deadline, "Permit expired");

//         address owner_ = ownerOf(tokenId);
//         bytes32 structHash = keccak256(
//             abi.encode(
//                 keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"),
//                 spender,
//                 tokenId,
//                 _nonces[tokenId],
//                 deadline
//             )
//         );

//         bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));

//         (address recoveredm,,) = ECDSA.tryRecover(digest, sig);
//         require(recoveredm == owner_, "Invalid signature");

//         // bump nonce
//         unchecked {
//             _nonces[tokenId] += 1;
//         }
//         _approve(spender, tokenId);
//     }

//     // --- helpers to initialize BHStorage ---
//     function setRoyalty(address royaltyImpl) external {
//         BHStorage.diamondStorage().royaltyContract = royaltyImpl;
//     }
// }
