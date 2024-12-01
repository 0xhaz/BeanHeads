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
    using Strings for uint256;
    using Avatar for *;

    error BeanHeads__TokenDoesNotExist();

    mapping(uint256 => Avatar.Bodies) private _bodies;
    mapping(uint256 => Avatar.Accessories) private _accessories;
    mapping(uint256 => Avatar.Clothes) private _clothes;
    mapping(uint256 => Avatar.Hats) private _hats;
    mapping(uint256 => Avatar.Eyes) private _eyes;
    mapping(uint256 => Avatar.Eyebrows) private _eyebrows;
    mapping(uint256 => Avatar.Mouths) private _mouths;
    mapping(uint256 => Avatar.Hairs) private _hairs;
    mapping(uint256 => Avatar.FacialHairs) private _facialHairs;
    mapping(uint256 => Avatar.FaceMask) private _faceMasks;
    mapping(uint256 => Avatar.Shapes) private _shapes;

    uint256 private tokenIdCounter;

    event MintedGenesis(address indexed owner, uint256 indexed tokenId);

    constructor() ERC721("BeanHeads", "BEAN") Ownable(msg.sender) {}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) revert BeanHeads__TokenDoesNotExist();

        Avatar.Bodies memory body = _bodies[tokenId];
        Avatar.Accessories memory accessory = _accessories[tokenId];
        Avatar.Clothes memory clothes = _clothes[tokenId];
        Avatar.Hats memory hat = _hats[tokenId];
        Avatar.Eyes memory eyes = _eyes[tokenId];
        Avatar.Eyebrows memory eyebrows = _eyebrows[tokenId];
        Avatar.Mouths memory mouth = _mouths[tokenId];
        Avatar.Hairs memory hair = _hairs[tokenId];
        Avatar.FacialHairs memory facialHair = _facialHairs[tokenId];
        Avatar.FaceMask memory faceMask = _faceMasks[tokenId];
        Avatar.Shapes memory shape = _shapes[tokenId];

        string memory attributes = _buildAttributesJSON(
            body, accessory, clothes, hat, eyes, eyebrows, mouth, hair, facialHair, faceMask, shape
        );

        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "BeanHead #',
                            Strings.toString(tokenId),
                            '", "description": "BeanHeads is a customizable avatar on-chain NFT collection", "attributes": [',
                            attributes,
                            "]}"
                        )
                    )
                )
            )
        );
    }

    function mintNFT() public returns (uint256) {}

    function buildAvatar(Avatar.AllAttributes calldata attributes) public returns (uint256) {
        uint256 tokenId = tokenIdCounter;
        tokenIdCounter++;

        _bodies[tokenId] = Avatar.Bodies(attributes.body.bodyType, attributes.body.skinColor);
        _accessories[tokenId] =
            Avatar.Accessories(attributes.accessory.accessory, attributes.accessory.lashes, attributes.accessory.mask);
        _clothes[tokenId] = Avatar.Clothes(
            attributes.clothes.clothes, attributes.clothes.clothesGraphic, attributes.clothes.clothingColor
        );
        _hats[tokenId] = Avatar.Hats(attributes.hat.hatStyle, attributes.hat.hatColor);
        _eyes[tokenId] = Avatar.Eyes(attributes.eyes.eyeShape);
        _eyebrows[tokenId] = Avatar.Eyebrows(attributes.eyebrows.eyebrowShape);
        _mouths[tokenId] = Avatar.Mouths(attributes.mouth.mouthStyle, attributes.mouth.lipColor);
        _hairs[tokenId] = Avatar.Hairs(attributes.hair.hairStyle, attributes.hair.hairColor);
        _facialHairs[tokenId] = Avatar.FacialHairs(attributes.facialHair.facialHairType);
        _faceMasks[tokenId] = Avatar.FaceMask(attributes.faceMask.isOn, attributes.faceMask.faceMaskColor);
        _shapes[tokenId] = Avatar.Shapes(attributes.shapes.circleColor);

        _safeMint(msg.sender, tokenId);

        emit MintedGenesis(msg.sender, tokenId);

        return tokenId;
    }

    function formatAttributes(Avatar.AllAttributes memory attributes) public pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"accessory": "',
                Strings.toString(attributes.accessory.accessory),
                '", "bodyType": "',
                Strings.toString(attributes.body.bodyType),
                '", "skinColor": "',
                Avatar.colorToHex(attributes.body.skinColor),
                '", "clothes": "',
                Strings.toString(attributes.clothes.clothes),
                '", "clothesColor": "',
                Avatar.colorToHex(attributes.clothes.clothingColor),
                '", "clothesGraphic": "',
                Strings.toString(attributes.clothes.clothesGraphic),
                '", "eyebrowShape": "',
                Strings.toString(attributes.eyebrows.eyebrowShape),
                '", "eyeShape": "',
                Strings.toString(attributes.eyes.eyeShape),
                '", "facialHairType": "',
                Strings.toString(attributes.facialHair.facialHairType),
                '", "hairStyle": "',
                Strings.toString(attributes.hair.hairStyle),
                '", "hairColor": "',
                Avatar.colorToHex(attributes.hair.hairColor),
                '", "hatStyle": "',
                Strings.toString(attributes.hat.hatStyle),
                '", "hatColor": "',
                Avatar.colorToHex(attributes.hat.hatColor),
                '", "mouthStyle": "',
                Strings.toString(attributes.mouth.mouthStyle),
                '", "lipColor": "',
                Avatar.colorToHex(attributes.mouth.lipColor),
                '", "circleColor": "',
                Avatar.colorToHex(attributes.shapes.circleColor),
                '", "faceMask": "',
                attributes.faceMask.isOn ? "true" : "false",
                '", "faceMaskColor": "',
                Avatar.colorToHex(attributes.faceMask.faceMaskColor),
                '", "lashes": "',
                attributes.accessory.lashes ? "true" : "false",
                '", "mask": "',
                attributes.accessory.mask ? "true" : "false",
                '"}'
            )
        );
    }

    function getAttributes(uint256 tokenId) external view returns (Avatar.AllAttributes memory) {
        if (tokenId >= tokenIdCounter) revert BeanHeads__TokenDoesNotExist();

        return _constructAttributes(tokenId);
    }

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

    function getBodies(uint256 tokenId) external view returns (Avatar.Bodies memory) {
        return _bodies[tokenId];
    }

    function getAccessories(uint256 tokenId) external view returns (Avatar.Accessories memory) {
        return _accessories[tokenId];
    }

    function getClothes(uint256 tokenId) external view returns (Avatar.Clothes memory) {
        return _clothes[tokenId];
    }

    function getHats(uint256 tokenId) external view returns (Avatar.Hats memory) {
        return _hats[tokenId];
    }

    function getEyes(uint256 tokenId) external view returns (Avatar.Eyes memory) {
        return _eyes[tokenId];
    }

    function getEyebrows(uint256 tokenId) external view returns (Avatar.Eyebrows memory) {
        return _eyebrows[tokenId];
    }

    function getMouths(uint256 tokenId) external view returns (Avatar.Mouths memory) {
        return _mouths[tokenId];
    }

    function getHairs(uint256 tokenId) external view returns (Avatar.Hairs memory) {
        return _hairs[tokenId];
    }

    function getFacialHairs(uint256 tokenId) external view returns (Avatar.FacialHairs memory) {
        return _facialHairs[tokenId];
    }

    function getFaceMask(uint256 tokenId) external view returns (Avatar.FaceMask memory) {
        return _faceMasks[tokenId];
    }

    function getShapes(uint256 tokenId) external view returns (Avatar.Shapes memory) {
        return _shapes[tokenId];
    }

    function randomNum(uint256 mod, uint256 seed, uint256 salt) external view returns (uint256) {}

    function withdraw() external {}

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function _buildAttributesJSON(
        Avatar.Bodies memory body,
        Avatar.Accessories memory accessory,
        Avatar.Clothes memory clothes,
        Avatar.Hats memory hat,
        Avatar.Eyes memory eyes,
        Avatar.Eyebrows memory eyebrows,
        Avatar.Mouths memory mouth,
        Avatar.Hairs memory hair,
        Avatar.FacialHairs memory facialHair,
        Avatar.FaceMask memory faceMask,
        Avatar.Shapes memory shape
    ) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type": "Accessory", "value": "',
                Avatar.getAccessory(bytes4(abi.encodePacked(accessory.accessory))),
                '"},',
                '{"trait_type": "Body Type", "value": "',
                Avatar.getBody(bytes4(abi.encodePacked(body.bodyType))),
                '"},',
                '{"trait_type": "Skin Color", "value": "',
                Avatar.getSkinColor(body.skinColor),
                '"},',
                '{"trait_type": "Clothes", "value": "',
                Avatar.getClothing(bytes4(abi.encodePacked(clothes.clothes))),
                '"},',
                '{"trait_type": "Clothes Color", "value": "',
                Avatar.getClothingColor(clothes.clothingColor),
                '"},',
                '{"trait_type": "Clothes Graphic", "value": "',
                Avatar.getClothingGraphic(bytes4(abi.encodePacked(clothes.clothesGraphic))),
                '"},',
                '{"trait_type": "Eyebrow Shape", "value": "',
                Avatar.getEyebrows(bytes4(abi.encodePacked(eyebrows.eyebrowShape))),
                '"},',
                '{"trait_type": "Eye Shape", "value": "',
                Avatar.getEyes(bytes4(abi.encodePacked(eyes.eyeShape))),
                '"},',
                '{"trait_type": "Facial Hair Type", "value": "',
                Avatar.getFacialHair(bytes4(abi.encodePacked(facialHair.facialHairType))),
                '"},',
                '{"trait_type": "Hair Style", "value": "',
                Avatar.getHair(bytes4(abi.encodePacked(hair.hairStyle))),
                '"},',
                '{"trait_type": "Hair Color", "value": "',
                Avatar.getHairColor(hair.hairColor),
                '"},',
                '{"trait_type": "Hat Style", "value": "',
                Avatar.getHats(bytes4(abi.encodePacked(hat.hatStyle))),
                '"},',
                '{"trait_type": "Hat Color", "value": "',
                Avatar.getHatColor(hat.hatColor),
                '"},',
                '{"trait_type": "Mouth Type", "value": "',
                Avatar.getMouths(bytes4(abi.encodePacked(mouth.mouthStyle))),
                '"},',
                '{"trait_type": "Lip Color", "value": "',
                Avatar.getLipColor(mouth.lipColor),
                '"},',
                '{"trait_type": "Circle Color", "value": "',
                Avatar.getCircleColor(shape.circleColor),
                '"},',
                '{"trait_type": "Face Mask", "value": "',
                Avatar.isFaceMaskOn(faceMask.isOn),
                '"},',
                '{"trait_type": "Face Mask Color", "value": "',
                Avatar.getFaceMaskColor(faceMask.faceMaskColor),
                '"},',
                '{"trait_type": "Lashes", "value": "',
                Avatar.hasLashes(accessory.lashes),
                '"},',
                '{"trait_type": "Mask", "value": "',
                Avatar.hasMask(accessory.mask),
                '"}'
            )
        );
    }

    function _constructAttributes(uint256 tokenId) internal view returns (Avatar.AllAttributes memory attributes) {
        attributes = Avatar.AllAttributes({
            body: _bodies[tokenId],
            accessory: _accessories[tokenId],
            clothes: _clothes[tokenId],
            hat: _hats[tokenId],
            eyes: _eyes[tokenId],
            eyebrows: _eyebrows[tokenId],
            mouth: _mouths[tokenId],
            hair: _hairs[tokenId],
            facialHair: _facialHairs[tokenId],
            faceMask: _faceMasks[tokenId],
            shapes: _shapes[tokenId]
        });
    }
}
