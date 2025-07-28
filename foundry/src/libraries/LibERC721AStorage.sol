// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

library LibERC721AStorage {
    bytes32 internal constant STORAGE_POSITION = keccak256("erc721a.beanheads.storage");

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    struct ERC721AStorage {
        uint256 currentIndex;
        uint256 burnedCounter;
        string name;
        string symbol;
        mapping(uint256 => uint256) packedOwnerships;
        mapping(address => uint256) packedAddressData;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (ERC721AStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
