// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {LibERC721AStorage} from "src/libraries/LibERC721AStorage.sol";

library LibERC721A {
    error LibERC721A__MintToZeroAddress();
    error LibERC721A__MintZeroQuantity();
    error LibERC721A__TokenDoesNotExist();

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function _nextTokenId() internal view returns (uint256) {
        return LibERC721AStorage.layout().currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        LibERC721AStorage.ERC721AStorage storage ds = LibERC721AStorage.layout();

        if (to == address(0)) revert LibERC721A__MintToZeroAddress();
        if (quantity == 0) revert LibERC721A__MintZeroQuantity();

        uint256 startTokenId = ds.currentIndex;
        ds.packedAddressData[to] += quantity * ((1 << 64) | 1);
        ds.packedOwnerships[startTokenId] = _packedOwnershipData(to);

        for (uint256 i; i < quantity; i++) {
            emit Transfer(address(0), to, startTokenId + i);
        }
        ds.currentIndex += quantity;
    }

    function _packedOwnershipData(address owner) private view returns (uint256 result) {
        result = uint256(uint160(owner)) | (block.timestamp << 160);
    }

    function ownerOf(uint256 tokenId) internal view returns (address) {
        LibERC721AStorage.ERC721AStorage storage ds = LibERC721AStorage.layout();
        uint256 packed = ds.packedOwnerships[tokenId];
        if (packed == 0) revert LibERC721A__TokenDoesNotExist();
        return address(uint160(packed));
    }
}
