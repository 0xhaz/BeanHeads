// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
// import {Avatar} from "src/types/Avatar.sol";

/**
 * @title BeanHeads
 * @notice BeanHeads is a customizable avatar on chain NFT collection
 * @dev Uses breeding concept to create new avatars similar to Cryptokitties
 * @dev Uses Chainlink VRF for attributes randomness
 */
contract BeanHeads is ERC721Enumerable, Ownable, IBeanHeads {
    using Base64 for bytes;
    using Strings for uint256;
    // using Avatar for *;

    error BeanHeads__TokenDoesNotExist();

    // mapping(uint256 => Avatar.Core) private _core;
    // mapping(uint256 => Avatar.Appearance) private _appearance;
    // mapping(uint256 => Avatar.Clothing) private _clothes;
    // mapping(uint256 => Avatar.Extras) private _extras;

    uint256 private tokenIdCounter;

    event MintedGenesis(address indexed owner, uint256 indexed tokenId);

    constructor() ERC721("BeanHeads", "BEAN") Ownable(msg.sender) {}

    // function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     if (_ownerOf(tokenId) == address(0)) revert BeanHeads__TokenDoesNotExist();

    //     Avatar.Core memory body = Avatar.Core({
    //         accessory: _core[tokenId].accessory,
    //         bodyType: _core[tokenId].bodyType,
    //         skinColor: _core[tokenId].skinColor
    //     });
    //     Avatar.Appearance memory appearance = Avatar.Appearance({
    //         eyebrowShape: _appearance[tokenId].eyebrowShape,
    //         eyeShape: _appearance[tokenId].eyeShape,
    //         mouthStyle: _appearance[tokenId].mouthStyle,
    //         facialHairType: _appearance[tokenId].facialHairType,
    //         hairStyle: _appearance[tokenId].hairStyle,
    //         hairColor: _appearance[tokenId].hairColor
    //     });
    //     Avatar.Clothing memory clothes = Avatar.Clothing({
    //         clothes: _clothes[tokenId].clothes,
    //         clothesGraphic: _clothes[tokenId].clothesGraphic,
    //         clothingColor: _clothes[tokenId].clothingColor,
    //         hatStyle: _clothes[tokenId].hatStyle,
    //         hatColor: _clothes[tokenId].hatColor
    //     });
    //     Avatar.Extras memory extras = Avatar.Extras({
    //         circleColor: _extras[tokenId].circleColor,
    //         lipColor: _extras[tokenId].lipColor,
    //         faceMaskColor: _extras[tokenId].faceMaskColor,
    //         faceMask: _extras[tokenId].faceMask,
    //         lashes: _extras[tokenId].lashes,
    //         mask: _extras[tokenId].mask
    //     });

    //     string memory attributes = _buildAttributesJSON(body, appearance, clothes, extras);

    //     return string(
    //         abi.encodePacked(
    //             _baseURI(),
    //             Base64.encode(
    //                 bytes(
    //                     abi.encodePacked(
    //                         '{"name": "BeanHead #',
    //                         Strings.toString(tokenId),
    //                         '", "description": "BeanHeads is a customizable avatar on-chain NFT collection", "attributes": [',
    //                         attributes,
    //                         "]}"
    //                     )
    //                 )
    //             )
    //         )
    //     );
    // }

    function mintNFT() public returns (uint256) {}

    // function buildAvatar(
    //     Avatar.Core calldata coreParams,
    //     Avatar.Appearance calldata appearanceParams,
    //     Avatar.Clothing calldata clothParams,
    //     Avatar.Extras calldata extraParams
    // ) public returns (uint256) {
    //     uint256 tokenId = tokenIdCounter;
    //     tokenIdCounter++;

    //     Avatar.Core memory body = Avatar.Core({
    //         accessory: _core[tokenId].accessory,
    //         bodyType: _core[tokenId].bodyType,
    //         skinColor: _core[tokenId].skinColor
    //     });
    //     Avatar.Appearance memory appearance = Avatar.Appearance({
    //         eyebrowShape: _appearance[tokenId].eyebrowShape,
    //         eyeShape: _appearance[tokenId].eyeShape,
    //         mouthStyle: _appearance[tokenId].mouthStyle,
    //         facialHairType: _appearance[tokenId].facialHairType,
    //         hairStyle: _appearance[tokenId].hairStyle,
    //         hairColor: _appearance[tokenId].hairColor
    //     });
    //     Avatar.Clothing memory clothes = Avatar.Clothing({
    //         clothes: _clothes[tokenId].clothes,
    //         clothesGraphic: _clothes[tokenId].clothesGraphic,
    //         clothingColor: _clothes[tokenId].clothingColor,
    //         hatStyle: _clothes[tokenId].hatStyle,
    //         hatColor: _clothes[tokenId].hatColor
    //     });
    //     Avatar.Extras memory extras = Avatar.Extras({
    //         circleColor: _extras[tokenId].circleColor,
    //         lipColor: _extras[tokenId].lipColor,
    //         faceMaskColor: _extras[tokenId].faceMaskColor,
    //         faceMask: _extras[tokenId].faceMask,
    //         lashes: _extras[tokenId].lashes,
    //         mask: _extras[tokenId].mask
    //     });

    //     _core[tokenId] = body;
    //     _appearance[tokenId] = appearance;
    //     _clothes[tokenId] = clothes;
    //     _extras[tokenId] = extras;

    //     _safeMint(msg.sender, tokenId);

    //     emit MintedGenesis(msg.sender, tokenId);

    //     return tokenId;
    // }

    // function formatAttributes(
    //     Avatar.Core calldata coreParams,
    //     Avatar.Appearance calldata appearanceParams,
    //     Avatar.Clothing calldata clothParams,
    //     Avatar.Extras calldata extraParams
    // ) public pure returns (string memory) {
    //     return string(
    //         abi.encodePacked(
    //             '{"accessory": "',
    //             Strings.toString(coreParams.accessory),
    //             '", "bodyType": "',
    //             Strings.toString(coreParams.bodyType),
    //             '", "skinColor": "',
    //             Avatar.colorToHex(coreParams.skinColor),
    //             '", "clothes": "',
    //             Strings.toString(clothParams.clothes),
    //             '", "clothesColor": "',
    //             Avatar.colorToHex(clothParams.clothingColor),
    //             '", "clothesGraphic": "',
    //             Strings.toString(clothParams.clothesGraphic),
    //             '", "eyebrowShape": "',
    //             Strings.toString(appearanceParams.eyebrowShape),
    //             '", "eyeShape": "',
    //             Strings.toString(appearanceParams.eyeShape),
    //             '", "facialHairType": "',
    //             Strings.toString(appearanceParams.facialHairType),
    //             '", "hairStyle": "',
    //             Strings.toString(appearanceParams.hairStyle),
    //             '", "hairColor": "',
    //             Avatar.colorToHex(appearanceParams.hairColor),
    //             '", "hatStyle": "',
    //             Strings.toString(clothParams.hatStyle),
    //             '", "hatColor": "',
    //             Avatar.colorToHex(clothParams.hatColor),
    //             '", "mouthStyle": "',
    //             Strings.toString(appearanceParams.mouthStyle),
    //             '", "lipColor": "',
    //             Avatar.colorToHex(extraParams.lipColor),
    //             '", "circleColor": "',
    //             Avatar.colorToHex(extraParams.circleColor),
    //             '", "faceMask": "',
    //             extraParams.faceMask ? "true" : "false",
    //             '", "faceMaskColor": "',
    //             Avatar.colorToHex(extraParams.faceMaskColor),
    //             '", "lashes": "',
    //             extraParams.lashes ? "true" : "false",
    //             '", "mask": "',
    //             extraParams.mask ? "true" : "false",
    //             '"}'
    //         )
    //     );
    // }

    // function getAttributes(uint256 tokenId) external view returns (string memory) {
    //     if (tokenId >= tokenIdCounter) revert BeanHeads__TokenDoesNotExist();

    //     Avatar.Core memory body = Avatar.Core({
    //         accessory: _core[tokenId].accessory,
    //         bodyType: _core[tokenId].bodyType,
    //         skinColor: _core[tokenId].skinColor
    //     });
    //     Avatar.Appearance memory appearance = Avatar.Appearance({
    //         eyebrowShape: _appearance[tokenId].eyebrowShape,
    //         eyeShape: _appearance[tokenId].eyeShape,
    //         mouthStyle: _appearance[tokenId].mouthStyle,
    //         facialHairType: _appearance[tokenId].facialHairType,
    //         hairStyle: _appearance[tokenId].hairStyle,
    //         hairColor: _appearance[tokenId].hairColor
    //     });
    //     Avatar.Clothing memory clothes = Avatar.Clothing({
    //         clothes: _clothes[tokenId].clothes,
    //         clothesGraphic: _clothes[tokenId].clothesGraphic,
    //         clothingColor: _clothes[tokenId].clothingColor,
    //         hatStyle: _clothes[tokenId].hatStyle,
    //         hatColor: _clothes[tokenId].hatColor
    //     });
    //     Avatar.Extras memory extras = Avatar.Extras({
    //         circleColor: _extras[tokenId].circleColor,
    //         lipColor: _extras[tokenId].lipColor,
    //         faceMaskColor: _extras[tokenId].faceMaskColor,
    //         faceMask: _extras[tokenId].faceMask,
    //         lashes: _extras[tokenId].lashes,
    //         mask: _extras[tokenId].mask
    //     });

    //     return _buildAttributesJSON(body, appearance, clothes, extras);
    // }

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

    // function getBodies(uint256 tokenId) external view returns (Avatar.Core memory) {
    //     return _core[tokenId];
    // }

    // function getAccessories(uint256 tokenId) external view returns (uint8) {
    //     return _core[tokenId].accessory;
    // }

    // function getClothes(uint256 tokenId) external view returns (Avatar.Clothing memory) {
    //     return _clothes[tokenId];
    // }

    // function getHats(uint256 tokenId) external view returns (Avatar.Clothing memory) {
    //     return _clothes[tokenId];
    // }

    // function getEyes(uint256 tokenId) external view returns (Avatar.Appearance memory) {
    //     return _appearance[tokenId];
    // }

    // function getEyebrows(uint256 tokenId) external view returns (Avatar.Appearance memory) {
    //     return _appearance[tokenId];
    // }

    // function getMouths(uint256 tokenId) external view returns (Avatar.Appearance memory) {
    //     return _appearance[tokenId];
    // }

    // function getHairs(uint256 tokenId) external view returns (Avatar.Appearance memory) {
    //     return _appearance[tokenId];
    // }

    // function getFacialHairs(uint256 tokenId) external view returns (Avatar.Appearance memory) {
    //     return _appearance[tokenId];
    // }

    // function getFaceMask(uint256 tokenId) external view returns (Avatar.Extras memory) {
    //     return _extras[tokenId];
    // }

    // function getShapes(uint256 tokenId) external view returns (Avatar.Extras memory) {
    //     return _extras[tokenId];
    // }

    // function randomNum(uint256 mod, uint256 seed, uint256 salt) external view returns (uint256) {}

    // function withdraw() external {}

    // function _baseURI() internal pure override returns (string memory) {
    //     return "data:application/json;base64,";
    // }

    // function _buildAttributesJSON(
    //     Avatar.Core memory coreParams,
    //     Avatar.Appearance memory appearanceParams,
    //     Avatar.Clothing memory clothParams,
    //     Avatar.Extras memory extraParams
    // ) private pure returns (string memory) {
    //     return string(
    //         abi.encodePacked(
    //             '{"trait_type": "Accessory", "value": "',
    //             Avatar.getAccessory(bytes4(abi.encodePacked(coreParams.accessory))),
    //             '"},',
    //             '{"trait_type": "Body Type", "value": "',
    //             Avatar.getBody(bytes4(abi.encodePacked(coreParams.bodyType))),
    //             '"},',
    //             '{"trait_type": "Skin Color", "value": "',
    //             Avatar.getSkinColor(coreParams.skinColor),
    //             '"},',
    //             '{"trait_type": "Clothes", "value": "',
    //             Avatar.getClothing(bytes4(abi.encodePacked(clothParams.clothes))),
    //             '"},',
    //             '{"trait_type": "Clothes Color", "value": "',
    //             Avatar.getClothingColor(clothParams.clothingColor),
    //             '"},',
    //             '{"trait_type": "Clothes Graphic", "value": "',
    //             Avatar.getClothingGraphic(bytes4(abi.encodePacked(clothParams.clothesGraphic))),
    //             '"},',
    //             '{"trait_type": "Eyebrow Shape", "value": "',
    //             Avatar.getEyebrows(bytes4(abi.encodePacked(appearanceParams.eyebrowShape))),
    //             '"},',
    //             '{"trait_type": "Eye Shape", "value": "',
    //             Avatar.getEyes(bytes4(abi.encodePacked(appearanceParams.eyeShape))),
    //             '"},',
    //             '{"trait_type": "Facial Hair Type", "value": "',
    //             Avatar.getFacialHair(bytes4(abi.encodePacked(appearanceParams.facialHairType))),
    //             '"},',
    //             '{"trait_type": "Hair Style", "value": "',
    //             Avatar.getHair(bytes4(abi.encodePacked(appearanceParams.hairStyle))),
    //             '"},',
    //             '{"trait_type": "Hair Color", "value": "',
    //             Avatar.getHairColor(appearanceParams.hairColor),
    //             '"},',
    //             '{"trait_type": "Hat Style", "value": "',
    //             Avatar.getHats(bytes4(abi.encodePacked(clothParams.hatStyle))),
    //             '"},',
    //             '{"trait_type": "Hat Color", "value": "',
    //             Avatar.getHatColor(clothParams.hatColor),
    //             '"},',
    //             '{"trait_type": "Mouth Type", "value": "',
    //             Avatar.getMouths(bytes4(abi.encodePacked(appearanceParams.mouthStyle))),
    //             '"},',
    //             '{"trait_type": "Lip Color", "value": "',
    //             Avatar.getLipColor(extraParams.lipColor),
    //             '"},',
    //             '{"trait_type": "Circle Color", "value": "',
    //             Avatar.getCircleColor(extraParams.circleColor),
    //             '"},',
    //             '{"trait_type": "Face Mask", "value": "',
    //             Avatar.isFaceMaskOn(extraParams.faceMask),
    //             '"},',
    //             '{"trait_type": "Face Mask Color", "value": "',
    //             Avatar.getFaceMaskColor(extraParams.faceMaskColor),
    //             '"},',
    //             '{"trait_type": "Lashes", "value": "',
    //             Avatar.hasLashes(extraParams.lashes),
    //             '"},',
    //             '{"trait_type": "Mask", "value": "',
    //             Avatar.hasMask(extraParams.mask),
    //             '"}'
    //         )
    //     );
    // }

    // function _constructAttributes(uint256 tokenId)
    //     internal
    //     view
    //     returns (
    //         Avatar.Core memory coreParams,
    //         Avatar.Appearance memory appearanceParams,
    //         Avatar.Clothing memory clothParams,
    //         Avatar.Extras memory extraParams
    //     )
    // {
    //     Avatar.Core memory body = Avatar.Core({
    //         accessory: _core[tokenId].accessory,
    //         bodyType: _core[tokenId].bodyType,
    //         skinColor: _core[tokenId].skinColor
    //     });
    //     Avatar.Appearance memory appearance = Avatar.Appearance({
    //         eyebrowShape: _appearance[tokenId].eyebrowShape,
    //         eyeShape: _appearance[tokenId].eyeShape,
    //         mouthStyle: _appearance[tokenId].mouthStyle,
    //         facialHairType: _appearance[tokenId].facialHairType,
    //         hairStyle: _appearance[tokenId].hairStyle,
    //         hairColor: _appearance[tokenId].hairColor
    //     });
    //     Avatar.Clothing memory clothes = Avatar.Clothing({
    //         clothes: _clothes[tokenId].clothes,
    //         clothesGraphic: _clothes[tokenId].clothesGraphic,
    //         clothingColor: _clothes[tokenId].clothingColor,
    //         hatStyle: _clothes[tokenId].hatStyle,
    //         hatColor: _clothes[tokenId].hatColor
    //     });
    //     Avatar.Extras memory extras = Avatar.Extras({
    //         circleColor: _extras[tokenId].circleColor,
    //         lipColor: _extras[tokenId].lipColor,
    //         faceMaskColor: _extras[tokenId].faceMaskColor,
    //         faceMask: _extras[tokenId].faceMask,
    //         lashes: _extras[tokenId].lashes,
    //         mask: _extras[tokenId].mask
    //     });

    //     return (body, appearance, clothes, extras);
    // }
    function getAttributes(uint256 tokenId) external view override returns (string memory) {}

    function randomNum(uint256 mod, uint256 seed, uint256 salt) external view override returns (uint256) {}

    function withdraw() external override {}
}
