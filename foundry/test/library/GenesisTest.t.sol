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
        hairStyle: 1,
        clothesGraphic: 0,
        eyebrowShape: 5,
        eyeShape: 6,
        facialHairType: 0,
        hatStyle: 0,
        mouthStyle: 4,
        skinColor: 3,
        clothingColor: 0,
        hairColor: 0,
        hatColor: 1,
        shapeColor: 1,
        lipColor: 1,
        faceMaskColor: 1,
        faceMask: false,
        shapes: false,
        lashes: false
    });

    function test_buildAvatar() public {
        string memory avatar = Genesis.buildAvatar(params);
        vm.writeFile("./output/genesis.svg", avatar);
        console.log(avatar);
    }
}
