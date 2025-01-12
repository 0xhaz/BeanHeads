// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Genesis} from "src/types/Genesis.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Helpers is Test {
    Genesis.HairParams hairParams = Genesis.HairParams({hairStyle: 1, hairColor: 0});
    Genesis.BodyParams bodyParams = Genesis.BodyParams({bodyType: 1, skinColor: 3});
    Genesis.ClothingParams clothingParams = Genesis.ClothingParams({clothes: 3, clothingColor: 0, clothesGraphic: 2});
    Genesis.FacialFeaturesParams facialFeaturesParams =
        Genesis.FacialFeaturesParams({eyebrowShape: 3, eyeShape: 5, facialHairType: 2, mouthStyle: 6, lipColor: 1});
    Genesis.AccessoryParams accessoryParams = Genesis.AccessoryParams({accessoryId: 1, hatStyle: 1, hatColor: 3});
    Genesis.OtherParams otherParams =
        Genesis.OtherParams({faceMask: false, faceMaskColor: 0, shapes: false, shapeColor: 0, lashes: true});
    Genesis.SVGParams public params = Genesis.SVGParams({
        hairParams: hairParams,
        bodyParams: bodyParams,
        clothingParams: clothingParams,
        facialFeaturesParams: facialFeaturesParams,
        accessoryParams: accessoryParams,
        otherParams: otherParams
    });

    function getParams(Genesis.SVGParams memory) public view returns (string memory) {
        return string(
            abi.encodePacked(
                Strings.toString(params.accessoryParams.accessoryId),
                Strings.toString(params.bodyParams.bodyType),
                Strings.toString(params.clothingParams.clothes),
                Strings.toString(params.hairParams.hairStyle),
                Strings.toString(params.clothingParams.clothesGraphic),
                Strings.toString(params.facialFeaturesParams.eyebrowShape),
                Strings.toString(params.facialFeaturesParams.eyeShape),
                Strings.toString(params.facialFeaturesParams.facialHairType),
                Strings.toString(params.accessoryParams.hatStyle),
                Strings.toString(params.facialFeaturesParams.mouthStyle),
                Strings.toString(params.bodyParams.skinColor),
                Strings.toString(params.clothingParams.clothingColor),
                Strings.toString(params.hairParams.hairColor),
                Strings.toString(params.accessoryParams.hatColor),
                Strings.toString(params.otherParams.shapeColor),
                Strings.toString(params.facialFeaturesParams.lipColor),
                Strings.toString(params.otherParams.faceMaskColor),
                params.otherParams.faceMask ? "true" : "false",
                params.otherParams.shapes ? "true" : "false",
                params.otherParams.lashes ? "true" : "false"
            )
        );
    }
}
