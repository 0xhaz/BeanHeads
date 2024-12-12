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
        uint8 hatStyle;
        uint8 eyeShape;
        uint8 eyebrowShape;
        uint8 mouthStyle;
        uint8 hairStyle;
        uint8 facialHairType;
        bool faceMask;
    }
}
