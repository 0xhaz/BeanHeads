// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ImagesLib, ImagesInBytes} from "src/types/Constants.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
/**
 * @title Avatar Library
 * @notice Library for Beanhead's Avatar attributes
 */

library Avatar {
    struct AllAttributes {
        string accessory;
        string bodyType;
        string skinColor;
        string clothes;
        string clothesColor;
        string clothesGraphic;
        string eyebrowShape;
        string eyeShape;
        string facialHairType;
        string hairStyle;
        string hairColor;
        string hatStyle;
        string hatColor;
        string mouthStyle;
        string lipColor;
        string circleColor;
        string faceMask;
        string faceMaskColor;
        string lashes;
        string mask;
    }

    struct Layer {
        string base; // The primary SVG path for this layer
        string overlay; // The overlay SVG path for this layer
    }

    struct Bodies {
        uint8 bodyType;
        bytes3 skinColor;
    }

    struct Accessories {
        uint8 accessory;
        bool lashes;
        bool mask;
    }

    struct Clothes {
        uint8 clothes;
        uint8 clothesGraphic;
        bytes3 clothingColor;
    }

    struct Hats {
        uint8 hatStyle;
        bytes3 hatColor;
    }

    struct Eyes {
        uint8 eyeShape;
    }

    struct Eyebrows {
        uint8 eyebrowShape;
    }

    struct Mouths {
        uint8 mouthStyle;
        bytes3 lipColor;
    }

    struct Hairs {
        uint8 hairStyle;
        bytes3 hairColor;
    }

    struct FacialHairs {
        uint8 facialHairType;
    }

    struct FaceMask {
        bool isOn;
        bytes3 faceMaskColor;
    }

    struct Shapes {
        bytes3 circleColor;
    }

    function getAccessory(bytes4 selector) public pure returns (string memory) {
        bytes4[3] memory accessories = [ImagesInBytes.ROUND_GLASSES, ImagesInBytes.SHADES, ImagesInBytes.TINY_GLASSES];

        return selector == accessories[0]
            ? ImagesLib.RoundGlasses
            : selector == accessories[1] ? ImagesLib.Shades : selector == accessories[2] ? ImagesLib.TinyGlasses : "";
    }

    function getBody(bytes4 selector) public pure returns (string memory) {
        bytes4[2] memory bodies = [ImagesInBytes.BREAST, ImagesInBytes.CHEST];

        return selector == bodies[0] ? ImagesLib.Breast : selector == bodies[1] ? ImagesLib.Chest : "";
    }

    function getClothing(bytes4 selector) public pure returns (string memory) {
        bytes4[6] memory clothingTypes = [
            ImagesInBytes.DRESS_FRONT,
            ImagesInBytes.DRESS_BACK,
            ImagesInBytes.DRESS_SHIRT,
            ImagesInBytes.SHIRT,
            ImagesInBytes.TANK_TOP,
            ImagesInBytes.V_NECK
        ];

        return selector == clothingTypes[0]
            ? ImagesLib.DressFront
            : selector == clothingTypes[1]
                ? ImagesLib.DressBack
                : selector == clothingTypes[2]
                    ? ImagesLib.DressShirt
                    : selector == clothingTypes[3]
                        ? ImagesLib.Shirt
                        : selector == clothingTypes[4] ? ImagesLib.TankTop : selector == clothingTypes[5] ? ImagesLib.VNeck : "";
    }

    function getClothingColor(bytes3 color) public pure returns (string memory) {
        return string(abi.encodePacked("#", color));
    }

    function getClothingGraphic(bytes4 selector) public pure returns (string memory) {
        bytes4[5] memory clothingGraphics =
            [ImagesInBytes.GATSBY, ImagesInBytes.GRAPHQL, ImagesInBytes.REACT, ImagesInBytes.REDWOOD, ImagesInBytes.VUE];

        return selector == clothingGraphics[0]
            ? ImagesLib.Gatsby
            : selector == clothingGraphics[1]
                ? ImagesLib.GraphQL
                : selector == clothingGraphics[2]
                    ? ImagesLib.React
                    : selector == clothingGraphics[3] ? ImagesLib.Redwood : selector == clothingGraphics[4] ? ImagesLib.Vue : "";
    }

    function getEyebrows(bytes4 selector) public pure returns (string memory) {
        bytes4[4] memory eyebrowShapes = [
            ImagesInBytes.ANGRY_EYEBROWS,
            ImagesInBytes.LEFT_LOWERED_EYEBROW,
            ImagesInBytes.NORMAL,
            ImagesInBytes.SERIOUS_EYEBROWS
        ];

        return selector == eyebrowShapes[0]
            ? ImagesLib.AngryEyebrows
            : selector == eyebrowShapes[1]
                ? ImagesLib.LeftLoweredEyebrow
                : selector == eyebrowShapes[2]
                    ? ImagesLib.Normal
                    : selector == eyebrowShapes[3] ? ImagesLib.SeriousEyebrows : "";
    }

    function getEyes(bytes4 selector) public pure returns (string memory) {
        bytes4[10] memory eyeShapes = [
            ImagesInBytes.CONTENT_EYES,
            ImagesInBytes.DIZZY_EYES,
            ImagesInBytes.HAPPY_EYES,
            ImagesInBytes.HEART_EYES,
            ImagesInBytes.LASHES,
            ImagesInBytes.LEFT_TWITCH_EYE,
            ImagesInBytes.NORMAL_EYES,
            ImagesInBytes.SIMPLE_EYES,
            ImagesInBytes.SQUINT_EYES,
            ImagesInBytes.WINK
        ];

        return selector == eyeShapes[0]
            ? ImagesLib.ContentEyes
            : selector == eyeShapes[1]
                ? ImagesLib.DizzyEyes
                : selector == eyeShapes[2]
                    ? ImagesLib.HappyEyes
                    : selector == eyeShapes[3]
                        ? ImagesLib.HeartEyes
                        : selector == eyeShapes[4]
                            ? ImagesLib.Lashes
                            : selector == eyeShapes[5]
                                ? ImagesLib.LeftTwitchEyes
                                : selector == eyeShapes[6]
                                    ? ImagesLib.NormalEyes
                                    : selector == eyeShapes[7]
                                        ? ImagesLib.SimpleEyes
                                        : selector == eyeShapes[8] ? ImagesLib.SquintEyes : selector == eyeShapes[9] ? ImagesLib.Wink : "";
    }

    function getFacialHair(bytes4 selector) public pure returns (string memory) {
        bytes4[2] memory facialHairTypes = [ImagesInBytes.MEDIUM_BEARD, ImagesInBytes.STUBBLE];

        return selector == facialHairTypes[0]
            ? ImagesLib.MediumBeard
            : selector == facialHairTypes[1] ? ImagesLib.Stubble : "";
    }

    function getHair(bytes4 selector) public pure returns (string memory) {
        bytes4[10] memory hairStyles = [
            ImagesInBytes.AFRO_FRONT,
            ImagesInBytes.AFRO_BACK,
            ImagesInBytes.BALDING_HAIR,
            ImagesInBytes.BOBCUT,
            ImagesInBytes.BUN,
            ImagesInBytes.BUZZCUT,
            ImagesInBytes.LONG_HAIR,
            ImagesInBytes.LONG_HAIR_BACK,
            ImagesInBytes.PIXIE_CUT,
            ImagesInBytes.SHORT_HAIR
        ];

        return selector == hairStyles[0]
            ? ImagesLib.AfroFront
            : selector == hairStyles[1]
                ? ImagesLib.AfroBack
                : selector == hairStyles[2]
                    ? ImagesLib.BaldingHair
                    : selector == hairStyles[3]
                        ? ImagesLib.BobCut
                        : selector == hairStyles[4]
                            ? ImagesLib.BunHair
                            : selector == hairStyles[5]
                                ? ImagesLib.BuzzCut
                                : selector == hairStyles[6]
                                    ? ImagesLib.LongHair
                                    : selector == hairStyles[7]
                                        ? ImagesLib.LongHairBack
                                        : selector == hairStyles[8] ? ImagesLib.PixieCut : selector == hairStyles[9] ? ImagesLib.ShortHair : "";
    }

    function getHairPath(uint8 hairStyle) internal pure returns (string memory) {
        return hairStyle == 0
            ? ImagesLib.AfroFront
            : hairStyle == 1
                ? ImagesLib.AfroBack
                : hairStyle == 2
                    ? ImagesLib.BaldingHair
                    : hairStyle == 3
                        ? ImagesLib.BobCut
                        : hairStyle == 4
                            ? ImagesLib.BunHair
                            : hairStyle == 5
                                ? ImagesLib.BuzzCut
                                : hairStyle == 6
                                    ? ImagesLib.LongHair
                                    : hairStyle == 7 ? ImagesLib.LongHairBack : hairStyle == 8 ? ImagesLib.PixieCut : ImagesLib.ShortHair;
    }

    function getHairColor(bytes3 color) public pure returns (string memory) {
        return string(abi.encodePacked("#", color));
    }

    function getHats(bytes4 selector) public pure returns (string memory) {
        bytes4[2] memory hatStyles = [ImagesInBytes.BEANIE, ImagesInBytes.TURBAN];

        return selector == hatStyles[0] ? ImagesLib.Beanie : selector == hatStyles[1] ? ImagesLib.Turban : "";
    }

    function getHatColor(bytes3 color) public pure returns (string memory) {
        return string(abi.encodePacked("#", color));
    }

    function getMouths(bytes4 selector) public pure returns (string memory) {
        bytes4[7] memory mouthShapes = [
            ImagesInBytes.GRIN,
            ImagesInBytes.LIPS,
            ImagesInBytes.OPEN_MOUTH,
            ImagesInBytes.OPEN_SMILE,
            ImagesInBytes.SAD,
            ImagesInBytes.SERIOUS_MOUTH,
            ImagesInBytes.TONGUE
        ];

        return selector == mouthShapes[0]
            ? ImagesLib.Grin
            : selector == mouthShapes[1]
                ? ImagesLib.Lips
                : selector == mouthShapes[2]
                    ? ImagesLib.OpenMouth
                    : selector == mouthShapes[3]
                        ? ImagesLib.OpenSmile
                        : selector == mouthShapes[4]
                            ? ImagesLib.Sad
                            : selector == mouthShapes[5] ? ImagesLib.SeriousMouth : selector == mouthShapes[6] ? ImagesLib.Tongue : "";
    }

    function getLipColor(bytes3 color) public pure returns (string memory) {
        return string(abi.encodePacked("#", color));
    }

    function getSkinColor(bytes3 color) public pure returns (string memory) {
        return string(abi.encodePacked("#", color));
    }

    function getCircleColor(bytes3 color) public pure returns (string memory) {
        return string(abi.encodePacked("#", color));
    }

    function getFaceMaskColor(bytes3 color) public pure returns (string memory) {
        return string(abi.encodePacked("#", color));
    }

    function isFaceMaskOn(bool value) public pure returns (string memory) {
        return value ? "true" : "false";
    }

    function hasLashes(bool value) public pure returns (string memory) {
        return value ? "true" : "false";
    }

    function hasMask(bool value) public pure returns (string memory) {
        return value ? "true" : "false";
    }

    function renderHair(Hairs memory hair) public pure returns (string memory) {
        if (hair.hairStyle == 6) {
            return string(
                abi.encodePacked(
                    "<g>",
                    '<path d="',
                    getLongHairBack(),
                    '" fill="',
                    colorToHex(hair.hairColor),
                    '"/>',
                    '<path d="',
                    getLongHairFront(),
                    '" fill="',
                    colorToHex(hair.hairColor),
                    '"/>',
                    "</g>"
                )
            );
        } else if (hair.hairStyle == 0) {
            return string(
                abi.encodePacked(
                    "<g>",
                    '<path d="',
                    getAfroBack(),
                    '" fill="',
                    colorToHex(hair.hairColor),
                    '"/>',
                    '<path d="',
                    getAfroFront(),
                    '" fill="',
                    colorToHex(hair.hairColor),
                    '"/>',
                    "</g>"
                )
            );
        } else {
            return string(
                abi.encodePacked(
                    '<path d="', getHairPath(hair.hairStyle), '" fill="', colorToHex(hair.hairColor), '"/>'
                )
            );
        }
    }

    function colorToHex(bytes3 color) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "#", toHexString(uint8(color[0]), 2), toHexString(uint8(color[1]), 2), toHexString(uint8(color[2]), 2)
            )
        );
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(length * 2);
        for (uint256 i; i < length; ++i) {
            buffer[length * 2 - 1 - i * 2] = _hexChar(uint8(value & 0xf));
            buffer[length * 2 - 2 - i * 2] = _hexChar(uint8((value >> 4) & 0xf));
            value >>= 8;
        }
        return string(buffer);
    }

    function _hexChar(uint8 value) private pure returns (bytes1) {
        return value < 10 ? bytes1(value + 48) : bytes1(value + 87);
    }

    function getLongHairBack() internal pure returns (string memory) {
        return getHair(bytes4(ImagesInBytes.LONG_HAIR_BACK));
    }

    function getLongHairFront() internal pure returns (string memory) {
        return getHair(bytes4(ImagesInBytes.LONG_HAIR));
    }

    function getAfroFront() internal pure returns (string memory) {
        return getHair(bytes4(ImagesInBytes.AFRO_FRONT));
    }

    function getAfroBack() internal pure returns (string memory) {
        return getHair(bytes4(ImagesInBytes.AFRO_BACK));
    }

    function getAllAttributes(uint256 tokenId) public view returns (AllAttributes memory result) {}

    function _getAccessory(uint256 tokenId) private view returns (string memory) {
        return _getAttribute(tokenId, 0x01, 0x00);
    }

    function _getBodyType(uint256 tokenId) private view returns (string memory) {
        return _getAttribute(tokenId, 0x00, 0x00);
    }

    function _getMask(uint256 tokenId) private view returns (string memory) {
        return _getAttribute(tokenId, 0x01, 0x02);
    }

    function _getAttribute(uint256 tokenId, uint256 slot, uint256 offset) private view returns (string memory) {
        bytes32 attribute;
        assembly {
            let slotHash := keccak256(add(slot, tokenId), 0x20)
            attribute := sload(add(slotHash, offset))
        }

        return string(abi.encodePacked(attribute));
    }
}
