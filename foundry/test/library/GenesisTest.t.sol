// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Genesis} from "src/types/Genesis.sol";

contract GenesisTest is Test {
    /// Helper function to create a Genesis struct
    Genesis.SVGParams params = Genesis.SVGParams({
        accessory: 0,
        bodyType: 1,
        clothes: 1,
        hairStyle: 0,
        clothesGraphic: 0,
        eyebrowShape: 4,
        eyeShape: 5,
        facialHairType: 2,
        hatStyle: 0,
        mouthStyle: 4,
        skinColor: 3,
        clothingColor: 0,
        hairColor: 0,
        hatColor: 3,
        shapeColor: 2,
        lipColor: 1,
        faceMaskColor: 0,
        faceMask: false,
        shapes: false,
        lashes: true
    });

    function test_buildAvatar() public {
        string memory avatar = Genesis.buildAvatar(params);
        vm.writeFile("./output/genesis.svg", avatar);
        // console.log(avatar);
    }
}
