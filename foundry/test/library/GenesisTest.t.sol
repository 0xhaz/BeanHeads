// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Genesis} from "src/types/Genesis.sol";

contract GenesisTest is Test {
    /// Helper function to create a Genesis struct
    Genesis.SVGParams params = Genesis.SVGParams({
        bodyType: 1,
        clothes: 1,
        hairStyle: 1,
        clothesGraphic: 0,
        eyebrowShape: 2,
        accessory: 1,
        eyeShape: 6,
        facialHairType: 0,
        hatStyle: 0,
        mouthStyle: 4,
        skinColor: 0,
        clothingColor: 3,
        hairColor: 1,
        hatColor: 1,
        shapeColor: 1,
        lipColor: 1,
        faceMaskColor: 1,
        faceMask: false,
        shapes: false,
        lashes: false
    });

    function test_buildAvatar() public {
        string memory svg = Genesis.buildAvatar(params);
        vm.writeFile("./output/genesis.svg", svg);
        console.log(svg);
    }
}
