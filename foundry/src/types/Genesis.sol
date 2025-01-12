// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {AccessoryDetail} from "src/libraries/baseModel/AccessoryDetail.sol";
import {BodyDetail} from "src/libraries/baseModel/BodyDetail.sol";
import {ClothingDetail} from "src/libraries/baseModel/ClothingDetail.sol";
import {ClothingGraphicDetail} from "src/libraries/baseModel/ClothingGraphicDetail.sol";
import {EyebrowDetail} from "src/libraries/baseModel/EyebrowDetail.sol";
import {EyesDetail} from "src/libraries/baseModel/EyesDetail.sol";
import {FacialHairDetail} from "src/libraries/baseModel/FacialHairDetail.sol";
import {HairDetail} from "src/libraries/baseModel/HairDetail.sol";
import {HatsDetail} from "src/libraries/baseModel/HatsDetail.sol";
import {OptItems} from "src/libraries/baseModel/OptItems.sol";
import {MouthDetail} from "src/libraries/baseModel/MouthDetail.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library Genesis {
    using Strings for uint8;

    struct HairParams {
        uint8 hairStyle;
        uint8 hairColor;
    }

    struct BodyParams {
        uint8 bodyType;
        uint8 skinColor;
    }

    struct ClothingParams {
        uint8 clothes;
        uint8 clothingColor;
        uint8 clothesGraphic;
    }

    struct FacialFeaturesParams {
        uint8 eyebrowShape;
        uint8 eyeShape;
        uint8 facialHairType;
        uint8 mouthStyle;
        uint8 lipColor;
    }

    struct AccessoryParams {
        uint8 accessoryId;
        uint8 hatStyle;
        uint8 hatColor;
    }

    struct OtherParams {
        bool faceMask;
        uint8 faceMaskColor;
        bool shapes;
        uint8 shapeColor;
        bool lashes;
    }

    struct SVGParams {
        HairParams hairParams;
        BodyParams bodyParams;
        ClothingParams clothingParams;
        FacialFeaturesParams facialFeaturesParams;
        AccessoryParams accessoryParams;
        OtherParams otherParams;
    }

    function buildAvatar(SVGParams memory params) internal pure returns (string memory) {
        (string memory hairBack, string memory hairFront) =
            getHairComponentsById(params.hairParams.hairStyle, params.hairParams.hairColor);

        (string memory hairSVG,) = HairDetail.getHairById(params.hairParams.hairStyle, params.hairParams.hairColor);

        (string memory accessorySVG,) = AccessoryDetail.getAccessoryById(params.accessoryParams.accessoryId);

        (string memory bodySVG,) = BodyDetail.getBodyById(
            params.bodyParams.bodyType, params.bodyParams.skinColor, params.clothingParams.clothingColor
        );

        (string memory clothesSVG,) = ClothingDetail.getClothingById(
            params.bodyParams.bodyType, params.clothingParams.clothes, params.clothingParams.clothingColor
        );

        (string memory clothingGraphicSVG,) = ClothingGraphicDetail.getClothingGraphicById(
            params.clothingParams.clothes, params.clothingParams.clothesGraphic
        );

        (string memory eyebrowShapeSVG,) = EyebrowDetail.getEyebrowById(params.facialFeaturesParams.eyebrowShape);

        (string memory eyeSVG,) =
            EyesDetail.getEyeById(params.facialFeaturesParams.eyeShape, params.bodyParams.skinColor);

        (string memory facialHairSVG,) = FacialHairDetail.getFacialHairById(params.facialFeaturesParams.facialHairType);

        (string memory hatSVG,) = HatsDetail.getHatsById(
            params.accessoryParams.hatStyle, params.accessoryParams.hatColor, params.hairParams.hairStyle
        );

        (string memory mouthNameSVG,) =
            MouthDetail.getMouthById(params.facialFeaturesParams.mouthStyle, params.facialFeaturesParams.lipColor);

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">',
                "<g>",
                isShapesOn(params.otherParams.shapes, params.otherParams.shapeColor),
                "</g>",
                "<g>",
                hairBack,
                "</g>",
                "<g>",
                bodySVG,
                "</g>",
                "<g>",
                hairFront,
                "</g>",
                "<g>",
                clothesSVG,
                "</g>",
                "<g>",
                hairSVG,
                "</g>",
                "<g>",
                clothingGraphicSVG,
                "</g>",
                "<g>",
                eyeSVG,
                "</g>",
                "<g>",
                facialHairSVG,
                "</g>",
                "<g>",
                hatSVG,
                "</g>",
                "<g>",
                mouthNameSVG,
                "</g>",
                "<g>",
                eyebrowShapeSVG,
                "</g>",
                "<g>",
                accessorySVG,
                "</g>",
                "<g>",
                isFaceMaskOn(params.otherParams.faceMask, params.otherParams.faceMaskColor),
                "</g>",
                "<g>",
                isLashesOn(params.facialFeaturesParams.eyeShape, params.otherParams.lashes),
                "</g>",
                "</svg>"
            )
        );

        return svg;
    }

    function isFaceMaskOn(bool faceMask, uint8 color) private pure returns (string memory) {
        if (faceMask) {
            return OptItems.faceMaskSVG(color);
        }
        return "";
    }

    function isShapesOn(bool shapes, uint8 color) private pure returns (string memory) {
        if (shapes) {
            return OptItems.shapeSVG(color);
        }
        return "";
    }

    function isLashesOn(uint8 eyeShape, bool lashes) private pure returns (string memory) {
        if (lashes) {
            return OptItems.lashesSVG(eyeShape);
        }

        return "";
    }

    function getHairComponentsById(uint8 id, uint8 color)
        private
        pure
        returns (string memory back, string memory front)
    {
        if (id == 1) {
            (back, front) = HairDetail.afroHairSVG(color);
        } else if (id == 3) {
            (back, front) = HairDetail.bobCutSVG(color);
        } else if (id == 5) {
            (back, front) = HairDetail.longHairSVG(color);
        } else {
            return ("", "");
        }
    }

    function buildAttributes(Genesis.SVGParams memory params) internal pure returns (string memory) {
        // Initialize JSON string
        string memory attributes = "[";

        unchecked {
            string[2] memory hairAttributes = buildHairAttributes(params.hairParams);
            for (uint256 i = 0; i < hairAttributes.length; i++) {
                attributes = string(abi.encodePacked(attributes, hairAttributes[i], ","));
            }

            string[3] memory accessoryAttributes = buildAccessoryAttributes(params.accessoryParams);
            for (uint256 i = 0; i < accessoryAttributes.length; i++) {
                attributes = string(abi.encodePacked(attributes, accessoryAttributes[i], ","));
            }

            string[2] memory bodyAttributes = buildBodyAttributes(params.bodyParams);
            for (uint256 i = 0; i < bodyAttributes.length; i++) {
                attributes = string(abi.encodePacked(attributes, bodyAttributes[i], ","));
            }

            string[3] memory clothingAttributes = buildClothingAttributes(params.clothingParams);
            for (uint256 i = 0; i < clothingAttributes.length; i++) {
                attributes = string(abi.encodePacked(attributes, clothingAttributes[i], ","));
            }

            string[5] memory facialFeaturesAttributes = buildFacialFeaturesAttributes(params.facialFeaturesParams);
            for (uint256 i = 0; i < facialFeaturesAttributes.length; i++) {
                attributes = string(abi.encodePacked(attributes, facialFeaturesAttributes[i], ","));
            }

            string[5] memory otherAttributes = buildOtherAttributes(params.otherParams);
            for (uint256 i = 0; i < otherAttributes.length; i++) {
                attributes = string(abi.encodePacked(attributes, otherAttributes[i], ","));
            }
        }

        // Remove trailing comma and close JSON array
        bytes memory tempBytes = bytes(attributes);
        if (tempBytes.length > 1) {
            tempBytes[tempBytes.length - 1] = "]"; // Replace last comma with closing bracket
        } else {
            attributes = "[]"; // If no attributes, return empty array
        }

        return string(tempBytes);
    }

    function buildHairAttributes(HairParams memory params) private pure returns (string[2] memory hairAttributes) {
        string memory hairStyleName = HairDetail.getHairTypeName(params.hairStyle);
        string memory hairColorName = HairDetail.getHairColorName(params.hairColor);

        hairAttributes[0] = string(abi.encodePacked('{"trait_type": "Hair Style", "value": "', hairStyleName, '"}'));

        hairAttributes[1] = string(abi.encodePacked('{"trait_type": "Hair Color", "value": "', hairColorName, '"}'));

        return hairAttributes;
    }

    function buildAccessoryAttributes(AccessoryParams memory params)
        private
        pure
        returns (string[3] memory accessoryAttributes)
    {
        string memory accessoryName = AccessoryDetail.getAccessoryName(params.accessoryId);
        string memory hatName = HatsDetail.getHatsName(params.hatStyle);
        string memory hatColorName = HatsDetail.getHatsColorName(params.hatColor);

        accessoryAttributes[0] = string(abi.encodePacked('{"trait_type": "Accessory", "value": "', accessoryName, '"}'));

        accessoryAttributes[1] = string(abi.encodePacked('{"trait_type": "Hat Style", "value": "', hatName, '"}'));

        accessoryAttributes[2] = string(abi.encodePacked('{"trait_type": "Hat Color", "value": "', hatColorName, '"}'));

        return accessoryAttributes;
    }

    function buildBodyAttributes(BodyParams memory params) private pure returns (string[2] memory bodyAttributes) {
        string memory bodyTypeName = BodyDetail.getBodyTypeName(params.bodyType);
        string memory skinColorName = BodyDetail.getBodyColorName(params.skinColor);

        bodyAttributes[0] = string(abi.encodePacked('{"trait_type": "Body Type", "value": "', bodyTypeName, '"}'));

        bodyAttributes[1] = string(abi.encodePacked('{"trait_type": "Skin Color", "value": "', skinColorName, '"}'));

        return bodyAttributes;
    }

    function buildClothingAttributes(ClothingParams memory params)
        private
        pure
        returns (string[3] memory clothingAttributes)
    {
        string memory clothesName = ClothingDetail.getClothingName(params.clothes);
        string memory clothesColorName = ClothingDetail.getClothingColor(params.clothingColor);
        string memory clothingGraphicName = ClothingGraphicDetail.getClothingGraphicName(params.clothesGraphic);

        clothingAttributes[0] = string(abi.encodePacked('{"trait_type": "Clothes", "value": "', clothesName, '"}'));

        clothingAttributes[1] =
            string(abi.encodePacked('{"trait_type": "Clothes Color", "value": "', clothesColorName, '"}'));

        clothingAttributes[2] =
            string(abi.encodePacked('{"trait_type": "Clothes Graphic", "value": "', clothingGraphicName, '"}'));

        return clothingAttributes;
    }

    function buildFacialFeaturesAttributes(FacialFeaturesParams memory params)
        private
        pure
        returns (string[5] memory facialFeaturesAttributes)
    {
        string memory eyebrowShapeName = EyebrowDetail.getEyebrowName(params.eyebrowShape);
        string memory eyeName = EyesDetail.getEyeName(params.eyeShape);
        string memory facialHairName = FacialHairDetail.getFacialHairName(params.facialHairType);
        string memory mouthStyleName = MouthDetail.getMouthName(params.mouthStyle);
        string memory lipColorName = MouthDetail.getMouthColor(params.lipColor);

        facialFeaturesAttributes[0] =
            string(abi.encodePacked('{"trait_type": "Eyebrow Shape", "value": "', eyebrowShapeName, '"}'));

        facialFeaturesAttributes[1] = string(abi.encodePacked('{"trait_type": "Eye Shape", "value": "', eyeName, '"}'));

        facialFeaturesAttributes[2] =
            string(abi.encodePacked('{"trait_type": "Facial Hair Type", "value": "', facialHairName, '"}'));

        facialFeaturesAttributes[3] =
            string(abi.encodePacked('{"trait_type": "Mouth Style", "value": "', mouthStyleName, '"}'));

        facialFeaturesAttributes[4] =
            string(abi.encodePacked('{"trait_type": "Lip Color", "value": "', lipColorName, '"}'));

        return facialFeaturesAttributes;
    }

    function buildOtherAttributes(OtherParams memory params) private pure returns (string[5] memory otherAttributes) {
        otherAttributes[0] =
            string(abi.encodePacked('{"trait_type": "Face Mask", "value": "', params.faceMask ? "true" : "false", '"}'));

        otherAttributes[1] = string(
            abi.encodePacked('{"trait_type": "Face Mask Color", "value": "', params.faceMaskColor.toString(), '"}')
        );

        otherAttributes[2] =
            string(abi.encodePacked('{"trait_type": "Shapes", "value": "', params.shapes ? "true" : "false", '"}'));

        otherAttributes[3] =
            string(abi.encodePacked('{"trait_type": "Shape Color", "value": "', params.shapeColor.toString(), '"}'));

        otherAttributes[4] =
            string(abi.encodePacked('{"trait_type": "Lashes", "value": "', params.lashes ? "true" : "false", '"}'));

        return otherAttributes;
    }

    function generateBase64SVG(Genesis.SVGParams memory params) internal pure returns (string memory) {
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500">',
                '<rect width="500" height="500" fill="',
                params.bodyParams.skinColor,
                '"/>',
                '<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-size="24">',
                "BeanHeads Avatar</text>",
                "</svg>"
            )
        );

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
    }
}
