// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Genesis} from "src/types/Genesis.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Helpers is Test {
    Genesis.SVGParams params = Genesis.SVGParams({
        accessory: 0,
        bodyType: 1,
        clothes: 2,
        hairStyle: 1,
        clothesGraphic: 2,
        eyebrowShape: 3,
        eyeShape: 5,
        facialHairType: 2,
        hatStyle: 0,
        mouthStyle: 6,
        skinColor: 2,
        clothingColor: 0,
        hairColor: 0,
        hatColor: 3,
        shapeColor: 0,
        lipColor: 1,
        faceMaskColor: 0,
        faceMask: false,
        shapes: false,
        lashes: true
    });

    function getParams(Genesis.SVGParams memory) public view returns (string memory) {
        return string(
            abi.encodePacked(
                Strings.toString(params.accessory),
                Strings.toString(params.bodyType),
                Strings.toString(params.clothes),
                Strings.toString(params.hairStyle),
                Strings.toString(params.clothesGraphic),
                Strings.toString(params.eyebrowShape),
                Strings.toString(params.eyeShape),
                Strings.toString(params.facialHairType),
                Strings.toString(params.hatStyle),
                Strings.toString(params.mouthStyle),
                Strings.toString(params.skinColor),
                Strings.toString(params.clothingColor),
                Strings.toString(params.hairColor),
                Strings.toString(params.hatColor),
                Strings.toString(params.shapeColor),
                Strings.toString(params.lipColor),
                Strings.toString(params.faceMaskColor),
                params.faceMask ? "true" : "false",
                params.shapes ? "true" : "false",
                params.lashes ? "true" : "false"
            )
        );
    }
}
