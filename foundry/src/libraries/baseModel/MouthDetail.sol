// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {SVGBody} from "./SVGBody.sol";

library MouthDetail {
    error MouthDetail__InvalidMouthType(uint8 id);
    error MouthDetail__InvalidLipsColor(uint8 id);

    string constant GRIN = "Grin";
    string constant LIPS = "Lips";
    string constant OPEN_MOUTH = "Open Mouth";
    string constant OPEN_SMILE = "Open Smile";
    string constant SAD = "Sad";
    string constant SERIOUS_MOUTH = "Serious Mouth";
    string constant TONGUE = "Tongue";

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

    struct Mouth {
        string name;
        string svg;
    }

    enum LipsColor {
        LIPS_RED,
        LIPS_PURPLE,
        LIPS_PINK,
        LIPS_TURQUOISE,
        LIPS_GREEN
    }

    /// @dev Retrieves the base and shadow color for the lips
    /// @param id The id of the lips color
    function getColorsForLips(uint8 id) internal pure returns (bytes3 baseColor, bytes3 shadowColor) {
        if (id == uint8(LipsColor.LIPS_RED)) {
            return (LIPS_RED_BASE, LIPS_RED_SHADOW);
        } else if (id == uint8(LipsColor.LIPS_PURPLE)) {
            return (LIPS_PURPLE_BASE, LIPS_PURPLE_SHADOW);
        } else if (id == uint8(LipsColor.LIPS_PINK)) {
            return (LIPS_PINK_BASE, LIPS_PINK_SHADOW);
        } else if (id == uint8(LipsColor.LIPS_TURQUOISE)) {
            return (LIPS_TURQUOISE_BASE, LIPS_TURQUOISE_SHADOW);
        } else if (id == uint8(LipsColor.LIPS_GREEN)) {
            return (LIPS_GREEN_BASE, LIPS_GREEN_SHADOW);
        } else {
            revert MouthDetail__InvalidLipsColor(id);
        }
    }

    /// @dev Converts bytes3 to a hex string for SVG
    function bytesToHex(bytes3 color) internal pure returns (string memory) {
        bytes memory buffer = new bytes(7);
        buffer[0] = "#";
        for (uint256 i = 0; i < 3; i++) {
            buffer[i * 2 + 1] = _toHexChar(uint8(color[i] >> 4));
            buffer[i * 2 + 2] = _toHexChar(uint8(color[i] & 0x0f));
        }

        return string(buffer);
    }

    /// @dev Helper to convert uint8 to hex char
    function _toHexChar(uint8 value) private pure returns (bytes1) {
        return bytes1(value < 10 ? value + 48 : value + 87);
    }

    /// @dev Returns the SVG for a grin mouth
    function grinMouthSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="grin-mouth" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M463.75,593.17c15.55,0,25.12,12.76,36.49,12.76s25.91-12.76,41.27-12.76,23.72,11.12,23.72,26.52c0,16.65-16.75,46-62.6,46s-65.4-27.74-65.4-45.45C437.23,603.89,448.2,593.17,463.75,593.17Z" style="fill:#fff;stroke:#592d3d;stroke-miterlimit:10;stroke-width:10.781752824783325px"/>'
                    '<line x1="477.85" y1="596.6" x2="477.85" y2="662.1" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:10.781752824783325px"/>'
                    '<line x1="526.99" y1="596.6" x2="526.99" y2="662.1" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:10.781752824783325px"/>'
                )
            )
        );
    }

    /// @dev Returns the SVG for a lips mouth
    function lipsMouthSVG(uint8 id) internal pure returns (string memory) {
        (bytes3 baseColor, bytes3 shadowColor) = getColorsForLips(id);

        return SVGBody.fullSVG(
            'id="lips-mouth" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M468.41,635.27a255.08,255.08,0,0,0,55.61,0q-.42-.27-.84-.6c-.71-.54-1.46-1.18-2.38-2l-2.42-2.26c-3.8-3.52-6.34-5.22-9.26-5.73-3.75-.65-7.69,1-12.18,5.81a1,1,0,0,1-1.45,0c-4.49-4.77-8.43-6.46-12.18-5.81-2.92.51-5.46,2.21-9.27,5.73l-2.42,2.26c-.91.84-1.66,1.48-2.37,2Q468.81,635,468.41,635.27Z" style="fill:#010101"/>',
                    '<path d="M560.41,648.36l-.56-2.28C487.07,662.7,440,647.21,440,647.21l-1.83-.32a1.84,1.84,0,0,0,.49,1.78c18.05,18.05,34,30.45,61.79,30.45C529.93,679.12,542.43,666.22,560.41,648.36Z" style="fill:#f3ab98"/>',
                    '<path d="M558.55,642.44c-3.63,0-5.35-1.31-15.58-10.79-7.49-6.93-12.63-10.36-18.91-11.46-7.83-1.37-15.83-.88-24.36,7.68-8.53-8.56-16.52-9-24.36-7.68-6.28,1.1-11.42,4.53-18.91,11.46-10.23,9.48-11.95,10.79-15.58,10.79a1.84,1.84,0,0,0-1.3,3.14q26.25,26.25,60.15,26.28t60.15-26.28A1.84,1.84,0,0,0,558.55,642.44Z" style="fill:',
                    /// Base color
                    /// #dd3e3e
                    bytesToHex(baseColor),
                    '"',
                    "/>",
                    '<path d="M559.57,645.84l-.55-2.21c-70.56,16.12-118.17.53-118.17.53l-1.77-.31a1.82,1.82,0,0,0,.47,1.73q26.25,26.25,60.15,26.28Q533.38,671.86,559.57,645.84Z" style="fill:',
                    /// Shadow color
                    /// #c43333
                    bytesToHex(shadowColor),
                    '"',
                    "/>",
                    '<path d="M479.28,650.39c13.45-.94,26.69-1.44,39.89-3,6.59-.76,13.15-1.74,19.67-2.86s13-2.41,19.51-3.8l1.34,5.85q-9.87,2.34-19.92,3.81t-20.16,2.06c-6.75.37-13.5.54-20.25.27A127.84,127.84,0,0,1,479.28,650.39Z" style="fill:#592d3d"/>',
                    '<path d="M441.79,641.31c1.69.43,3.57,1,5.38,1.48s3.65,1.08,5.49,1.63,3.68,1.1,5.52,1.77a27.06,27.06,0,0,1,5.46,2.64,22.06,22.06,0,0,1-6.05.9c-2,0-3.95-.16-5.93-.32s-3.93-.47-5.88-.85a38.82,38.82,0,0,1-5.86-1.55Z" style="fill:#592d3d"/>',
                    '<path d="M558.55,642.44c-3.63,0-5.35-1.31-15.58-10.79-7.49-6.93-12.53-11.29-18.91-11.46-11.21-.3-19.15,6.12-24.76,6.12s-10.45-7.53-24-6.12c-6.34.66-11.42,4.53-18.91,11.46-10.23,9.48-11.95,10.79-15.58,10.79a1.84,1.84,0,0,0-1.3,3.14q26.25,26.25,60.15,26.28t60.15-26.28A1.84,1.84,0,0,0,558.55,642.44Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M524.06,626.48a41.49,41.49,0,0,0-12.19,2.94c-1.94.77-3.87,1.6-5.85,2.42a20.2,20.2,0,0,1-6.42,1.74,8.92,8.92,0,0,1-3.47-.64,24,24,0,0,1-3-1.4,59.7,59.7,0,0,0-5.58-2.83,27.56,27.56,0,0,0-5.94-1.73,38.5,38.5,0,0,0-6.29-.5,26.31,26.31,0,0,1,6.4-.48,24.54,24.54,0,0,1,6.38,1.25,46,46,0,0,1,5.9,2.6c1.87.94,3.71,1.83,5.52,1.74a19.76,19.76,0,0,0,5.8-1.51c2-.71,4-1.51,6-2.13A30,30,0,0,1,524.06,626.48Z" style="fill:#fff"/><path d="M472.62,652.36c3.22,0,3.23-5,0-5s-3.22,5,0,5Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    /// @dev Returns the SVG for an open mouth
    function openMouthSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="open-mouth" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<circle cx="499.7" cy="642.93" r="53.95" style="fill:#592d3d"/>',
                    '<path d="M491.21,663.39c-14.07-3.37-27.62,1-33.45,9.87a48.46,48.46,0,0,0,52.82,20.14,49.33,49.33,0,0,0,6-2C517.93,679.39,507.08,667.18,491.21,663.39Z" style="fill:#f28195"/>',
                    '<path d="M478.65,652l.8,0h.65c.43,0,.84,0,1.25.06a17.92,17.92,0,0,1,2.44.35,21,21,0,0,1,4.74,1.53,18.15,18.15,0,0,1,7.78,6.65,17.17,17.17,0,0,1,2.77,9.28,14.75,14.75,0,0,1-2.69,8.47c-1.3-2.76-2.24-5.2-3.31-7.29a24,24,0,0,0-1.62-2.87,12.38,12.38,0,0,0-1.95-2.21,13,13,0,0,0-4.82-2.66,24.72,24.72,0,0,0-2.85-.69c-.49-.07-1-.16-1.47-.22l-.73-.07-.33,0c-.08,0-.26,0-.19,0Z" style="fill:#592d3d"/>',
                    '<circle cx="499.7" cy="642.93" r="53.95" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>'
                )
            )
        );
    }

    /// @dev Returns the SVG for an open smile mouth
    function openSmileMouthSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="open-smile-mouth" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M443.14,621.86c0-18.9,113.72-16.06,113.72,0a56.86,56.86,0,0,1-113.72,0Z" style="fill:#592d3d"/>',
                    '<path d="M495,643c-16.95-1-31.73,6.75-36.65,18.22a56.86,56.86,0,0,0,65.14,12.53A55.39,55.39,0,0,0,530,670.2C529.08,656.09,514.06,644.18,495,643Z" style="fill:#f28195"/>',
                    '<path d="M443.14,621.86c0-18.9,113.72-16.06,113.72,0a56.86,56.86,0,0,1-113.72,0Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:6px"/>',
                    '<path d="M478.12,632.46c.45-.11.63-.16.92-.21l.75-.14c.49-.09,1-.14,1.46-.18a21.54,21.54,0,0,1,2.89-.1,25,25,0,0,1,5.79.81,21.4,21.4,0,0,1,10.35,6.1,20.18,20.18,0,0,1,5.08,10.16A17.27,17.27,0,0,1,504,659.25c-2.07-2.93-3.66-5.56-5.32-7.76a28.41,28.41,0,0,0-2.45-3,14.06,14.06,0,0,0-2.7-2.16,15.48,15.48,0,0,0-6.11-2.09A29.5,29.5,0,0,0,484,644c-.59,0-1.18,0-1.76.05l-.85.06-.39,0c-.1,0-.3,0-.23,0Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    /// @dev Returns the SVG for a sad mouth
    function sadMouthSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="sad-mouth" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M538.71,665.74c-15.55,0-25.12-12.76-36.48-12.76S476.31,665.74,461,665.74s-23.73-11.11-23.73-26.51c0-16.65,16.75-46.06,62.61-46.06s65.39,27.74,65.39,45.46C565.23,655,554.27,665.74,538.71,665.74Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    /// @dev Returns the SVG for a serious mouth
    function seriousMouthSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="serious-mouth" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<line x1="446.66" y1="606.02" x2="542.53" y2="606.02" style="fill:none;stroke:#592d3d;stroke-linecap:round;stroke-miterlimit:10;stroke-width:12px"/>'
                )
            )
        );
    }

    /// @dev Returns the SVG for a tongue mouth
    function toungeMouthSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="tounge-mouth" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M443.14,621.86c0-18.9,113.72-16.06,113.72,0a56.86,56.86,0,0,1-113.72,0Z" style="fill:#592d3d"/>',
                    '<path d="M443.14,621.86c0-18.9,113.72-16.06,113.72,0a56.86,56.86,0,0,1-113.72,0Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:6px"/>',
                    '<path d="M532.49,646.6c0-8.06-14.55-14.6-32.49-14.6s-32.49,6.54-32.49,14.6h0v44.34c0,14.41,14.55,26.08,32.49,26.08s32.49-11.67,32.49-26.08V646.61Z" style="fill:#f18094"/>',
                    '<path d="M532.49,646.6c0-8.06-14.55-14.6-32.49-14.6s-32.49,6.54-32.49,14.6h0v44.34c0,14.41,14.55,26.08,32.49,26.08s32.49-11.67,32.49-26.08V646.61Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M479.31,626.6l.91-.21.76-.14c.49-.08,1-.14,1.46-.18a21.42,21.42,0,0,1,2.89-.1,25,25,0,0,1,5.79.81,21.39,21.39,0,0,1,10.34,6.11A20.07,20.07,0,0,1,506.54,643a17.19,17.19,0,0,1-1.37,10.35c-2.08-2.93-3.66-5.55-5.32-7.76a27.26,27.26,0,0,0-2.46-3,14.09,14.09,0,0,0-2.69-2.16,15.31,15.31,0,0,0-6.11-2.08,25.67,25.67,0,0,0-3.43-.22c-.59,0-1.18,0-1.76,0l-.85.06-.4,0c-.09,0-.29,0-.22,0Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    /// @dev Returns the SVG for a mouth based on the given mouth type
    function getMouthById(uint8 id, uint8 color) internal pure returns (Mouth memory) {
        if (id == 1) {
            return Mouth(GRIN, grinMouthSVG());
        } else if (id == 2) {
            return Mouth(LIPS, lipsMouthSVG(color));
        } else if (id == 3) {
            return Mouth(OPEN_MOUTH, openMouthSVG());
        } else if (id == 4) {
            return Mouth(OPEN_SMILE, openSmileMouthSVG());
        } else if (id == 5) {
            return Mouth(SAD, sadMouthSVG());
        } else if (id == 6) {
            return Mouth(SERIOUS_MOUTH, seriousMouthSVG());
        } else if (id == 7) {
            return Mouth(TONGUE, toungeMouthSVG());
        } else {
            revert MouthDetail__InvalidMouthType(id);
        }
    }
}