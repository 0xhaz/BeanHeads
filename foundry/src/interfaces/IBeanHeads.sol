// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Genesis} from "src/types/Genesis.sol";

interface IBeanHeads {
    function mintGenesis(Genesis.SVGParams memory params) external returns (uint256);

    function getAttributes(uint256 tokenId) external view returns (string memory);

    function getOwnerAttributes(address owner) external view returns (string[20][] memory);

    function getOwnerTokens(address owner) external view returns (uint256[] memory);

    function getOwnerTokensCount(address owner) external view returns (uint256);

    function getOwnerTokensCount() external view returns (uint256);

    function getOwner() external view returns (address);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function getAttributesCount() external view returns (uint256);

    function getAttributesByIndex(uint256 index) external view returns (string[20] memory);

    function getAttributesByTokenId(uint256 tokenId) external view returns (Genesis.SVGParams memory);

    function getAttributesByOwner(address owner) external view returns (Genesis.SVGParams memory);

    function randomNum(uint256 mod, uint256 seed, uint256 salt) external view returns (uint256);

    function withdraw() external;
}
