// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {ERC721AUpgradeable, ERC721AUpgradeableInternal} from "src/ERC721A/ERC721AUpgradeable.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {ERC721AStorage} from "src/libraries/ERC721A/ERC721AStorage.sol";
import {ERC721PermitBase} from "src/abstracts/ERC721PermitBase.sol";
import {BeanHeadsBase} from "src/abstracts/BeanHeadsBase.sol";

contract MockPermit721 is ERC721AUpgradeable, ERC721PermitBase {
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    constructor() ERC721PermitBase(address(this)) {
        ERC721AStorage.Layout storage _l = ERC721AStorage.layout();
        _l._name = "BeanHeads";
        _l._symbol = "BEANS";
    }

    function computePermitDigest(address spender, uint256 tokenId, uint256 deadline) external view returns (bytes32) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        uint256 nonce = ds.tokenNonces[tokenId];
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonce, deadline));
        return _hashTypedDataV4(structHash);
    }

    function mint(address to, uint256 quantity) external {
        _safeMint(to, quantity);
    }

    function approved(uint256 tokenId) external view returns (address) {
        return getApproved(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.supportedInterfaces[interfaceId];
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override(ERC721AUpgradeableInternal, BeanHeadsBase)
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        // Handle removal from previous owner
        if (from != address(0)) {
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = startTokenId + i;
                _removeFromOwnerTokens(ds, from, tokenId);
            }
        }

        // Handle addition to new owner
        if (to != address(0)) {
            for (uint256 i = 0; i < quantity; i++) {
                ds.ownerTokens[to].push(startTokenId + i);
            }
        }
    }
}
