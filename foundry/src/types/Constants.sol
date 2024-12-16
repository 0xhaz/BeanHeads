// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

library Colors {
    bytes3 constant WHITE_BASE = 0xFFFFFF;
    bytes3 constant WHITE_SHADOW = 0xE2E2E2;
    bytes3 constant BLUE_BASE = 0x85c5e5;
    bytes3 constant BLUE_SHADOW = 0x67B7D6;
    bytes3 constant BLACK_BASE = 0x633749;
    bytes3 constant BLACK_SHADOW = 0x5E3244;
    bytes3 constant GREEN_BASE = 0x89D86F;
    bytes3 constant GREEN_SHADOW = 0x7DC462;
    bytes3 constant RED_BASE = 0xD67070;
    bytes3 constant RED_SHADOW = 0xC46565;

    bytes3 constant LIGHT_SKIN_BASE = 0xfdd2b2;
    bytes3 constant LIGHT_SKIN_SHADOW = 0xf3ab98;
    bytes3 constant YELLOW_SKIN_BASE = 0xfbe8b3;
    bytes3 constant YELLOW_SKIN_SHADOW = 0xedd494;
    bytes3 constant BROWN_SKIN_BASE = 0xd8985d;
    bytes3 constant BROWN_SKIN_SHADOW = 0xc6854e;
    bytes3 constant DARK_SKIN_BASE = 0xa56941;
    bytes3 constant DARK_SKIN_SHADOW = 0x8d5638;
    bytes3 constant RED_SKIN_BASE = 0xcc734c;
    bytes3 constant RED_SKIN_SHADOW = 0xb56241;
    bytes3 constant BLACK_SKIN_BASE = 0x754437;
    bytes3 constant BLACK_SKIN_SHADOW = 0x6b3d34;

    bytes3 constant DEFAULT_STROKE = 0x592d3d;
    bytes3 constant HAIR_BLONDE_BASE = 0xFEDC58;
    bytes3 constant HAIR_BLONDE_SHADOW = 0xEDBF2E;
    bytes3 constant HAIR_ORANGE_BASE = 0xD96E27;
    bytes3 constant HAIR_ORANGE_SHADOW = 0xC65C22;
    bytes3 constant HAIR_BLACK_BASE = 0x592d3d;
    bytes3 constant HAIR_BLACK_SHADOW = 0x592d3d;
    bytes3 constant HAIR_WHITE_BASE = 0xffffff;
    bytes3 constant HAIR_WHITE_SHADOW = 0xE2E2E2;
    bytes3 constant HAIR_BROWN_BASE = 0xA56941;
    bytes3 constant HAIR_BROWN_SHADOW = 0x8D5638;
    bytes3 constant HAIR_BLUE_BASE = 0x85c5e5;
    bytes3 constant HAIR_BLUE_SHADOW = 0x67B7D6;
    bytes3 constant HAIR_PINK_BASE = 0xD69AC7;
    bytes3 constant HAIR_PINK_SHADOW = 0xC683B4;

    bytes3 constant LIPS_RED_BASE = 0xdd3e3e;
    bytes3 constant LIPS_RED_SHADOW = 0xc43333;
    bytes3 constant LIPS_PURPLE_BASE = 0xb256a1;
    bytes3 constant LIPS_PURPLE_SHADOW = 0x9c4490;
    bytes3 constant LIPS_PINK_BASE = 0xd69ac7;
    bytes3 constant LIPS_PINK_SHADOW = 0xc683b4;
    bytes3 constant LIPS_TURQUOISE_BASE = 0x5ccbf1;
    bytes3 constant LIPS_TURQUOISE_SHADOW = 0x49b5cd;
    bytes3 constant LIPS_GREEN_BASE = 0x4ab749;
    bytes3 constant LIPS_GREEN_SHADOW = 0x3ca047;
}

library Errors {
    error InvalidType(uint8 id);
    error InvalidColor(uint8 id);
}
