// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {SVGBody} from "./SVGBody.sol";
import {Colors, Errors} from "src/types/Constants.sol";
import {BytesConverter} from "src/libraries/BytesConverter.sol";
import {BodyDetail} from "src/libraries/baseModel/BodyDetail.sol";

library ClothingDetail {
    using Colors for bytes3;

    uint8 constant WOMEN = 1;
    uint8 constant MEN = 2;

    enum ClothColor {
        WHITE,
        BLUE,
        BLACK,
        GREEN,
        RED
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Retrieves the base and shadow color for the clothing
    /// @param color The id of the clothing color
    function getColorForClothes(uint8 color) internal pure returns (bytes3, bytes3) {
        return _getColors(color);
    }

    /// @dev SVG content for back dress
    function dressBackSVG(uint8 bodyTypeId, uint8 color) internal pure returns (string memory) {
        (bytes3 baseColor, bytes3 shadowColor) = getColorForClothes(color);
        bool includeBreastSVG = (bodyTypeId == WOMEN);
        return renderDressBackSVG(baseColor, shadowColor, includeBreastSVG, color);
    }

    /// @dev SVG content for front dress
    function dressFrontSVG(uint8 color) internal pure returns (string memory) {
        (bytes3 baseColor,) = getColorForClothes(color);
        return renderDressFrontSVG(baseColor);
    }

    /// @dev SVG content for dress
    function dressSVG(uint8 bodyTypeId, uint8 color) internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="dress" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<g id="back">',
                    dressBackSVG(bodyTypeId, color),
                    "</g>",
                    '<g id="front">',
                    dressFrontSVG(color),
                    "</g>"
                )
            )
        );
    }

    /// @dev SVG content for shirt
    function shirtSVG(uint8 bodyTypeId, uint8 color) internal pure returns (string memory) {
        (bytes3 baseColor, bytes3 shadowColor) = getColorForClothes(color);
        bool includeBreastSVG = (bodyTypeId == WOMEN);
        return renderShirtSVG(baseColor, shadowColor, includeBreastSVG, color);
    }

    /// @dev SVG content for t-shirt
    function tShirtSVG(uint8 bodyTypeId, uint8 color) internal pure returns (string memory) {
        (bytes3 baseColor, bytes3 shadowColor) = getColorForClothes(color);
        bool includeBreastSVG = (bodyTypeId == WOMEN);
        return renderTShirtSVG(baseColor, shadowColor, includeBreastSVG, color);
    }

    /// @dev SVG content for tank top
    function tankTopSVG(uint8 bodyTypeId, uint8 color) internal pure returns (string memory) {
        (bytes3 baseColor, bytes3 shadowColor) = getColorForClothes(color);
        bool includeBreastSVG = (bodyTypeId == WOMEN);
        return renderTankTopSVG(baseColor, shadowColor, includeBreastSVG, color);
    }

    /// @dev SVG content for v-neck
    function vNeckSVG(uint8 bodyTypeId, uint8 color) internal pure returns (string memory) {
        (bytes3 baseColor, bytes3 shadowColor) = getColorForClothes(color);
        bool includeBreastSVG = (bodyTypeId == WOMEN);
        return renderVNeckSVG(baseColor, shadowColor, includeBreastSVG, color);
    }

    /// @dev Returns the SVG and name for a specific clothing item
    function getClothingById(uint8 bodyId, uint8 clothId, uint8 color) internal pure returns (string memory) {
        if (clothId == 0) return "";
        if (clothId == 1) return dressSVG(bodyId, color);
        if (clothId == 2) return shirtSVG(bodyId, color);
        if (clothId == 3) return tShirtSVG(bodyId, color);
        if (clothId == 4) return tankTopSVG(bodyId, color);
        if (clothId == 5) return vNeckSVG(bodyId, color);
        revert Errors.InvalidType(clothId);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function renderDressFrontSVG(bytes3 baseColor) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<path d="M329.09,794.17c56.12,35.58,168.48,75.53,168.48,75.53l-.16,14S397,879.36,316.32,844.9C316.32,814.38,329.09,794.17,329.09,794.17Z" style="fill:',
                BytesConverter.bytesToHex(baseColor),
                ";",
                'stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                '<path d="M671.55,794.43C619,831.8,503,869.7,503,869.7l.17,14s100.41-4.3,181.08-38.76C684.29,822.67,671.55,794.43,671.55,794.43Z" style="fill:',
                BytesConverter.bytesToHex(baseColor),
                ";",
                'stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                '<path d="M320.63,822.65c.28.24.83.61,1.27.92s1,.64,1.45.95c1,.6,2,1.21,3.08,1.77,2.08,1.16,4.23,2.25,6.43,3.28s4.42,2,6.65,3c1.12.5,2.23,1,3.34,1.58s2.22,1.1,3.31,1.76a40.85,40.85,0,0,1-7.42-1.08q-3.63-.9-7.17-2.15a65,65,0,0,1-7-2.89c-1.13-.56-2.26-1.16-3.36-1.84-.55-.34-1.09-.69-1.64-1.06a15.93,15.93,0,0,1-1.67-1.31Z" style="fill:#592d3d"/>'
            )
        );
    }

    /// @dev Render SVG for dress
    function renderDressBackSVG(bytes3 baseColor, bytes3 shadowColor, bool isWoman, uint8 color)
        private
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                '<path d="M568.44,849.8c-21.18,6.89-42,17.48-62.85,19.67-26.75,2.82-54.1-13.37-82.3-21.08-2.15-2.58-18.35-14.44-33.47-13.94-11.88.4-15.09,4.3-18.4,8.19l-4.16,213.48a13.27,13.27,0,0,0,13.27,13.27H619.47a13.27,13.27,0,0,0,13.27-13.27l-2.38-215.36c-4.43,0-7.1-9.4-20.41-5.09C593.66,841,569.71,848.28,568.44,849.8Z" style="fill:',
                BytesConverter.bytesToHex(baseColor),
                '"/>',
                '<polygon points="632.74 831.31 609.95 869.4 621.34 999.43 632.94 999.43 632.94 893.78 632.74 831.31" style="fill:',
                BytesConverter.bytesToHex(shadowColor),
                '"/>',
                '<path d="M380.53,1069.39H497.15c-109.2,0-100.91-231.14-129.89-231.14v217.87A13.27,13.27,0,0,0,380.53,1069.39Z" style="fill:',
                BytesConverter.bytesToHex(shadowColor),
                '"/>',
                '<path d="M361.26,860.4a63.71,63.71,0,0,1-.1-8.29q.19-4.15.71-8.31c.18-1.39.35-2.77.57-4.16s.44-2.77.78-4.16a27.84,27.84,0,0,1,3.44-8.35,27.54,27.54,0,0,1,3.73,8.22c.39,1.38.68,2.76.93,4.13s.5,2.76.72,4.14c.44,2.75.79,5.51,1,8.27a62,62,0,0,1,.21,8.29Z" style="fill:#592d3d"/>',
                '<path d="M632.74,869.4v8c.26,34,.26,69,0,102.76,0,2.87,0,5.72,0,8.53v67.41a13.27,13.27,0,0,1-13.27,13.27H380.53a13.27,13.27,0,0,1-13.27-13.27V998q0-3.76,0-7.65c-.25-34.86-.25-69.86,0-105.3V860.29" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                '<path d="M626.76,869.38a65.79,65.79,0,0,1,.65-8.53q.57-4.25,1.46-8.47c.3-1.41.6-2.82.94-4.22s.69-2.81,1.15-4.21a29.21,29.21,0,0,1,4.18-8.28,28.9,28.9,0,0,1,3,8.78c.26,1.45.42,2.89.55,4.33s.25,2.88.35,4.31c.18,2.87.28,5.74.25,8.59a67.65,67.65,0,0,1-.54,8.54Z" style="fill:#592d3d"/>',
                '<path d="M557.91,889.36c4.41-.78,8.76-1.39,13.1-2l13-1.93c4.31-.65,8.61-1.36,12.91-2.1s8.61-1.58,13.07-2.2a62.58,62.58,0,0,1-12.33,5.26,87,87,0,0,1-13,3,94.61,94.61,0,0,1-13.33,1.11A65.72,65.72,0,0,1,557.91,889.36Z" style="fill:#592d3d"/>',
                isWoman ? string(abi.encodePacked("<g>", BodyDetail.onlyBreastSVG(color), "</g>")) : ""
            )
        );
    }

    /// @dev Render Shirt SVG
    function renderShirtSVG(bytes3 baseColor, bytes3 shadowColor, bool isWoman, uint8 color)
        private
        pure
        returns (string memory)
    {
        return SVGBody.fullSVG(
            'id="shirt" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<polygon points="547.85 847.98 505.72 813.61 580.35 758.82 419.65 758.82 494.28 813.61 452.15 847.98 414.52 791.48 414.52 869.96 588.78 869.96 588.78 786.52 547.85 847.98" style="fill:none "/>',
                    '<path d="M616.66,758.16l-42.73.1a119.49,119.49,0,0,1-1.43,13.48,63.7,63.7,0,0,1-1.74,6.34c-2.34,6.49-17.26,12-21.49,16.73a48.22,48.22,0,0,1-4.5,4.43c-25.17,18.2-65.17,19.2-89.48-.58a51.36,51.36,0,0,1-7.11-7.61c-4.23-5.56-16.4-11.59-18.1-18.94a60,60,0,0,1-1.08-6.59,63.55,63.55,0,0,1-.36-6.8s-45.21-.56-45.21-.56a13.28,13.28,0,0,0-13.28,13.27v284.69a13.28,13.28,0,0,0,13.28,13.27H622.36a13.27,13.27,0,0,0,13.27-13.27V778C635.63,765.82,629.75,758.16,616.66,758.16Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M612.84,758.16c63.54,0,88.52,43.39,78.9,272-18.74,6.7-55.91,4.59-55.91,4.59Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<polygon points="451.06 855.4 499.51 831.31 548.09 855.4 511.03 812.38 467.14 813.21 451.06 855.4" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M635.63,831.31s-22.79,84.54-19.31,234l33.21-31,3.58-137.58C647.49,824.5,635.63,831.31,635.63,831.31Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M389,758.16c-61.78,0-88.88,56.45-80.75,245.48,22.42,9.91,56.19,5.58,56.19,5.58Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M306.94,957.49q.26,20.46,1.21,43.48c15.27.73,43.69.88,57.11,0l4.18-42.81C358.67,956.9,323.66,956.49,306.94,957.49Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M370.12,831.31l-.5,177.69-13.35.9C353.3,860.85,370.12,831.31,370.12,831.31Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M612.84,758.16c67.42,0,78.45,56.28,78.9,133.78v138.22s-50,5.53-55.91,4.59l-.1-142.11" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M389,758.16c-25.73,0-43.52,8.12-55.71,22.44-19.45,22.87-24.63,61.54-25,108.27v123.77c12.06,3.32,61.36-3.64,61.36-3.64l.49-118.6" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M372.6,1011.24c-1.83,2.61-73.77,1.92-74.67,0s-2.19-37.5,0-41c1.8-2.88,72.11-2.27,74.67,0S374.43,1008.63,372.6,1011.24Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    ';stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M383.43,1069.39H500c-109.19,0-100.91-231.14-129.89-231.14v217.87A13.28,13.28,0,0,0,383.43,1069.39Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M364.15,860.29c-.19-3.67-.11-7.35.06-11s.47-7.34.85-11c.2-1.83.41-3.67.65-5.51s.49-3.67.85-5.5a44.05,44.05,0,0,1,3.59-11,44.05,44.05,0,0,1,3.59,11c.36,1.83.62,3.67.85,5.5s.45,3.68.65,5.51q.58,5.52.86,11c.16,3.67.24,7.35,0,11Z" style="fill:#592d3d"/>',
                    '<path d="M635.63,869.4v8c.26,34,.26,69,0,102.76,0,2.87,0,5.72,0,8.53v67.41a13.27,13.27,0,0,1-13.27,13.27H383.43a13.28,13.28,0,0,1-13.28-13.27V990.3c-.26-34.86-.26-69.86,0-105.3V860.29" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M697.42,970.24c2.22,2.26,1.59,38.39,0,41s-64,1.92-64.77,0-1.9-37.5,0-41c.27-.5,2.28-.89,5.45-1.18" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    ';stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M678.92,968.3c3.8.3,15-1.18,15.42-.76" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M678.92,968.3a23.67,23.67,0,0,1,1.88-2.16,12.13,12.13,0,0,1,1.78-1.47,12.74,12.74,0,0,1,1.81-1c.61-.29,1.22-.54,1.83-.79a24.1,24.1,0,0,1,3.79-1.18,15.85,15.85,0,0,1,2-.31c.36,0,.73,0,1.17,0,.25,0,.46,0,.82,0,.12,0,.44,0,.71.07l.35,0,.49.11.25.06.2.06.57.21a6.45,6.45,0,0,1,2,1.37l4.2,4.29-8.65,8.48-4.12-4.37a5.73,5.73,0,0,0,1.91,1.32c.18.08.36.14.54.2l.17,0,.19.05a2.34,2.34,0,0,0,.38.09l.19,0h0c.1,0,.26,0,.22,0s-.07,0-.15,0l-.75,0c-.57,0-1.19,0-1.82,0a26.27,26.27,0,0,1-3.92-.53c-.67-.15-1.34-.3-2-.49a12.56,12.56,0,0,1-2-.72,10,10,0,0,1-2.08-1.32A8.19,8.19,0,0,1,678.92,968.3Z" style="fill:#592d3d"/>',
                    '<polygon points="592.51 763.64 517.84 818.45 559.98 852.83 619.4 763.59 592.51 763.64" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M629.63,869.4c-.19-4.18-.1-8.36.06-12.53s.47-8.36.86-12.53c.2-2.09.4-4.18.64-6.27s.49-4.18.86-6.27a54.83,54.83,0,0,1,3.58-12.53,54.37,54.37,0,0,1,3.59,12.53c.36,2.09.63,4.18.85,6.27s.45,4.18.65,6.27c.39,4.17.69,8.35.85,12.53s.26,8.35.06,12.53Z" style="fill:#592d3d"/>',
                    '<path d="M383.43,758.26l233.23-.1" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<polygon points="529.39 835.55 507.04 813.21 484.7 835.55 495.68 846.53 485.96 953.16 506.7 969.33 528.12 953.16 518.41 846.53 529.39 835.55" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<line x1="500.04" y1="813.21" x2="500.04" y2="1069.39" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:6px"/>',
                    '<polygon points="500.04 813.21 522.39 828.55 500.04 850.9 477.7 828.55 500.04 813.21" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M419.62,758.8s43.27,39.34,74.66,54.81C479,838.82,452.15,848,452.15,848l-59.43-89.23Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    ';stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M580.38,758.8S541,800,505.72,813.61c10,20.28,42.13,34.37,42.13,34.37l59.43-89.23Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    ';stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<polygon points="478.96 946.16 499.7 962.33 521.12 946.16 511.12 836.38 488.96 836.38 478.96 946.16" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<polyline points="477.7 828.55 488.68 839.53 478.96 946.16 499.7 962.33 521.12 946.16 511.41 839.53 522.39 828.55" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M638.1,969.06c7.51-.71,21.51-.89,34-.67" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M637.54,963.08a50.92,50.92,0,0,1,8.84-.47c2.9.07,5.78.3,8.66.65,1.43.18,2.87.37,4.3.61a43.36,43.36,0,0,1,4.29.85,27.53,27.53,0,0,1,8.5,3.67,30.13,30.13,0,0,1-8.52,3.5c-1.41.36-2.82.63-4.23.86s-2.81.47-4.21.69c-2.8.42-5.59.78-8.35,1s-5.52.5-8.16.54l-6,.1-1-11.13Z" style="fill:#592d3d"/>',
                    '<circle cx="515.77" cy="982.93" r="4.8" style="fill:#592d3d"/>',
                    '<path d="M490.89,836.19c-.05-.06,0,0,0,0l.07.05a.88.88,0,0,1,.17.12l.38.29c.25.21.52.42.78.65.53.45,1.09.93,1.7,1.39s1.27.9,2,1.42a27.37,27.37,0,0,1,2.71,2.33,5.61,5.61,0,0,1-3.13,2.43,9.41,9.41,0,0,1-3.7.27,11,11,0,0,1-3.63-1,9.72,9.72,0,0,1-1.65-1,8.85,8.85,0,0,1-.77-.63c-.12-.11-.25-.23-.37-.36l-.2-.21-.25-.29Z" style="fill:#592d3d"/>',
                    isWoman ? string(abi.encodePacked("<g>", BodyDetail.onlyBreastSVG(color), "</g>")) : ""
                )
            )
        );
    }

    /// @dev Render TShirt SVG
    function renderTShirtSVG(bytes3 baseColor, bytes3 shadowColor, bool isWoman, uint8 color)
        private
        pure
        returns (string memory)
    {
        return SVGBody.fullSVG(
            'id="t-shirt" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M677.8,906.35c.21-37.11-1.21-70.07-7.73-95.39C660,785.6,641.89,770.48,610,770.48L632.79,905S655.31,915.24,677.8,906.35Z" style="fill:none"/>',
                    '<path d="M686.41,895.79a20.31,20.31,0,0,1-3.7,2.43" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M326.11,809.88c-6.83,25.57-8,59.13-7.74,97,19.9,8.54,50.42-2.15,50.42-2.15l17.33-132.24C355.25,772.46,336.85,786.36,326.11,809.88Z" style="fill:none"/>',
                    '<path d="M613.76,758.72H559.55v.1a62.78,62.78,0,0,1-1.44,13.39,60.92,60.92,0,0,1-1.74,6.33,50.88,50.88,0,0,1-10,16.83,48.2,48.2,0,0,1-4.5,4.43c-25.17,18.2-65.17,19.2-89.48-.58a51.79,51.79,0,0,1-7.11-7.6,50.84,50.84,0,0,1-9.1-19.41,62.41,62.41,0,0,1-1.07-6.59,61,61,0,0,1-.37-6.8v-.1H380.53A13.28,13.28,0,0,0,367.26,772v284.68A13.28,13.28,0,0,0,380.53,1070H619.47a13.28,13.28,0,0,0,13.27-13.28V778.6C632.74,766.38,626.85,758.72,613.76,758.72Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M610,758.72c63.54,0,73.4,56,73.9,133.17-18.6,11.62-48.91,1.31-48.91,1.31Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M632.74,831.87,610,870l11.38,130h11.61V894.35l17.28,2.89C644.6,825.07,632.74,831.87,632.74,831.87Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M386.12,758.72c-61.78,0-75.83,53.8-76.85,127.66,19,19.86,58,4.58,58,4.58Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M367.23,831.87V891l-17.31,4.31C355.59,825.19,367.23,831.87,367.23,831.87Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M610,758.72c67.41,0,78.45,56.29,78.9,133.78-26.2,12.43-53.91.7-53.91.7" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M386.12,758.72c-66.79,0-80.08,54.7-80.76,130.72C326,904.22,367.22,891,367.22,891" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M380.53,1070H497.15C388,1070,396.24,838.82,367.26,838.82v217.86A13.28,13.28,0,0,0,380.53,1070Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M361.26,860.85c-.19-3.67-.11-7.34.05-11s.47-7.35.86-11c.2-1.84.4-3.67.65-5.51s.49-3.67.85-5.51a44.18,44.18,0,0,1,3.59-11,43.74,43.74,0,0,1,3.58,11c.37,1.84.63,3.67.86,5.51s.45,3.67.65,5.51c.38,3.67.68,7.34.85,11s.25,7.34.06,11Z" style="fill:#592d3d"/>',
                    '<path d="M632.74,870v8c.26,34,.26,69,0,102.75,0,2.87,0,5.72,0,8.53v67.41A13.28,13.28,0,0,1,619.47,1070H380.53a13.28,13.28,0,0,1-13.27-13.28V998.52c0-2.51,0-5.07,0-7.65-.25-34.87-.25-69.87,0-105.3V860.85" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M626.74,870c-.19-4.17-.1-8.35.06-12.53s.47-8.35.85-12.53c.2-2.09.41-4.18.65-6.27s.49-4.17.86-6.26a54.55,54.55,0,0,1,3.58-12.53,55.09,55.09,0,0,1,3.59,12.53c.36,2.09.62,4.18.85,6.26s.45,4.18.65,6.27c.38,4.18.69,8.35.85,12.53s.25,8.36.06,12.53Z" style="fill:#592d3d"/>',
                    '<path d="M380.53,758.82l233.23-.1" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M559.55,758.82a62.78,62.78,0,0,1-1.44,13.39,60.92,60.92,0,0,1-1.74,6.33,50.88,50.88,0,0,1-10,16.83,48.2,48.2,0,0,1-4.5,4.43c-25.17,18.2-65.17,19.2-89.48-.58a51.79,51.79,0,0,1-7.11-7.6,50.84,50.84,0,0,1-9.1-19.41,62.41,62.41,0,0,1-1.07-6.59,61,61,0,0,1-.37-6.8" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M503.4,828.39a66.61,66.61,0,0,1-18.39,1.1,69.79,69.79,0,0,1-18.2-3.76,61.46,61.46,0,0,1-16.5-8.64l-1.86-1.41c-.61-.48-1.2-1-1.79-1.52a32.24,32.24,0,0,1-3.33-3.28,43.83,43.83,0,0,1-5.38-7.51,87.37,87.37,0,0,0,6.74,6.09c.58.48,1.17.95,1.75,1.4s1.23.82,1.84,1.24,1.22.84,1.85,1.23l1.91,1.16a88.05,88.05,0,0,0,16.1,7.46,106.26,106.26,0,0,0,17.25,4.45A173.7,173.7,0,0,0,503.4,828.39Z" style="fill:#592d3d"/>',
                    '<path d="M307.83,892.5a24.54,24.54,0,0,0,3.68,2.77" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M674.7,882.69a19.88,19.88,0,0,1-6.76,2.52,34.83,34.83,0,0,1-7.2.65,40.16,40.16,0,0,1-7.18-.79c-1.18-.21-2.33-.56-3.49-.87s-2.27-.77-3.37-1.24c1.21,0,2.38.18,3.56.28l3.52.29c1.17,0,2.33.2,3.5.21s2.32.11,3.48.12q3.5.06,7-.19A49.31,49.31,0,0,0,674.7,882.69Z" style="fill:#592d3d"/>',
                    isWoman ? string(abi.encodePacked("<g>", BodyDetail.onlyBreastSVG(color), "</g>")) : ""
                )
            )
        );
    }

    /// @dev Render TankTop SVG
    function renderTankTopSVG(bytes3 baseColor, bytes3 shadowColor, bool isWoman, uint8 color)
        private
        pure
        returns (string memory)
    {
        return SVGBody.fullSVG(
            'id="tank-top" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M613.76,758.16H559.55v.1H589a175.21,175.21,0,0,1-2.12,27.22q-1,6.57-2.57,12.88a116.51,116.51,0,0,1-14.71,34.22,92,92,0,0,1-6.61,9c-37.06,37-95.95,39-131.74-1.19A98.26,98.26,0,0,1,420.8,825a124.07,124.07,0,0,1-13.4-39.48q-1-6.57-1.58-13.39c-.35-4.54-.54-9.15-.54-13.82h29.47v-.1H380.53c.82,22.29-1.59,75.64-9.11,84.48l-4.16,213.48a13.27,13.27,0,0,0,13.27,13.27H619.47a13.27,13.27,0,0,0,13.27-13.27l-2.38-215.36C620.61,840.76,613.42,783.07,613.76,758.16Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<polygon points="632.74 831.31 609.95 869.4 621.34 999.43 632.94 999.43 632.94 893.78 632.74 831.31" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M380.53,1069.39H497.15c-109.2,0-100.91-231.14-129.89-231.14v217.87A13.27,13.27,0,0,0,380.53,1069.39Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M361.26,860.4a63.71,63.71,0,0,1-.1-8.29q.19-4.15.71-8.31c.18-1.39.35-2.77.57-4.16s.44-2.77.78-4.16a27.84,27.84,0,0,1,3.44-8.35,27.54,27.54,0,0,1,3.73,8.22c.39,1.38.68,2.76.93,4.13s.5,2.76.72,4.14c.44,2.75.79,5.51,1,8.27a62,62,0,0,1,.21,8.29Z" style="fill:#592d3d"/>',
                    '<path d="M632.74,869.4v8c.26,34,.26,69,0,102.76,0,2.87,0,5.72,0,8.53v67.41a13.27,13.27,0,0,1-13.27,13.27H380.53a13.27,13.27,0,0,1-13.27-13.27V998q0-3.76,0-7.65c-.25-34.86-.25-69.86,0-105.3V860.29" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M626.76,869.38a65.79,65.79,0,0,1,.65-8.53q.57-4.25,1.46-8.47c.3-1.41.6-2.82.94-4.22s.69-2.81,1.15-4.21a29.21,29.21,0,0,1,4.18-8.28,28.9,28.9,0,0,1,3,8.78c.26,1.45.42,2.89.55,4.33s.25,2.88.35,4.31c.18,2.87.28,5.74.25,8.59a67.65,67.65,0,0,1-.54,8.54Z" style="fill:#592d3d"/>',
                    '<path d="M368.1,833c21.58-5.27,12.43-74.73,12.43-74.73l233.23-.1s3.93,76.62,19.18,82.92" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M589,758.26a175.22,175.22,0,0,1-2.11,27.22q-1,6.57-2.57,12.88a116.51,116.51,0,0,1-14.71,34.22,92,92,0,0,1-6.61,9c-37.06,37-95.95,39-131.74-1.19A98.26,98.26,0,0,1,420.8,825a124.07,124.07,0,0,1-13.4-39.48q-1-6.57-1.58-13.39c-.35-4.54-.54-9.15-.54-13.82" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    isWoman ? string(abi.encodePacked("<g>", BodyDetail.onlyBreastSVG(color), "</g>")) : ""
                )
            )
        );
    }

    /// @dev Render VNeck SVG
    function renderVNeckSVG(bytes3 baseColor, bytes3 shadowColor, bool isWoman, uint8 color)
        private
        pure
        returns (string memory)
    {
        return SVGBody.fullSVG(
            'id="v-neck" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M680.7,905.78c.2-37.1-1.21-70.07-7.74-95.39-10.08-25.35-28.18-40.47-60.12-40.47l22.85,134.47S658.2,914.68,680.7,905.78Z" style="fill:none"/>',
                    '<path d="M689.3,895.23a20.28,20.28,0,0,1-3.69,2.42" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M329,809.32c-6.82,25.57-8,59.13-7.74,97,19.9,8.55,50.43-2.15,50.43-2.15L389,771.89C358.14,771.89,339.74,785.79,329,809.32Z" style="fill:none"/>',
                    '<path d="M616.66,758.16l-38.44.1c0,53.72-75.33,111.14-75.33,111.14s-80.8-60.58-80.8-111.14l-38.66-.1a13.28,13.28,0,0,0-13.28,13.27v284.69a13.28,13.28,0,0,0,13.28,13.27H622.36a13.27,13.27,0,0,0,13.27-13.27V778C635.63,765.82,629.75,758.16,616.66,758.16Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M612.84,758.16c63.54,0,73.4,56,73.9,133.16-18.59,11.62-48.91,1.32-48.91,1.32Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M635.63,831.31,612.84,869.4l11.39,130h11.6V893.78l17.28,2.89C647.49,824.5,635.63,831.31,635.63,831.31Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M389,758.16c-61.78,0-75.82,53.79-76.85,127.66,19,19.85,57.95,4.58,57.95,4.58Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M370.12,831.31V890.4l-17.31,4.3C358.48,824.63,370.12,831.31,370.12,831.31Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M612.84,758.16c67.42,0,78.45,56.28,78.9,133.78-26.2,12.42-53.91.7-53.91.7" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M389,758.16c-66.79,0-80.08,54.69-80.75,130.71,20.59,14.79,61.85,1.53,61.85,1.53" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M383.43,1069.39H500c-109.19,0-100.91-231.14-129.89-231.14v217.87A13.28,13.28,0,0,0,383.43,1069.39Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M364.15,860.29c-.19-3.67-.11-7.35.06-11s.47-7.34.85-11c.2-1.83.41-3.67.65-5.51s.49-3.67.85-5.5a44.05,44.05,0,0,1,3.59-11,44.05,44.05,0,0,1,3.59,11c.36,1.83.62,3.67.85,5.5s.45,3.68.65,5.51q.58,5.52.86,11c.16,3.67.24,7.35,0,11Z" style="fill:#592d3d"/>',
                    '<path d="M635.63,869.4v8c.26,34,.26,69,0,102.76,0,2.87,0,5.72,0,8.53v67.41a13.27,13.27,0,0,1-13.27,13.27H383.43a13.28,13.28,0,0,1-13.28-13.27V990.3c-.26-34.86-.26-69.86,0-105.3V860.29" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M629.63,869.4c-.19-4.18-.1-8.36.06-12.53s.47-8.36.86-12.53c.2-2.09.4-4.18.64-6.27s.49-4.18.86-6.27a54.83,54.83,0,0,1,3.58-12.53,54.37,54.37,0,0,1,3.59,12.53c.36,2.09.63,4.18.85,6.27s.45,4.18.65,6.27c.39,4.17.69,8.35.85,12.53s.26,8.35.06,12.53Z" style="fill:#592d3d"/>',
                    '<path d="M383.43,758.26l233.23-.1" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M310.72,891.94a24.84,24.84,0,0,0,3.68,2.76" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M677.59,882.13a20.25,20.25,0,0,1-6.75,2.52,34.91,34.91,0,0,1-7.21.64,39.94,39.94,0,0,1-7.17-.78c-1.18-.22-2.34-.57-3.49-.87s-2.28-.78-3.38-1.24c1.21,0,2.39.17,3.56.27l3.52.29c1.17,0,2.33.2,3.5.21s2.33.11,3.49.12c2.32.05,4.64,0,7-.18A50.81,50.81,0,0,0,677.59,882.13Z" style="fill:#592d3d"/>',
                    '<path d="M578.22,758.26c0,53.72-75.33,111.14-75.33,111.14s-80.8-60.58-80.8-111.14" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    isWoman ? string(abi.encodePacked("<g>", BodyDetail.onlyBreastSVG(color), "</g>")) : ""
                )
            )
        );
    }

    /// @dev Helper functoins to return colors
    function _getColors(uint8 color) private pure returns (bytes3, bytes3) {
        if (color == 0) return (Colors.WHITE_BASE, Colors.WHITE_SHADOW);
        if (color == 1) return (Colors.BLUE_BASE, Colors.BLUE_SHADOW);
        if (color == 2) return (Colors.BLACK_BASE, Colors.BLACK_SHADOW);
        if (color == 3) return (Colors.GREEN_BASE, Colors.GREEN_SHADOW);
        if (color == 4) return (Colors.RED_BASE, Colors.RED_SHADOW);
        revert Errors.InvalidColor(color);
    }
}
