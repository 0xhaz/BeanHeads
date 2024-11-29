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

    uint8 public accessory = 0; // ROUND_GLASSES
    uint8 public bodyType = 1; // CHEST
    uint8 public clothes = 3; // TANK_TOP
    uint8 public eyebrowShape = 2; // LEFT_LOWERED_EYEBROW
    uint8 public eyeShape = 1; // DIZZY_EYES
    uint8 public mouthStyle = 4; // SAD
    uint8 public facialHairType = 1; // STUBBLE
    uint8 public clothesGraphic = 0; // GATSBY
    uint8 public hairStyle = 0; // LONG_HAIR
    uint8 public hatStyle = 0; // BEANIE
    bytes3 public faceMaskColor = 0x123456;
    bytes3 public clothingColor = 0x654321;
    bytes3 public hairColor = 0xaabbcc;
    bytes3 public hatColor = 0x112233;
    bytes3 public circleColor = 0x445566;
    bytes3 public lipColor = 0x998877;
    bytes3 public skinColor = 0x112233;
    bool public faceMask = true;
    bool public lashes = false;
    bool public mask = true;
}
