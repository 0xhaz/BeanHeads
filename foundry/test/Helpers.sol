// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Avatar} from "src/types/Avatar.sol";
import {Images, ImagesLib, ImagesInBytes} from "src/types/Constants.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Helpers is Test {
    using Images for *;
    using ImagesLib for *;
    using ImagesInBytes for *;

    Avatar.Core public core = Avatar.Core({accessory: 0, bodyType: 1, skinColor: 0x112233});

    Avatar.Appearance public appearance = Avatar.Appearance({
        eyebrowShape: 2,
        eyeShape: 1,
        mouthStyle: 4,
        facialHairType: 1,
        hairStyle: 0,
        hairColor: 0xaabbcc
    });

    Avatar.Clothing public clothing = Avatar.Clothing({
        clothes: 3, // TANK_TOP
        clothesGraphic: 0, // GATSBY
        clothingColor: 0x654321, // Clothing color
        hatStyle: 0, // BEANIE
        hatColor: 0x112233 // Hat color
    });

    Avatar.Extras public extras = Avatar.Extras({
        circleColor: 0x445566,
        lipColor: 0x998877,
        faceMaskColor: 0x123456,
        faceMask: true,
        lashes: false,
        mask: true
    });

    function getDefaultCore() public view returns (Avatar.Core memory) {
        return core;
    }

    function getCustomCore(uint8 accessory, uint8 bodyType, bytes3 skinColor)
        public
        pure
        returns (Avatar.Core memory)
    {
        return Avatar.Core({accessory: accessory, bodyType: bodyType, skinColor: skinColor});
    }

    function getDefaultAppearance() public view returns (Avatar.Appearance memory) {
        return appearance;
    }

    function getDefaultClothing() public view returns (Avatar.Clothing memory) {
        return clothing;
    }

    function getDefaultExtras() public view returns (Avatar.Extras memory) {
        return extras;
    }
}
