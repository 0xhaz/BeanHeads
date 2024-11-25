// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Avatar} from "src/types/Avatar.sol";

/**
 * @title BeanHeads
 * @notice BeanHeads is a customizable avatar on chain NFT collection
 * @dev Uses breeding concept to create new avatars similar to Cryptokitties
 * @dev Uses Chainlink VRF for attributes randomness
 */
contract BeanHeads is ERC721Enumerable, Ownable, IBeanHeads {
    using Base64 for bytes;
    using Avatar for Avatar.Attributes;

    error BeanHeads__TokenDoesNotExist();

    mapping(uint256 => Avatar.Attributes) private _attributes;

    uint256 private tokenIdCounter;

    constructor() ERC721("BeanHeads", "BEAN") Ownable(msg.sender) {}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) revert BeanHeads__TokenDoesNotExist();

        Avatar.Attributes memory avatar = _attributes[tokenId];

        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "BeanHead #',
                            tokenIdCounter,
                            '", "description" : "BeanHeads is a customizable avatar on chain NFT collection", "attributes": [',
                            '{"trait_type": "Accessory", "value": "',
                            Avatar.getAccessory(bytes4(abi.encodePacked(avatar.accessory))),
                            '"},',
                            '{"trait_type": "Body Type", "value": "',
                            Avatar.getBody(bytes4(abi.encodePacked(avatar.bodyType))),
                            '{"trait_type": "Clothes", "value": "',
                            Avatar.getClothing(bytes4(abi.encodePacked(avatar.clothes))),
                            '{"trait_type": "Clothes Color", "value": "',
                            Avatar.getClothingColor(avatar.clothingColor),
                            '{"trait_type": "Clothes Graphic", "value": "',
                            Avatar.getClothingGraphic(bytes4(abi.encodePacked(avatar.clothesGraphic))),
                            '{"trait_type": "Eyebrow Shape", "value": "',
                            Avatar.getEyebrows(bytes4(abi.encodePacked(avatar.eyebrowShape))),
                            '{"trait_type": "Eye Shape", "value": "',
                            Avatar.getEyes(bytes4(abi.encodePacked(avatar.eyeShape))),
                            '{"trait_type": "Facial Hair Type", "value": "',
                            Avatar.getFacialHair(bytes4(abi.encodePacked(avatar.facialHairType))),
                            '{"trait_type": "Hair Style", "value": "',
                            Avatar.getHair(bytes4(abi.encodePacked(avatar.hairStyle))),
                            '{"trait_type": "Hair Color", "value": "',
                            Avatar.getHairColor(avatar.hairColor),
                            '{"trait_type": "Hat Style", "value": "',
                            Avatar.getHats(bytes4(abi.encodePacked(avatar.hatStyle))),
                            '{"trait_type": "Hat Color", "value": "',
                            Avatar.getHatColor(avatar.hatColor),
                            '{"trait_type": "Mouth Type", "value": "',
                            Avatar.getMouths(bytes4(abi.encodePacked(avatar.mouthStyle))),
                            '{"trait_type": "Lip Color", "value": "',
                            Avatar.getLipColor(avatar.lipColor),
                            '{"trait_type": "Skin Color", "value": "',
                            Avatar.getSkinColor(avatar.skinColor),
                            '{"trait_type": "Circle Color", "value": "',
                            Avatar.getCircleColor(avatar.circleColor),
                            '{"trait_type": "Face Mask", "value": "',
                            Avatar.isFaceMaskOn(avatar.faceMask),
                            '{"trait_type": "Face Mask Color", "value": "',
                            Avatar.getFaceMaskColor(avatar.faceMaskColor),
                            '{"trait_type": "Lashes", "value": "',
                            Avatar.hasLashes(avatar.lashes),
                            '{"trait_type": "Mask", "value": "',
                            Avatar.hasMask(avatar.mask),
                            "]",
                            "}"
                        )
                    )
                )
            )
        );
    }

    function mintNFT() public returns (uint256) {}

    function buildAvatar(
        uint8 accessory,
        uint8 bodyType,
        uint8 clothes,
        uint8 eyebrowShape,
        uint8 eyeShape,
        uint8 mouthStyle,
        uint8 facialHairType,
        uint8 clothesGraphic,
        uint8 hairStyle,
        uint8 hatStyle,
        bytes3 faceMaskColor,
        bytes3 clothingColor,
        bytes3 hairColor,
        bytes3 hatColor,
        bytes3 circleColor,
        bytes3 lipColor,
        bytes3 skinColor,
        bool faceMask,
        bool lashes,
        bool mask
    ) public {
        _attributes[tokenIdCounter] = Avatar.Attributes(
            accessory,
            bodyType,
            clothes,
            eyebrowShape,
            eyeShape,
            mouthStyle,
            facialHairType,
            clothesGraphic,
            hairStyle,
            hatStyle,
            faceMaskColor,
            clothingColor,
            hairColor,
            hatColor,
            circleColor,
            lipColor,
            skinColor,
            faceMask,
            lashes,
            mask
        );

        _safeMint(msg.sender, tokenIdCounter);
        tokenIdCounter++;
    }

    function getAttributes(uint256 tokenId) external view returns (string[20] memory) {}

    function getOwnerAttributes(address owner) external view returns (string[20][] memory) {}

    function getOwnerTokens(address owner) external view returns (uint256[] memory) {}

    function getOwnerTokensCount(address owner) external view returns (uint256) {}

    function getOwnerTokensCount() external view returns (uint256) {}

    function getOwner() external view returns (address) {}

    function getOwnerOf(uint256 tokenId) external view returns (address) {}

    function getAttributesCount() external view returns (uint256) {}

    function getAttributesByIndex(uint256 index) external view returns (string[20] memory) {}

    function getAttributesByTokenId(uint256 tokenId) external view returns (string[20] memory) {}

    function getAttributesByOwner(address owner) external view returns (string[20][] memory) {}

    function randomNum(uint256 mod, uint256 seed, uint256 salt) external view returns (uint256) {}

    function withdraw() external {}

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }
}
