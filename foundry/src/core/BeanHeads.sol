// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {Errors, Events} from "src/types/Constants.sol";

/**
 * @title BeanHeads
 * @notice BeanHeads is a customizable avatar on chain NFT collection
 * @dev Uses breeding concept to create new avatars similar to Cryptokitties
 * @dev Uses Chainlink VRF for attributes randomness
 */
contract BeanHeads is ERC721A, Ownable, IBeanHeads {
    using Base64 for bytes;
    using Strings for uint256;

    uint256 private tokenIdCounter;

    mapping(uint256 => Genesis.SVGParams) private tokenIdToParams;

    constructor() ERC721A("BeanHeads", "BEAN") Ownable(msg.sender) {}

    function mintGenesis(Genesis.SVGParams memory params) public returns (uint256) {
        tokenIdCounter++;
        tokenIdToParams[tokenIdCounter] = params;
        _mint(msg.sender, 1);

        emit Events.MintedGenesis(msg.sender, tokenIdCounter);
        return tokenIdCounter;
    }

    function getOwnerAttributes(address owner) external view returns (string[20][] memory) {}

    function getOwnerTokens(address owner) external view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(owner));
        for (uint256 i = 0; i < balanceOf(owner); i++) {
            tokens[i] = balanceOf(owner);
        }
        return tokens;
    }

    function getOwnerTokensCount(address owner) external view returns (uint256) {}

    function getOwnerTokensCount() external view returns (uint256) {}

    function getOwner() external view returns (address) {}

    function getOwnerOf(uint256 tokenId) external view returns (address) {}

    function getAttributesCount() external view returns (uint256) {}

    function getAttributesByIndex(uint256 index) external view returns (string[20] memory) {}

    function getAttributesByTokenId(uint256 tokenId) external view returns (Genesis.SVGParams memory params) {
        params = tokenIdToParams[tokenId];
    }

    function getAttributesByOwner(address owner, uint256 tokenId)
        external
        view
        returns (Genesis.SVGParams memory params)
    {
        if (owner != _msgSender()) revert Errors.NotOwner();
        params = tokenIdToParams[tokenId];
    }

    function getAttributes(uint256 tokenId) external view override returns (string memory) {}

    function randomNum(uint256 mod, uint256 seed, uint256 salt) external view override returns (uint256) {}

    function withdraw() external override {}

    function tokenURI(uint256 tokenID) public view override(ERC721A, IBeanHeads) returns (string memory) {
        // Fetch token parameters
        Genesis.SVGParams memory params = tokenIdToParams[tokenID];

        // Build attributes and image
        string memory attributes = Genesis.buildAttributes(params);
        string memory image = Genesis.generateBase64SVG(params);

        // Generate metadata JSON
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "BeanHeads #',
                tokenID.toString(),
                '", "description": "BeanHeads is a customizable avatar on chain NFT collection", "image": "',
                image,
                '", "attributes":',
                attributes,
                "}"
            )
        );

        // Return metadata as base64 encoded JSON
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
    }
}
