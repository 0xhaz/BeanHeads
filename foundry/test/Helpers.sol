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

    // uint8 public accessory = 0; // ROUND_GLASSES
    // uint8 public bodyType = 1; // CHEST
    // uint8 public clothes = 3; // TANK_TOP
    // uint8 public eyebrowShape = 2; // LEFT_LOWERED_EYEBROW
    // uint8 public eyeShape = 1; // DIZZY_EYES
    // uint8 public mouthStyle = 4; // SAD
    // uint8 public facialHairType = 1; // STUBBLE
    // uint8 public clothesGraphic = 0; // GATSBY
    // uint8 public hairStyle = 0; // LONG_HAIR
    // uint8 public hatStyle = 0; // BEANIE
    // bytes3 public faceMaskColor = 0x123456;
    // bytes3 public clothingColor = 0x654321;
    // bytes3 public hairColor = 0xaabbcc;
    // bytes3 public hatColor = 0x112233;
    // bytes3 public circleColor = 0x445566;
    // bytes3 public lipColor = 0x998877;
    // bytes3 public skinColor = 0x112233;
    // bool public faceMask = true;
    // bool public lashes = false;
    // bool public mask = true;

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
