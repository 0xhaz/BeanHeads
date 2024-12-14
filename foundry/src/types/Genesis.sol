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
import {MouthDetail} from "src/libraries/baseModel/MouthDetail.sol";

library Genesis {
    struct SVGParams {
        uint8 accessory;
        uint8 bodyType;
        uint8 clothes;
        uint8 clothesGraphic;
        uint8 eyebrowShape;
        uint8 eyeShape;
        uint8 facialHairType;
        uint8 hairStyle;
        uint8 hatStyle;
        uint8 mouthStyle;
        bool faceMask;
        bool shapes;
        bool lashes;
        bytes3 skinColor;
        bytes3 clothingColor;
        bytes3 hairColor;
        bytes3 hatColor;
        bytes3 shapeColor;
        bytes3 lipColor;
        bytes3 faceMaskColor;
    }

    function buildAvatar(SVGParams memory params) internal pure returns (string memory) {
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">',
                // AccessoryDetail.getAccessoryById(params.accessory),
                // BodyDetail.getBodyById(params.bodyType, BodyDetail.BodyColor(uint8(params.skinColor[0]))),
                "</svg>"
            )
        );

        return svg;
    }
}
