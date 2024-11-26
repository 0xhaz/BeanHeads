// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ImagesLib, ImagesInBytes} from "src/types/Constants.sol";
/**
 * @title Avatar Library
 * @notice Library for Beanhead's Avatar attributes
 */

library Avatar {
    struct Attributes {
        uint8 accessory;
        uint8 bodyType;
        uint8 clothes;
        uint8 eyebrowShape;
        uint8 eyeShape;
        uint8 mouthStyle;
        uint8 facialHairType;
        uint8 clothesGraphic;
        uint8 hairStyle;
        uint8 hatStyle;
        bytes3 faceMaskColor;
        bytes3 clothingColor;
        bytes3 hairColor;
        bytes3 hatColor;
        bytes3 circleColor;
        bytes3 lipColor;
        bytes3 skinColor;
        bool faceMask;
        bool lashes;
        bool mask;
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
        bytes4[5] memory clothingTypes = [
            ImagesInBytes.DRESS,
            ImagesInBytes.DRESS_SHIRT,
            ImagesInBytes.SHIRT,
            ImagesInBytes.TANK_TOP,
            ImagesInBytes.V_NECK
        ];

        return selector == clothingTypes[0]
            ? ImagesLib.Dress
            : selector == clothingTypes[1]
                ? ImagesLib.DressShirt
                : selector == clothingTypes[2]
                    ? ImagesLib.Shirt
                    : selector == clothingTypes[3] ? ImagesLib.TankTop : selector == clothingTypes[4] ? ImagesLib.VNeck : "";
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
        bytes4[9] memory hairStyles = [
            ImagesInBytes.AFRO,
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
            ? ImagesLib.Afro
            : selector == hairStyles[1]
                ? ImagesLib.BaldingHair
                : selector == hairStyles[2]
                    ? ImagesLib.BobCut
                    : selector == hairStyles[3]
                        ? ImagesLib.BunHair
                        : selector == hairStyles[4]
                            ? ImagesLib.BuzzCut
                            : selector == hairStyles[5]
                                ? ImagesLib.LongHair
                                : selector == hairStyles[6]
                                    ? ImagesLib.LongHairBack
                                    : selector == hairStyles[7] ? ImagesLib.PixieCut : selector == hairStyles[8] ? ImagesLib.ShortHair : "";
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
}
