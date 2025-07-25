// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {SVGBody} from "./SVGBody.sol";
import {Colors} from "src/types/Constants.sol";
import {BytesConverter} from "src/libraries/BytesConverter.sol";

library HatsDetail {
    error HatsDetail__InvalidColor(uint8 id);
    error HatsDetail__InvalidType(uint8 id);

    using Colors for bytes3;
    using BytesConverter for bytes3;

    enum HatColor {
        WHITE,
        BLUE,
        BLACK,
        GREEN,
        RED
    }

    enum HatType {
        NONE,
        BEANIE,
        TURBAN
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Retrieves the base and shadow color for a hat
    /// @param id The hat color id
    function getColorForHat(uint8 id) internal pure returns (bytes3 baseColor, bytes3 shadowColor) {
        return _getColors(HatColor(id));
    }

    function _getColors(HatColor color) private pure returns (bytes3, bytes3) {
        if (color == HatColor.WHITE) return (Colors.WHITE_BASE, Colors.WHITE_SHADOW);
        if (color == HatColor.BLUE) return (Colors.BLUE_BASE, Colors.BLUE_SHADOW);
        if (color == HatColor.BLACK) return (Colors.BLACK_BASE, Colors.BLACK_SHADOW);
        if (color == HatColor.GREEN) return (Colors.GREEN_BASE, Colors.GREEN_SHADOW);
        if (color == HatColor.RED) return (Colors.RED_BASE, Colors.RED_SHADOW);
        revert HatsDetail__InvalidColor(uint8(color));
    }

    /// @dev SVG content for a beanie hat
    function beanieHatSVG(uint8 id) internal pure returns (string memory) {
        (bytes3 baseColor, bytes3 shadowColor) = getColorForHat(id);
        return renderBeanieHatSVG(baseColor, shadowColor);
    }

    /// @dev SVG content for a turban hat
    function turbanHatSVG(uint8 id) internal pure returns (string memory) {
        (bytes3 baseColor, bytes3 shadowColor) = getColorForHat(id);
        return renderTurbanHatSVG(baseColor, shadowColor);
    }

    /// @dev Returns the SVG content for a hat
    function getHatsById(uint8 id, uint8 color, uint8 hairStyle)
        internal
        pure
        returns (string memory svg, string memory name)
    {
        if (!isAllowedHats(id, hairStyle)) return ("", "");

        string[3] memory hats = ["", beanieHatSVG(color), turbanHatSVG(color)];
        if (id >= hats.length) revert HatsDetail__InvalidType(id);

        svg = hats[id];
        string memory hatName = getHatsName(id);
        string memory hatColorName = getHatsColorName(color);

        name = string(abi.encodePacked(hatColorName, " ", hatName));
        return (svg, name);
    }

    function getHatsName(uint8 id) internal pure returns (string memory) {
        string[3] memory hatNames = ["None", "Beanie", "Turban"];
        if (id >= hatNames.length) revert HatsDetail__InvalidType(id);
        return hatNames[id];
    }

    function getHatsColorName(uint8 id) internal pure returns (string memory) {
        HatColor color = HatColor(id);
        string[5] memory hatColorNames = ["White", "Blue", "Black", "Green", "Red"];

        if (id >= hatColorNames.length) revert HatsDetail__InvalidColor(uint8(id));
        return hatColorNames[uint8(color)];
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function renderBeanieHatSVG(bytes3 baseColor, bytes3 shadowColor) private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="beanie" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<circle cx="491.44" cy="157.14" r="47.48" style="fill:#fff"/>',
                    '<path d="M491.44,204.62a47.47,47.47,0,0,0,46.46-57.31c-30.78-4.77-62.7-2-93.77,6-.1,1.26-.17,2.53-.17,3.82A47.48,47.48,0,0,0,491.44,204.62Z" style="fill:#e2e2e2"/>',
                    '<circle cx="491.44" cy="157.14" r="47.48" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M240.26,423.13a254.67,254.67,0,0,1,6.54-57.5q1.29-5.55,2.81-11c2.9-32.3,20-58.94,42.86-82.73,4.76-3.81,5.71-12.37,10.47-17.13,16.18-14.27,30.45-28.55,48.53-40,74.22-47.58,172.23-73.27,251.21-29.5,16.17,8.56,34.25,13.32,47.57,24.74,25.7,21.88,43.77,47.58,69.47,68.51,22.83,19,26.64,49.48,34.74,76.07q1.53,5.44,2.81,11a254.67,254.67,0,0,1,6.54,57.5Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M246.8,365.63a254.67,254.67,0,0,0-6.54,57.5h83C321.7,342.47,301,275.11,406,193,330.68,221.59,262.05,284.38,246.8,365.63Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M258.18,321.12a109.41,109.41,0,0,0-8.57,33.51q-1.52,5.44-2.81,11a254.67,254.67,0,0,0-6.54,57.5H440.31a827.17,827.17,0,0,1,127.59,0H763.81a254.67,254.67,0,0,0-6.54-57.5q-1.29-5.55-2.81-11c-3.46-11.37-6.15-23.44-9.86-35C582.71,259.73,419,261,258.18,321.12Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M240.26,423.13a254.67,254.67,0,0,1,6.54-57.5q1.29-5.55,2.81-11c2.9-32.3,20-58.94,42.86-82.73,4.76-3.81,5.71-12.37,10.47-17.13,16.18-14.27,30.45-28.55,48.53-40,74.22-47.58,172.23-73.27,251.21-29.5,16.17,8.56,34.25,13.32,47.57,24.74,25.7,21.88,43.77,47.58,69.47,68.51,22.83,19,26.64,49.48,34.74,76.07q1.53,5.44,2.81,11a254.67,254.67,0,0,1,6.54,57.5Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12.856184465220856px"/>',
                    '<path d="M225.35,356.43c183.42-78,371.14-79.06,555.94,0,17.53,7.5,17.43,139.87,0,133.81-180.47-62.83-371.33-63.5-555.94,0C203.39,497.79,205.53,364.86,225.35,356.43Z" style="fill:#fff"/>',
                    '<path d="M751.33,443.71a43.58,43.58,0,0,1,1.35,9.9c.09,3.27-.11,6.52-.26,9.78l-.36,4.87c-.16,1.62-.32,3.24-.52,4.85-.4,3.23-.89,6.44-1.59,9.61l-7.87-1.41c.44-3.17,1-6.31,1.64-9.45l1-4.71,1-4.7c.74-3.13,1.37-6.27,2.22-9.4A53.94,53.94,0,0,1,751.33,443.71Z" style="fill:#592d3d"/>',
                    '<path d="M749.91,342.47a175.32,175.32,0,0,1,3.63,19c.43,3.19.78,6.39,1.09,9.59s.49,6.42.66,9.63c.26,6.42.37,12.84.06,19.25a114.35,114.35,0,0,1-2.45,19.11c-1-6.39-1.67-12.7-2.32-19s-1.21-12.55-2.05-18.78c-.39-3.12-.83-6.22-1.3-9.32s-1-6.19-1.52-9.27c-1.07-6.17-2.3-12.29-3.59-18.41Z" style="fill:#592d3d"/>',
                    '<path d="M668.78,322c7.56,42.87,6.71,89.49,0,138.73" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M598.19,307.61c5.15,42.9,4.57,89.55,0,138.83" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M533.85,356.47a172.75,172.75,0,0,1,2.37,20.68c.4,6.9.52,13.8.65,20.71l0,10.36c0,3.45,0,6.9-.12,10.35-.15,6.9-.4,13.8-.87,20.69l-8-.4c.22-6.87.57-13.73.94-20.59l1.21-20.57c.46-6.86.82-13.73,1.35-20.6S532.69,363.36,533.85,356.47Z" style="fill:#592d3d"/>',
                    '<path d="M535.93,299.88a58.54,58.54,0,0,1,.28,6.35c0,1.06-.05,2.12-.08,3.18L536,312.6c-.17,2.12-.32,4.25-.68,6.38a22.42,22.42,0,0,1-2.08,6.41,23.29,23.29,0,0,1-2.7-6.21c-.57-2.08-.93-4.16-1.31-6.25l-.49-3.12c-.13-1.05-.28-2.09-.39-3.13a55,55,0,0,1-.35-6.29Z" style="fill:#592d3d"/>',
                    '<path d="M467.76,299.65c.35,43,.31,89.67,0,139" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M403.38,306.18c-2.06,43-1.83,89.73,0,139.11" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M333.37,391.65a161.31,161.31,0,0,1,2.71,16.78c.63,5.59,1.09,11.17,1.65,16.75l1.51,16.73c.47,5.57.93,11.15,1.25,16.74l-8,.64c-.58-5.61-.93-11.24-1.18-16.87-.13-2.82-.2-5.64-.28-8.46l-.1-8.46c0-5.64.05-11.29.35-16.93A117.52,117.52,0,0,1,333.37,391.65Z" style="fill:#592d3d"/>',
                    '<path d="M340.48,320.18c-.25,3.65-.64,7.28-1.05,10.91l-.66,5.45-.72,5.45c-.54,3.64-.95,7.28-1.6,10.93a67.39,67.39,0,0,1-2.8,10.92,55.71,55.71,0,0,1-2-11.14c-.3-3.72-.32-7.42-.38-11.14l0-5.56c.06-1.86.11-3.71.2-5.56.2-3.71.49-7.41,1-11.09Z" style="fill:#592d3d"/>',
                    '<path d="M264.86,340.45c-6.86,43-6.09,89.85,0,139.3" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M753.07,434.58a3.75,3.75,0,1,0-3.75-3.75,3.8,3.8,0,0,0,3.75,3.75Z" style="fill:#592d3d"/>',
                    '<path d="M758.28,341.38c10,42.84,8.85,89.43,0,138.64" style="fill:none;stroke:#e2e2e2;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M681,320c7.56,42.87,6.71,89.49,0,138.74" style="fill:none;stroke:#e2e2e2;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M610.38,305.45c5.15,42.9,4.57,89.55,0,138.83" style="fill:none;stroke:#e2e2e2;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M544.06,297.82c2.74,42.92,2.44,89.61,0,138.92" style="fill:none;stroke:#e2e2e2;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M479.8,297.16c.34,42.95.31,89.67,0,139" style="fill:none;stroke:#e2e2e2;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M415.34,303.53c-2.06,43-1.83,89.73,0,139.11" style="fill:none;stroke:#e2e2e2;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M348.41,317c-4.46,43-4,89.79,0,139.21" style="fill:none;stroke:#e2e2e2;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M276.74,337.64c-6.86,43-6.09,89.85,0,139.3" style="fill:none;stroke:#e2e2e2;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M225.35,356.43c183.42-78,371.14-79.06,555.94,0,17.53,7.5,17.43,139.87,0,133.81-180.47-62.83-371.33-63.5-555.94,0C203.39,497.79,205.53,364.86,225.35,356.43Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:11.793553752904756px"/>',
                    '<path d="M426.76,283.72A328.8,328.8,0,0,1,465.37,278c3.25-.28,6.49-.56,9.74-.78l9.75-.56c3.26-.14,6.51-.2,9.77-.3l9.77-.13c13,0,26.05.63,39,1.84a324.4,324.4,0,0,1,38.6,5.8c-13-.29-26-.79-38.88-1.13s-25.84-.49-38.75-.52h-9.68c-3.23,0-6.46.12-9.69.11l-9.68.14c-3.23.11-6.46.16-9.7.2C452.72,283,439.78,283.46,426.76,283.72Z" style="fill:#592d3d"/>',
                    '<path d="M347.31,233.83a183.71,183.71,0,0,1,22.38-15.33c7.78-4.62,15.81-8.84,24-12.66,2-1,4.13-1.86,6.2-2.78s4.13-1.86,6.24-2.67c4.22-1.65,8.4-3.38,12.7-4.8a217,217,0,0,1,26.06-7.5c-2.07.91-4.16,1.78-6.25,2.63s-4.19,1.64-6.25,2.56c-4.15,1.74-8.31,3.42-12.43,5.22l-3.09,1.33c-1,.43-2.08.85-3.1,1.32l-6.15,2.73c-2.06.88-4.09,1.83-6.14,2.75s-4.09,1.84-6.1,2.83l-6.1,2.83c-2,1-4,2-6.05,3-4,1.94-8,4-12.05,6C363.19,225.31,355.23,229.48,347.31,233.83Z" style="fill:#fff"/>'
                )
            )
        );
    }

    function renderTurbanHatSVG(bytes3 baseColor, bytes3 shadowColor) private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="turban" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M765.63,495.43s.3-2.94.8-8.24C759.75,345.82,643,233.25,500,233.25c-147.32,0-266.75,119.43-266.75,266.75,0,7.28.31,14.49.89,21.63,12.11-39.32,161.32-77.95,298.44-133.08C631.75,452.24,765.63,495.43,765.63,495.43Z" style="opacity:.15"/>',
                    '<path d="M747.94,163.66l0,0C684.65,74.76,266,93.83,204.16,155.69c-66.94,66.94,29.18,351,29.18,351,0-41.1,160.33-82.31,303.37-139.83,99.17,63.69,228.92,108.54,228.92,108.54S793.59,209.32,747.94,163.66Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    '"/>',
                    '<path d="M610.06,159.09c-36.6-4-184.31-1.44-322.45,25.65A481,481,0,0,0,235,197.59c-4.25,1.37-8.49,2.76-12.62,4.33s-8.24,3.18-12.18,5a112.44,112.44,0,0,0-11.34,5.93c-3.54,2.16-10.85,8.81-13.51,11.39l-7.3-15.56a69.81,69.81,0,0,1,12.33-9.59,116.58,116.58,0,0,1,13-6.93,217.66,217.66,0,0,1,26.74-10.11,460.64,460.64,0,0,1,54.55-12.9c18.3-3.27,36.69-5.71,55.1-7.7s35.8-7.94,54.26-8.88C494.59,148.61,592.19,154.62,610.06,159.09Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M188.17,320.14c3.47-1.42,6.8-2.75,10.2-4.07s6.78-2.61,10.18-3.87c6.79-2.57,13.62-5,20.45-7.36q20.52-7.09,41.26-13.47c6.91-2.14,13.82-4.25,20.78-6.22l10.42-3c3.47-1,6.94-2,10.44-2.93l20.94-5.59,21-5.25C382,261.7,484.59,232.18,513.37,230c-7,1.8-168.2,54.82-176.74,57.39L316,293.56q-20.57,6.22-41,12.91c-6.83,2.16-13.6,4.47-20.38,6.76s-13.54,4.65-20.3,7l-10.1,3.61q-5.07,1.77-10.08,3.64l-10,3.71c-3.32,1.23-6.69,2.52-9.9,3.78Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M711.7,270.48c-39.92,36.15-102.55,67-169.48,94.19l16.51,15.78h0S659.21,340.49,711.7,270.48Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M214.45,457.18a24.45,24.45,0,0,1,.66-5.43,27,27,0,0,1,1.75-4.9,36.8,36.8,0,0,1,5.26-8,72.69,72.69,0,0,1,13-11.7,206,206,0,0,1,28.63-16.72c19.57-9.69,39.67-17.6,59.8-25.27s40.4-14.82,60.64-22S424.76,349,445,341.87c40.42-14.25,79.8-31.3,119.21-47.95,9.86-4.14,93.82-54.66,102.72-60.67-8.32,6.8-67.53,50.51-99.82,67.22-39.1,18-78.43,35.84-118.64,50.95-20.13,7.5-40.29,14.87-60.43,22.25s-40.27,14.71-60.19,22.46c-10,3.88-19.86,7.85-29.66,12s-19.51,8.46-28.95,13.15A195.93,195.93,0,0,0,242.3,437a64.46,64.46,0,0,0-10.93,9.68c-3,3.49-7.94,11.25-7.92,14.53Z" style="fill:',
                    BytesConverter.bytesToHex(shadowColor),
                    '"/>',
                    '<path d="M747.94,163.66l0,0C684.65,74.76,266,93.83,204.16,155.69c-66.94,66.94,29.18,351,29.18,351,0-41.1,160.33-82.31,303.37-139.83,99.17,63.69,228.92,108.54,228.92,108.54S793.59,209.32,747.94,163.66Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M534.47,361.33c16.1-6.69,32.19-13.37,48.12-20.36l6-2.61,5.95-2.67,6-2.66,5.91-2.76,5.92-2.73c2-.91,3.92-1.88,5.88-2.81,3.91-1.89,7.83-3.75,11.69-5.74q23.34-11.6,45.56-25.15a427.09,427.09,0,0,0,43-29.7c-1.44,1.66-2.86,3.34-4.34,5s-2.9,3.33-4.49,4.84c-3.12,3.11-6.22,6.29-9.55,9.17-1.64,1.49-3.31,2.92-5,4.39s-3.41,2.8-5.12,4.21-3.45,2.76-5.2,4.11l-5.32,4A448.92,448.92,0,0,1,634.62,328c-3.84,2.18-7.74,4.23-11.63,6.29s-7.8,4.1-11.74,6.08l-5.9,3-6,2.87c-4,1.91-7.92,3.84-11.93,5.64q-24,11.06-48.52,20.65Z" style="fill:#592d3d"/>',
                    '<path d="M769.08,431.09c-1.42-.23-2.71-.46-4-.72s-2.63-.53-3.94-.82c-2.62-.55-5.2-1.21-7.79-1.86q-7.74-2-15.34-4.43a315.52,315.52,0,0,1-29.83-11.2A306.66,306.66,0,0,1,679.61,398a208.59,208.59,0,0,1-26.43-17.56c2.42,1.09,4.82,2.19,7.19,3.35s4.7,2.34,7.12,3.39c4.77,2.18,9.47,4.49,14.28,6.55q14.25,6.56,28.91,12l7.33,2.71L725.4,411c4.94,1.65,9.9,3.22,14.89,4.67s10,2.83,15,4.13l3.77.91c1.26.32,2.52.62,3.78.89,2.5.57,5.08,1.14,7.49,1.59Z" style="fill:#592d3d"/>',
                    '<path d="M615.36,160c-36.49-4.61-73.12-6.62-109.74-7.18s-73.25.43-109.73,3.15c-18.24,1.33-36.45,3.08-54.58,5.35s-36.18,5-54.06,8.36a484.87,484.87,0,0,0-52.83,12.84,211.12,211.12,0,0,0-25,9.44A113.77,113.77,0,0,0,197.84,198a56.05,56.05,0,0,0-9.85,7.45L179.5,197a67.76,67.76,0,0,1,12-9.28,115.9,115.9,0,0,1,12.81-6.8,226.14,226.14,0,0,1,26.49-10A457.87,457.87,0,0,1,285.08,158c36.5-6.53,73.31-10.19,110.17-12.17a1068.52,1068.52,0,0,1,110.62-.17c9.2.53,18.4,1.16,27.59,1.94s18.35,1.78,27.49,2.93A542.75,542.75,0,0,1,615.36,160Z" style="fill:#592d3d"/>',
                    '<path d="M210.05,449.36a24.5,24.5,0,0,1,.64-5.37,26.93,26.93,0,0,1,1.71-4.87,36.36,36.36,0,0,1,5.18-8,71.43,71.43,0,0,1,12.89-11.68,202.41,202.41,0,0,1,28.39-16.69c19.41-9.65,39.35-17.52,59.32-25.14s40.08-14.74,60.17-21.86,40.21-14,60.25-21.15c40.11-14.17,80-28.92,119.07-45.49q14.67-6.18,29.14-12.83t28.69-13.79q14.22-7.17,28-15.08t27.08-16.87c-8.25,6.75-16.94,13-25.81,18.91s-18,11.55-27.24,16.89S598.9,276.71,589.4,281.6s-19.15,9.51-28.82,14c-38.79,18-78.6,33.46-118.5,48.49-20,7.46-40,14.78-59.95,22.12s-39.95,14.62-59.72,22.33c-9.87,3.85-19.7,7.81-29.41,11.95s-19.35,8.41-28.71,13.08a191.39,191.39,0,0,0-26.63,15.63,63.16,63.16,0,0,0-10.78,9.64c-3,3.47-4.85,7.2-4.83,10.48Z" style="fill:#592d3d"/>',
                    '<path d="M184.48,311.25C198,305.7,211.57,300.86,225.22,296s27.38-9.26,41.18-13.53c27.6-8.52,55.41-16.36,83.45-23.23S406,246,434.45,240.93L445.09,239l5.33-1,5.34-.85L477.15,234c7.13-1.1,14.3-1.92,21.46-2.74s14.33-1.6,21.5-2.31q-10.54,2.44-21.09,4.73c-7,1.55-14.09,2.94-21.08,4.63-14,3.22-28.07,6.22-42,9.66q-42,9.66-83.48,21.17l-20.73,5.79L311.07,281c-13.74,4.12-27.44,8.36-41.07,12.81-6.84,2.15-13.63,4.46-20.42,6.74s-13.57,4.62-20.35,6.94c-13.48,4.75-27,9.69-40.19,14.83Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    /// @dev Check if the hats is allowed only to a specific type of hair
    function isAllowedHats(uint8 hatStyle, uint8 hairs) private pure returns (bool) {
        if (hatStyle == 1) {
            if (hairs == 1 || hairs == 4) return false;
            return true;
        }

        if (hatStyle == 2) {
            if (hairs == 1 || hairs == 3 || hairs == 4 || hairs == 5) return false;
            return true;
        }

        return false;
    }
}
