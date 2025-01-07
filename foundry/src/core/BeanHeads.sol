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

    string[20] private accessories;
    string[20] private bodyTypes;
    string[20] private clothes;
    string[20] private hairStyles;
    string[20] private clothesGraphics;
    string[20] private eyebrowShapes;
    string[20] private eyeShapes;
    string[20] private facialHairTypes;
    string[20] private hatStyles;
    string[20] private mouthStyles;
    string[20] private skinColors;
    string[20] private clothingColors;
    string[20] private hairColors;
    string[20] private hatColors;
    string[20] private shapeColors;
    string[20] private lipColors;
    string[20] private faceMaskColors;

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

    function getOwnerTokens(address owner) external view returns (uint256[] memory) {}

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

    function tokenURI(Genesis.SVGParams memory params, uint256 tokenID)
        external
        view
        override
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                abi.encodePacked(
                    '{"name": "BeanHeads #',
                    tokenID.toString(),
                    '", "description": "BeanHeads is a customizable avatar on chain NFT collection", "image": "',
                    '", "attributes": [',
                    accessories[params.accessory],
                    bodyTypes[params.bodyType],
                    clothes[params.clothes],
                    hairStyles[params.hairStyle],
                    clothesGraphics[params.clothesGraphic],
                    eyebrowShapes[params.eyebrowShape],
                    eyeShapes[params.eyeShape],
                    facialHairTypes[params.facialHairType],
                    hatStyles[params.hatStyle],
                    mouthStyles[params.mouthStyle],
                    skinColors[params.skinColor],
                    clothingColors[params.clothingColor],
                    hairColors[params.hairColor],
                    hatColors[params.hatColor],
                    shapeColors[params.shapeColor],
                    lipColors[params.lipColor],
                    faceMaskColors[params.faceMaskColor],
                    params.faceMask ? "true" : "false",
                    params.shapes ? "true" : "false",
                    params.lashes ? "true" : "false",
                    '"]',
                    ', "image": "',
                    "data:image/svg+xml;base64,",
                    '"}'
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
