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

library Genesis {
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
                ClothingGraphicDetail.getClothingGraphicById(params.clothesGraphic),
                "</g>",
                "<g>",
                EyesDetail.getEyeById(params.eyeShape),
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
                isShapesOn(params.shapes, params.shapeColor),
                "</g>",
                "<g>",
                isLashesOn(params.lashes),
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

    function isLashesOn(bool lashes) private pure returns (string memory) {
        if (lashes) {
            return OptItems.lashesSVG();
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
}
