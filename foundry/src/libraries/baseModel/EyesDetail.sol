// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {SVGBody} from "./SVGBody.sol";
import {BodyDetail} from "./BodyDetail.sol";
import {BytesConverter} from "../BytesConverter.sol";
import {Errors} from "src/types/Constants.sol";

library EyesDetail {
    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev SVG content for the Content Eyes
    function contentEyeSVG() internal pure returns (string memory) {
        return renderContentEyeSVG();
    }

    /// @dev SVG content for the Dizzy Eyes
    function dizzyEyeSVG() internal pure returns (string memory) {
        return renderDizzyEyeSVG();
    }

    /// @dev SVG content for the Happy Eyes
    function happyEyeSVG() internal pure returns (string memory) {
        return renderHappyEyeSVG();
    }

    /// @dev SVG content for the Heart Eyes
    function heartEyeSVG() internal pure returns (string memory) {
        return renderHeartEyeSVG();
    }

    /// @dev SVG content for the Left Twitch Eye
    function leftTwitchEyeSVG(uint8 color) internal pure returns (string memory) {
        (bytes3 baseColor,) = BodyDetail.getColorsForBody(color);
        return renderLeftTwitchEyeSVG(baseColor);
    }

    /// @dev SVG content for the Normal Eyes
    function normalEyeSVG() internal pure returns (string memory) {
        return renderNormalEyeSVG();
    }

    /// @dev SVG content for the Simple Eyes
    function simpleEyeSVG() internal pure returns (string memory) {
        return renderSimpleEyeSVG();
    }

    /// @dev SVG content for the Squint Eyes
    function squintEyeSVG() internal pure returns (string memory) {
        return renderSquintEyeSVG();
    }

    /// @dev SVG content for the Left Twitch Eye
    function winkEyeSVG() internal pure returns (string memory) {
        return renderWinkEyeSVG();
    }

    /// @dev Returns the SVG and name for the given eye type
    function getEyeById(uint8 id, uint8 color) internal pure returns (string memory) {
        if (id == 0) return "";
        if (id == 1) return contentEyeSVG();
        if (id == 2) return dizzyEyeSVG();
        if (id == 3) return happyEyeSVG();
        if (id == 4) return heartEyeSVG();
        if (id == 5) return leftTwitchEyeSVG(color);
        if (id == 6) return normalEyeSVG();
        if (id == 7) return simpleEyeSVG();
        if (id == 8) return squintEyeSVG();
        if (id == 9) return winkEyeSVG();

        revert Errors.InvalidType(id);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function renderContentEyeSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="content-eyes" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M703.51,506.11V519a49.59,49.59,0,0,1-1.94,25.32,45.67,45.67,0,0,1-3.51,7.65c-3.35,8.71-12.35,15.71-21.35,18.71-14,4-31,2-42-9-14-15-12-37-12.45-55.62" style="fill:none;stroke:#592d3d;stroke-linecap:round;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M376.69,505.7c2.34,26.61-1.66,63.61-36.13,67.17a45.89,45.89,0,0,1-8.12,0A43.6,43.6,0,0,1,310,564.31c-18-15-14-39-13.95-58.62" style="fill:none;stroke:#592d3d;stroke-linecap:round;stroke-miterlimit:10;stroke-width:12px"/>'
                )
            )
        );
    }

    function renderDizzyEyeSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="dizzy-eyes" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<line x1="375.88" y1="603.9" x2="306.24" y2="534.26" fill="none" stroke="#592d3d" stroke-linecap="round"    stroke-miterlimit="10" stroke-width="16" />',
                    '<line x1="306.24" y1="603.9" x2="375.88" y2="534.26" fill="none" stroke="#592d3d" stroke-linecap="round"   stroke-miterlimit="10" stroke-width="16" />',
                    '<line x1="695.99" y1="603.9" x2="626.34" y2="534.26" fill="none" stroke="#592d3d" stroke-linecap="round"   stroke-miterlimit="10" stroke-width="16" />',
                    '<line x1="626.34" y1="603.9" x2="695.99" y2="534.26" fill="none" stroke="#592d3d" stroke-linecap="round"   stroke-miterlimit="10" stroke-width="16" />'
                )
            )
        );
    }

    function renderHappyEyeSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="happy-eyes" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M296.49,572.61V559.68a49.6,49.6,0,0,1,1.94-25.32,46,46,0,0,1,3.51-7.65C305.29,518,314.29,511,323.29,508c14-4,31-2,42,9,14,15,12,37,12.45,55.62" style="fill:none;stroke:#592d3d;stroke-linecap:round;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M623.31,573c-2.34-26.62,1.66-63.62,36.13-67.17a45,45,0,0,1,8.12,0A43.68,43.68,0,0,1,690,514.41c18,15,14,39,13.95,58.63" style="fill:none;stroke:#592d3d;stroke-linecap:round;stroke-miterlimit:10;stroke-width:12px"/>'
                )
            )
        );
    }

    function renderHeartEyeSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="heart-eyes" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M271.4,576.82c-1-28.36,18-52.36,43.28-63.56a62.37,62.37,0,0,1,8.16-2.7,70,70,0,0,1,42.21,2.68A71.67,71.67,0,0,1,374,517.4c29.53,15.88,42.79,53.25,31.36,83.46a61.68,61.68,0,0,1-4.18,8.82,54.68,54.68,0,0,1-17.51,20.83,69.25,69.25,0,0,1-7.85,5c-27.38,13-64.38,9-86.45-11.4a69.35,69.35,0,0,1-6.11-7.47,64.89,64.89,0,0,1-5.57-9.5A55.78,55.78,0,0,1,272,585.39,75.67,75.67,0,0,1,271.4,576.82Z" style="fill:#f3ab98"/>',
                    '<path d="M269.77,558.47c-1-28.36,18-52.36,43.28-63.56a62.23,62.23,0,0,1,8.15-2.7,70,70,0,0,1,42.22,2.68,71.54,71.54,0,0,1,8.92,4.16c29.53,15.89,42.79,53.25,31.36,83.46a59.6,59.6,0,0,1-4.18,8.82,63.85,63.85,0,0,1-4.71,7.8,64.78,64.78,0,0,1-5.68,7,63.08,63.08,0,0,1-7.12,6.07,68.37,68.37,0,0,1-7.85,5c-27.38,13-64.38,9-86.44-11.4a67.24,67.24,0,0,1-6.11-7.47,65,65,0,0,1-5.58-9.5A55.59,55.59,0,0,1,270.32,567,71.3,71.3,0,0,1,269.77,558.47Z" style="fill:#fff;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M374,551.07v5.67a2,2,0,0,0-.13.39,21.27,21.27,0,0,1-1.92,6.53,44.36,44.36,0,0,1-8.59,12.09,120.43,120.43,0,0,1-24.25,18.93.87.87,0,0,1-1.06,0,128.66,128.66,0,0,1-19.86-14.63,61.62,61.62,0,0,1-11.37-13.31,24,24,0,0,1-3.08-18.5c3.22-14.32,21-20.17,32.15-10.57.95.81,1.79,1.76,2.74,2.7a2.75,2.75,0,0,1,.19-.28c5-5.56,11.1-8,18.44-6.81,8.05,1.35,13.32,6.16,15.89,13.9A36.94,36.94,0,0,1,374,551.07Z" style="fill:#e2495b"/>',
                    '<path d="M583.89,568.76c.43-15.13,6.67-30.09,15.1-41.33a72.82,72.82,0,0,1,7.12-8.53A69.73,69.73,0,0,1,696.28,510a73.27,73.27,0,0,1,6.53,5.13c27,21.45,30.12,63.14,15.32,93.23a62.31,62.31,0,0,1-4.78,6.86,72.09,72.09,0,0,1-7.58,8.13c-20.27,17.83-51.81,22.13-77.41,12.42a71.34,71.34,0,0,1-10.55-5c-17.9-10.78-30.37-31.09-33.43-52.23A62.93,62.93,0,0,1,583.89,568.76Z" style="fill:#f3ab98"/>',
                    '<path d="M589.38,557.26c.42-14.15,6.42-28.15,14.52-38.66a70.56,70.56,0,0,1,6.86-8,68.55,68.55,0,0,1,86.77-8.37,69.81,69.81,0,0,1,6.28,4.79c26,20.07,29,59.07,14.74,87.22a56.5,56.5,0,0,1-4.6,6.42,68.91,68.91,0,0,1-7.29,7.6C687.15,625,656.8,629,632.17,619.9A68.79,68.79,0,0,1,622,615.19c-17.22-10.08-29.22-29.08-32.17-48.85A56.34,56.34,0,0,1,589.38,557.26Z" style="fill:#fff;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M695.19,549.32v5.6a2.91,2.91,0,0,0-.12.39,21,21,0,0,1-1.89,6.44,43.87,43.87,0,0,1-8.49,11.94,118.43,118.43,0,0,1-24,18.69.87.87,0,0,1-1,0,127,127,0,0,1-19.61-14.44,61.31,61.31,0,0,1-11.22-13.14,23.82,23.82,0,0,1-3-18.27c3.18-14.14,20.79-19.91,31.75-10.44.94.8,1.77,1.74,2.7,2.67.06-.1.13-.19.19-.28,4.9-5.49,11-7.94,18.21-6.72,8,1.33,13.16,6.08,15.69,13.72A33.67,33.67,0,0,1,695.19,549.32Z" style="fill:#e2495b"/>'
                )
            )
        );
    }

    function renderLeftTwitchEyeSVG(bytes3 baseColor) private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="left-twitch-eye" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M271.4,568.53c-1-28.36,18-52.36,43.28-63.56a62.37,62.37,0,0,1,8.16-2.7A70,70,0,0,1,365.05,505a71.67,71.67,0,0,1,8.93,4.16c29.53,15.89,42.79,53.25,31.36,83.46a61.68,61.68,0,0,1-4.18,8.82,54.68,54.68,0,0,1-17.51,20.83,69.25,69.25,0,0,1-7.85,5c-27.38,13-64.38,9-86.45-11.4a68.39,68.39,0,0,1-6.11-7.47,64.89,64.89,0,0,1-5.57-9.5A55.78,55.78,0,0,1,272,577.1,75.67,75.67,0,0,1,271.4,568.53Z" style="fill:none"/>',
                    '<path d="M269.77,550.18c-1-28.36,18-52.36,43.28-63.56a62.23,62.23,0,0,1,8.15-2.7,70,70,0,0,1,42.22,2.68,71.54,71.54,0,0,1,8.92,4.16c29.53,15.89,42.79,53.26,31.36,83.46a59.6,59.6,0,0,1-4.18,8.82,63.85,63.85,0,0,1-4.71,7.8,64.78,64.78,0,0,1-5.68,7,63.08,63.08,0,0,1-7.12,6.07,68.37,68.37,0,0,1-7.85,5c-27.38,13-64.38,9-86.44-11.39a68.28,68.28,0,0,1-6.11-7.48,65,65,0,0,1-5.58-9.5,55.59,55.59,0,0,1-5.71-21.73A71.3,71.3,0,0,1,269.77,550.18Z" style="fill:#fff"/>',
                    '<circle cx="338.51" cy="541.79" r="12.24" style="fill:#592d3d"/>',
                    '<path d="M399.52,583a59.6,59.6,0,0,0,4.18-8.82,62.5,62.5,0,0,0,2.57-8.64c-68.32-7.75-127,20.81-127,20.81l1.1,1.75c.41.62.82,1.24,1.25,1.84a68.28,68.28,0,0,0,6.11,7.48c22.06,20.36,59.06,24.36,86.44,11.39a68.37,68.37,0,0,0,7.85-5,63.08,63.08,0,0,0,7.12-6.07,64.78,64.78,0,0,0,5.68-7A63.85,63.85,0,0,0,399.52,583Z" style="fill:',
                    BytesConverter.bytesToHex(baseColor),
                    ';stroke:#592d3d;stroke-miterlimit:10;stroke-width:6px"/>',
                    '<path d="M269.77,550.18c-1-28.36,18-52.36,43.28-63.56a62.23,62.23,0,0,1,8.15-2.7,70,70,0,0,1,42.22,2.68,71.54,71.54,0,0,1,8.92,4.16c29.53,15.89,42.79,53.26,31.36,83.46a59.6,59.6,0,0,1-4.18,8.82,63.85,63.85,0,0,1-4.71,7.8,64.78,64.78,0,0,1-5.68,7,63.08,63.08,0,0,1-7.12,6.07,68.37,68.37,0,0,1-7.85,5c-27.38,13-64.38,9-86.44-11.39a68.28,68.28,0,0,1-6.11-7.48,65,65,0,0,1-5.58-9.5,55.59,55.59,0,0,1-5.71-21.73A71.3,71.3,0,0,1,269.77,550.18Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M583.89,560.47c.43-15.13,6.67-30.09,15.1-41.33a72.82,72.82,0,0,1,7.12-8.53,69.73,69.73,0,0,1,90.17-8.95,73.27,73.27,0,0,1,6.53,5.13c27,21.45,30.12,63.14,15.32,93.23a62.31,62.31,0,0,1-4.78,6.86,72.09,72.09,0,0,1-7.58,8.13c-20.27,17.83-51.81,22.13-77.41,12.42a71.34,71.34,0,0,1-10.55-5c-17.9-10.78-30.37-31.09-33.43-52.23A62.93,62.93,0,0,1,583.89,560.47Z" style="fill:none"/>',
                    '<path d="M589.38,549c.42-14.15,6.42-28.15,14.52-38.66a70.56,70.56,0,0,1,6.86-8A68.55,68.55,0,0,1,697.53,494a69.81,69.81,0,0,1,6.28,4.79c26,20.07,29,59.07,14.74,87.22a56.5,56.5,0,0,1-4.6,6.42,68.91,68.91,0,0,1-7.29,7.6c-19.51,16.68-49.86,20.71-74.49,11.62A68.79,68.79,0,0,1,622,606.9c-17.22-10.08-29.22-29.08-32.17-48.85A56.34,56.34,0,0,1,589.38,549Z" style="fill:#fff;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<circle cx="659.21" cy="550.79" r="12.24" style="fill:#592d3d"/>',
                    '<path d="M718.86,618.11c-10.23,5-20.32,9.55-31.34,12.69a97.34,97.34,0,0,1-16.46,3.3,141.1,141.1,0,0,1-17.69.3A144.2,144.2,0,0,1,633,632.48c-1.93-.31-4.13.51-4.62,2.62-.41,1.81.55,4.28,2.62,4.62a164.26,164.26,0,0,0,19.66,2.1c3.19.13,6.37.06,9.56.16a78.25,78.25,0,0,0,9.06-.21c12-1,23.62-4.28,34.76-8.76,6.32-2.55,12.52-5.4,18.63-8.42a3.77,3.77,0,0,0,1.34-5.13,3.83,3.83,0,0,0-5.13-1.35Z" style="fill:#592d3d"/>',
                    '<path d="M365.31,627.42c-11.37,2.16-22.4,3.8-34.06,3.83a95.68,95.68,0,0,1-17-1.36,171.78,171.78,0,0,1-35.56-11.64,3.85,3.85,0,0,0-5.13,1.35c-.95,1.62-.5,4.27,1.34,5.13a164.42,164.42,0,0,0,17.87,7.1c2.91,1,5.87,1.7,8.78,2.6a91.22,91.22,0,0,0,8.91,2.35c11.95,2.42,24.22,2.37,36.31,1,6.88-.76,13.71-1.88,20.51-3.17,2-.37,3.12-2.77,2.62-4.61a3.83,3.83,0,0,0-4.62-2.62Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    function renderNormalEyeSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="normal-eyes" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M271.4,568.53c-1-28.36,18-52.36,43.28-63.56a62.37,62.37,0,0,1,8.16-2.7A70,70,0,0,1,365.05,505a71.67,71.67,0,0,1,8.93,4.16c29.53,15.89,42.79,53.25,31.36,83.46a61.68,61.68,0,0,1-4.18,8.82,54.68,54.68,0,0,1-17.51,20.83,69.25,69.25,0,0,1-7.85,5c-27.38,13-64.38,9-86.45-11.4a68.39,68.39,0,0,1-6.11-7.47,64.89,64.89,0,0,1-5.57-9.5A55.78,55.78,0,0,1,272,577.1,75.67,75.67,0,0,1,271.4,568.53Z" style="fill:none"/>',
                    '<path d="M269.77,550.18c-1-28.36,18-52.36,43.28-63.56a62.23,62.23,0,0,1,8.15-2.7,70,70,0,0,1,42.22,2.68,71.54,71.54,0,0,1,8.92,4.16c29.53,15.89,42.79,53.26,31.36,83.46a59.6,59.6,0,0,1-4.18,8.82,63.85,63.85,0,0,1-4.71,7.8,64.78,64.78,0,0,1-5.68,7,63.08,63.08,0,0,1-7.12,6.07,68.37,68.37,0,0,1-7.85,5c-27.38,13-64.38,9-86.44-11.39a68.28,68.28,0,0,1-6.11-7.48,65,65,0,0,1-5.58-9.5,55.59,55.59,0,0,1-5.71-21.73A71.3,71.3,0,0,1,269.77,550.18Z" style="fill:#fff;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<circle cx="338.51" cy="550.79" r="12.24" style="fill:#592d3d"/>',
                    '<path d="M583.89,560.47c.43-15.13,6.67-30.09,15.1-41.33a72.82,72.82,0,0,1,7.12-8.53,69.73,69.73,0,0,1,90.17-8.95,73.27,73.27,0,0,1,6.53,5.13c27,21.45,30.12,63.14,15.32,93.23a62.31,62.31,0,0,1-4.78,6.86,72.09,72.09,0,0,1-7.58,8.13c-20.27,17.83-51.81,22.13-77.41,12.42a71.34,71.34,0,0,1-10.55-5c-17.9-10.78-30.37-31.09-33.43-52.23A62.93,62.93,0,0,1,583.89,560.47Z" style="fill:#f3ab98"/>',
                    '<path d="M589.38,549c.42-14.15,6.42-28.15,14.52-38.66a70.56,70.56,0,0,1,6.86-8A68.55,68.55,0,0,1,697.53,494a69.81,69.81,0,0,1,6.28,4.79c26,20.07,29,59.07,14.74,87.22a56.5,56.5,0,0,1-4.6,6.42,68.91,68.91,0,0,1-7.29,7.6c-19.51,16.68-49.86,20.71-74.49,11.62A68.79,68.79,0,0,1,622,606.9c-17.22-10.08-29.22-29.08-32.17-48.85A56.34,56.34,0,0,1,589.38,549Z" style="fill:#fff;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<circle cx="659.21" cy="550.79" r="12.24" style="fill:#592d3d"/>'
                )
            )
        );
    }

    function renderSimpleEyeSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="simple-eyes" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<circle cx="341.06" cy="569.08" r="20.96" style="fill:#592d3d"/>',
                    '<path d="M340.93,586c1.79-.1,3.79-.26,5.7-.46s3.86-.44,5.79-.74,3.87-.65,5.81-1,3.92-.68,6-.83a24.74,24.74,0,0,1-5.31,3.12,48.86,48.86,0,0,1-5.78,2,50.61,50.61,0,0,1-6,1.36,36.13,36.13,0,0,1-6.24.54Z" style="fill:#592d3d"/>',
                    '<circle cx="661.77" cy="569.08" r="20.96" style="fill:#592d3d"/>',
                    '<path d="M661.77,586c1.8-.1,3.79-.26,5.7-.46s3.87-.44,5.8-.74,3.87-.65,5.81-1,3.92-.68,6-.83a25,25,0,0,1-5.31,3.12,48.86,48.86,0,0,1-5.78,2,51.06,51.06,0,0,1-6,1.36,36.22,36.22,0,0,1-6.24.54Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    function renderSquintEyeSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="squint-eyes" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M271.4,576.82c-1-28.36,18-52.36,43.28-63.56a62.37,62.37,0,0,1,8.16-2.7,70,70,0,0,1,42.21,2.68A71.67,71.67,0,0,1,374,517.4c29.53,15.88,42.79,53.25,31.36,83.46a61.68,61.68,0,0,1-4.18,8.82,54.68,54.68,0,0,1-17.51,20.83,69.25,69.25,0,0,1-7.85,5c-27.38,13-64.38,9-86.45-11.4a69.35,69.35,0,0,1-6.11-7.47,64.89,64.89,0,0,1-5.57-9.5A55.78,55.78,0,0,1,272,585.39,75.67,75.67,0,0,1,271.4,576.82Z" style="fill:#f3ab98"/>',
                    '<path d="M269.77,558.47c-1-28.36,18-52.36,43.28-63.56a62.23,62.23,0,0,1,8.15-2.7,70,70,0,0,1,42.22,2.68,71.54,71.54,0,0,1,8.92,4.16c29.53,15.89,42.79,53.25,31.36,83.46a59.6,59.6,0,0,1-4.18,8.82,63.85,63.85,0,0,1-4.71,7.8,64.78,64.78,0,0,1-5.68,7,63.08,63.08,0,0,1-7.12,6.07,68.37,68.37,0,0,1-7.85,5c-27.38,13-64.38,9-86.44-11.4a67.24,67.24,0,0,1-6.11-7.47,65,65,0,0,1-5.58-9.5A55.59,55.59,0,0,1,270.32,567,71.3,71.3,0,0,1,269.77,558.47Z" style="fill:#fff"/>',
                    '<circle cx="338.51" cy="559.08" r="12.24" style="fill:#592d3d"/>',
                    '<path d="M339.2,490.12a68.31,68.31,0,0,0-48.45,20.07,69.79,69.79,0,0,0-6.86,8,73.12,73.12,0,0,0-10.3,18.39H403.92a58.59,58.59,0,0,0-20.12-30,69.37,69.37,0,0,0-6.28-4.79A68.21,68.21,0,0,0,339.2,490.12Z" style="fill:#fdd2b2;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M274.09,581.45c5.5,13.75,15.3,25.93,27.92,33.32a68.27,68.27,0,0,0,10.15,4.7c24.63,9.09,55,5.07,74.49-11.61a69.9,69.9,0,0,0,7.29-7.61,55.62,55.62,0,0,0,4.6-6.42,77.37,77.37,0,0,0,4.94-12.38Z" style="fill:#fdd2b2;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M269.77,558.47c-1-28.36,18-52.36,43.28-63.56a62.23,62.23,0,0,1,8.15-2.7,70,70,0,0,1,42.22,2.68,71.54,71.54,0,0,1,8.92,4.16c29.53,15.89,42.79,53.25,31.36,83.46a59.6,59.6,0,0,1-4.18,8.82,63.85,63.85,0,0,1-4.71,7.8,64.78,64.78,0,0,1-5.68,7,63.08,63.08,0,0,1-7.12,6.07,68.37,68.37,0,0,1-7.85,5c-27.38,13-64.38,9-86.44-11.4a67.24,67.24,0,0,1-6.11-7.47,65,65,0,0,1-5.58-9.5A55.59,55.59,0,0,1,270.32,567,71.3,71.3,0,0,1,269.77,558.47Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M583.89,568.76c.43-15.13,6.67-30.09,15.1-41.33a72.82,72.82,0,0,1,7.12-8.53A69.73,69.73,0,0,1,696.28,510a73.27,73.27,0,0,1,6.53,5.13c27,21.45,30.12,63.14,15.32,93.23a62.31,62.31,0,0,1-4.78,6.86,72.09,72.09,0,0,1-7.58,8.13c-20.27,17.83-51.81,22.13-77.41,12.42a71.34,71.34,0,0,1-10.55-5c-17.9-10.78-30.37-31.09-33.43-52.23A62.93,62.93,0,0,1,583.89,568.76Z" style="fill:#f3ab98"/>',
                    '<path d="M589.38,557.26c.42-14.15,6.42-28.15,14.52-38.66a70.56,70.56,0,0,1,6.86-8,68.55,68.55,0,0,1,86.77-8.37,69.81,69.81,0,0,1,6.28,4.79c26,20.07,29,59.07,14.74,87.22a56.5,56.5,0,0,1-4.6,6.42,68.91,68.91,0,0,1-7.29,7.6C687.15,625,656.8,629,632.17,619.9A68.79,68.79,0,0,1,622,615.19c-17.22-10.08-29.22-29.08-32.17-48.85A56.34,56.34,0,0,1,589.38,557.26Z" style="fill:#fff"/>',
                    '<circle cx="659.21" cy="559.08" r="12.24" style="fill:#592d3d"/>',
                    '<path d="M659.21,490.55a68.31,68.31,0,0,0-48.45,20.07,70.56,70.56,0,0,0-6.86,8A73.3,73.3,0,0,0,593.6,537H723.93A58.63,58.63,0,0,0,703.81,507a69.81,69.81,0,0,0-6.28-4.79A68.21,68.21,0,0,0,659.21,490.55Z" style="fill:#fdd2b2;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M594.1,581.87c5.51,13.76,15.3,25.94,27.92,33.32a68.79,68.79,0,0,0,10.15,4.71c24.63,9.09,55,5.06,74.49-11.62a68.91,68.91,0,0,0,7.29-7.6,56.5,56.5,0,0,0,4.6-6.42,76.19,76.19,0,0,0,4.94-12.39Z" style="fill:#fdd2b2;stroke:#592d3d;stroke-miterlimit:10;stroke-width:8px"/>',
                    '<path d="M589.38,557.26c.42-14.15,6.42-28.15,14.52-38.66a70.56,70.56,0,0,1,6.86-8,68.55,68.55,0,0,1,86.77-8.37,69.81,69.81,0,0,1,6.28,4.79c26,20.07,29,59.07,14.74,87.22a56.5,56.5,0,0,1-4.6,6.42,68.91,68.91,0,0,1-7.29,7.6C687.15,625,656.8,629,632.17,619.9A68.79,68.79,0,0,1,622,615.19c-17.22-10.08-29.22-29.08-32.17-48.85A56.34,56.34,0,0,1,589.38,557.26Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>'
                )
            )
        );
    }

    function renderWinkEyeSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="wink-eye" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M271.4,576.82c-1-28.36,18-52.36,43.28-63.56a62.37,62.37,0,0,1,8.16-2.7,70,70,0,0,1,42.21,2.68A71.67,71.67,0,0,1,374,517.4c29.53,15.88,42.79,53.25,31.36,83.46a61.68,61.68,0,0,1-4.18,8.82,54.68,54.68,0,0,1-17.51,20.83,69.25,69.25,0,0,1-7.85,5c-27.38,13-64.38,9-86.45-11.4a69.35,69.35,0,0,1-6.11-7.47,64.89,64.89,0,0,1-5.57-9.5A55.78,55.78,0,0,1,272,585.39,75.67,75.67,0,0,1,271.4,576.82Z" style="fill:#f3ab98"/>',
                    '<path d="M269.77,558.47c-1-28.36,18-52.36,43.28-63.56a62.23,62.23,0,0,1,8.15-2.7,70,70,0,0,1,42.22,2.68,71.54,71.54,0,0,1,8.92,4.16c29.53,15.89,42.79,53.25,31.36,83.46a59.6,59.6,0,0,1-4.18,8.82,63.85,63.85,0,0,1-4.71,7.8,64.78,64.78,0,0,1-5.68,7,63.08,63.08,0,0,1-7.12,6.07,68.37,68.37,0,0,1-7.85,5c-27.38,13-64.38,9-86.44-11.4a67.24,67.24,0,0,1-6.11-7.47,65,65,0,0,1-5.58-9.5A55.59,55.59,0,0,1,270.32,567,71.3,71.3,0,0,1,269.77,558.47Z" style="fill:#fff;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<circle cx="338.51" cy="559.08" r="12.24" style="fill:#592d3d"/>',
                    '<line x1="715.03" y1="559.08" x2="603.4" y2="559.08" style="fill:none;stroke:#592d3d;stroke-linecap:round;stroke-miterlimit:10;stroke-width:16px"/>',
                    '<path d="M627,574.16a114.14,114.14,0,0,1,13.07-1.56c4.36-.3,8.72-.43,13.08-.44s8.71.14,13.07.43a114.34,114.34,0,0,1,13.08,1.57,112.18,112.18,0,0,1-13.08,1.58q-6.54.43-13.07.42t-13.08-.43A112,112,0,0,1,627,574.16Z" style="fill:#592d3d"/>'
                )
            )
        );
    }
}
