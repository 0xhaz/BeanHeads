// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Genesis} from "src/types/Genesis.sol";

contract GenesisTest is Test {
    /// Helper function to create a Genesis struct
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
        skinColor: 3,
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

    function test_buildAvatar() public {
        string memory avatar = Genesis.buildAvatar(params);
        vm.writeFile("./output/genesis.svg", avatar);
        // console.log(avatar);
    }
}
