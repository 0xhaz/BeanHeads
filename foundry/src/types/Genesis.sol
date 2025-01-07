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

    struct SVGParams {
        uint8 accessory;
        uint8 bodyType;
        uint8 clothes;
        uint8 hairStyle;
        uint8 clothesGraphic;
        uint8 eyebrowShape;
        uint8 eyeShape;
        uint8 facialHairType;
        uint8 hatStyle;
        uint8 mouthStyle;
        uint8 skinColor;
        uint8 clothingColor;
        uint8 hairColor;
        uint8 hatColor;
        uint8 shapeColor;
        uint8 lipColor;
        uint8 faceMaskColor;
        bool faceMask;
        bool shapes;
        bool lashes;
    }

    function buildAvatar(SVGParams memory params) internal pure returns (string memory) {
        (string memory hairBack, string memory hairFront) = getHairComponentsById(params.hairStyle, params.hairColor);

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">',
                "<g>",
                isShapesOn(params.shapes, params.shapeColor),
                "</g>",
                "<g>",
                hairBack,
                "</g>",
                "<g>",
                BodyDetail.getBodyById(params.bodyType, params.skinColor, params.clothingColor),
                "</g>",
                "<g>",
                hairFront,
                "</g>",
                "<g>",
                ClothingDetail.getClothingById(params.bodyType, params.clothes, params.clothingColor),
                "</g>",
                "<g>",
                HairDetail.getHairById(params.hairStyle, params.hairColor),
                "</g>",
                "<g>",
                ClothingGraphicDetail.getClothingGraphicById(params.clothes, params.clothesGraphic),
                "</g>",
                "<g>",
                EyesDetail.getEyeById(params.eyeShape, params.skinColor),
                "</g>",
                "<g>",
                FacialHairDetail.getFacialHairById(params.facialHairType),
                "</g>",
                "<g>",
                HatsDetail.getHatsById(params.hatStyle, params.hatColor),
                "</g>",
                "<g>",
                MouthDetail.getMouthById(params.mouthStyle, params.lipColor),
                "</g>",
                "<g>",
                EyebrowDetail.getEyebrowById(params.eyebrowShape),
                "</g>",
                "<g>",
                AccessoryDetail.getAccessoryById(params.accessory),
                "</g>",
                "<g>",
                isFaceMaskOn(params.faceMask, params.faceMaskColor),
                "</g>",
                "<g>",
                isLashesOn(params.eyeShape, params.lashes),
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
        string[20] memory attributesArray;

        // Store attributes as strings in a memory array
        attributesArray[0] =
            string(abi.encodePacked('{"trait_type": "Accessory", "value": "', params.accessory.toString(), '"}'));
        attributesArray[1] =
            string(abi.encodePacked('{"trait_type": "Body Type", "value": "', params.bodyType.toString(), '"}'));
        attributesArray[2] =
            string(abi.encodePacked('{"trait_type": "Clothes", "value": "', params.clothes.toString(), '"}'));
        attributesArray[3] =
            string(abi.encodePacked('{"trait_type": "Hair Style", "value": "', params.hairStyle.toString(), '"}'));
        attributesArray[4] = string(
            abi.encodePacked('{"trait_type": "Clothes Graphic", "value": "', params.clothesGraphic.toString(), '"}')
        );
        attributesArray[5] =
            string(abi.encodePacked('{"trait_type": "Eyebrow Shape", "value": "', params.eyebrowShape.toString(), '"}'));
        attributesArray[6] =
            string(abi.encodePacked('{"trait_type": "Eye Shape", "value": "', params.eyeShape.toString(), '"}'));
        attributesArray[7] = string(
            abi.encodePacked('{"trait_type": "Facial Hair Type", "value": "', params.facialHairType.toString(), '"}')
        );
        attributesArray[8] =
            string(abi.encodePacked('{"trait_type": "Hat Style", "value": "', params.hatStyle.toString(), '"}'));
        attributesArray[9] =
            string(abi.encodePacked('{"trait_type": "Mouth Style", "value": "', params.mouthStyle.toString(), '"}'));
        attributesArray[10] =
            string(abi.encodePacked('{"trait_type": "Skin Color", "value": "', params.skinColor.toString(), '"}'));
        attributesArray[11] = string(
            abi.encodePacked('{"trait_type": "Clothing Color", "value": "', params.clothingColor.toString(), '"}')
        );
        attributesArray[12] =
            string(abi.encodePacked('{"trait_type": "Hair Color", "value": "', params.hairColor.toString(), '"}'));
        attributesArray[13] =
            string(abi.encodePacked('{"trait_type": "Hat Color", "value": "', params.hatColor.toString(), '"}'));
        attributesArray[14] =
            string(abi.encodePacked('{"trait_type": "Shape Color", "value": "', params.shapeColor.toString(), '"}'));
        attributesArray[15] =
            string(abi.encodePacked('{"trait_type": "Lip Color", "value": "', params.lipColor.toString(), '"}'));
        attributesArray[16] = string(
            abi.encodePacked('{"trait_type": "Face Mask Color", "value": "', params.faceMaskColor.toString(), '"}')
        );
        attributesArray[17] =
            string(abi.encodePacked('{"trait_type": "Face Mask", "value": "', params.faceMask ? "true" : "false", '"}'));
        attributesArray[18] =
            string(abi.encodePacked('{"trait_type": "Shapes", "value": "', params.shapes ? "true" : "false", '"}'));
        attributesArray[19] =
            string(abi.encodePacked('{"trait_type": "Lashes", "value": "', params.lashes ? "true" : "false", '"}'));

        // Concatenate all attributes
        string memory attributes = "[";
        for (uint256 i = 0; i < attributesArray.length; i++) {
            attributes =
                string(abi.encodePacked(attributes, attributesArray[i], i < attributesArray.length - 1 ? "," : ""));
        }
        attributes = string(abi.encodePacked(attributes, "]"));

        return attributes;
    }

    function generateBase64SVG(Genesis.SVGParams memory params) internal pure returns (string memory) {
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500">',
                '<rect width="500" height="500" fill="',
                params.skinColor,
                '"/>',
                '<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-size="24">',
                "BeanHeads Avatar</text>",
                "</svg>"
            )
        );

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
    }
}
