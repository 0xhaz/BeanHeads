// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {SVGBody} from "./SVGBody.sol";
import {Errors} from "src/types/Constants.sol";

library EyebrowDetail {
    enum EyebrowType {
        ANGRY,
        CONCERNED,
        LEFTLOWERED,
        NORMAL,
        SERIOUS
    }
    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev SVG content for the Angry Eyebrows
    function angryEyebrowSVG() internal pure returns (string memory) {
        return renderAngryEyebrowSVG();
    }

    /// @dev SVG content for the Concerned Eyebrows
    function concernedEyebrowSVG() internal pure returns (string memory) {
        return renderConcernedEyebrowSVG();
    }

    /// @dev SVG content for the Left Lowered Eyebrow
    function leftLoweredEyebrowSVG() internal pure returns (string memory) {
        return renderLeftLoweredEyebrowSVG();
    }

    /// @dev SVG content for the Normal Eyebrows
    function normalEyebrowSVG() internal pure returns (string memory) {
        return renderNormalEyebrowSVG();
    }

    /// @dev SVG content for the Serious Eyebrows
    function seriousEyebrowSVG() internal pure returns (string memory) {
        return renderSeriousEyebrowSVG();
    }

    /// @dev Returns the SVG and name for a specific eyebrow type
    function getEyebrowById(uint8 id) internal pure returns (string memory svg, string memory name) {
        string[5] memory eyebrows =
            [angryEyebrowSVG(), concernedEyebrowSVG(), leftLoweredEyebrowSVG(), normalEyebrowSVG(), seriousEyebrowSVG()];

        if (id >= eyebrows.length) revert Errors.InvalidType(id);

        svg = eyebrows[id];
        name = getEyebrowName(id);
        return (svg, name);
    }

    function getEyebrowName(uint8 id) internal pure returns (string memory) {
        string[5] memory eyebrowNames = ["Angry", "Concerned", "Left Lowered", "Normal", "Serious"];
        if (id >= eyebrowNames.length) revert Errors.InvalidType(id);
        return eyebrowNames[id];
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function renderAngryEyebrowSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="angry-eyebrows" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M427.29,501.13l-13-4.39-31.2-10.54-37.6-12.71-32.49-11c-5.27-1.78-10.51-3.68-15.81-5.34l-.22-.08a10,10,0,0,0-5.32,19.29l13,4.39,31.2,10.54,37.6,12.7,32.49,11c5.26,1.78,10.5,3.67,15.81,5.34l.22.08a10,10,0,0,0,5.32-19.29Z" style="fill:#592d3d"/>',
                    '<path d="M697.18,453.9,684.46,459l-30.54,12.31-36.81,14.84L585.3,499q-7.74,3.12-15.47,6.24l-.22.08c-2.51,1-4.56,2.17-6,4.6a10.18,10.18,0,0,0-1,7.71,10.06,10.06,0,0,0,4.6,6c2.22,1.18,5.26,2,7.7,1l12.73-5.13,30.54-12.31L655,492.33l31.81-12.82c5.15-2.08,10.32-4.15,15.47-6.24l.22-.09c2.51-1,4.56-2.17,6-4.59a10,10,0,0,0-3.59-13.69c-2.22-1.17-5.27-2-7.71-1Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    function renderConcernedEyebrowSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="concerned-eyebrows" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M255.06,519.62l13-4.4,31.2-10.54,37.6-12.7,32.49-11c5.27-1.78,10.55-3.51,15.8-5.34l.23-.07a10.6,10.6,0,0,0,6-4.6,10,10,0,0,0-3.58-13.68,10,10,0,0,0-7.71-1l-13,4.39-31.2,10.54-37.6,12.71-32.49,11c-5.27,1.78-10.55,3.52-15.8,5.34l-.23.08a10.6,10.6,0,0,0-6,4.6,10,10,0,0,0,3.58,13.68,10,10,0,0,0,7.71,1Z" style="fill:#592d3d"/>',
                    '<path d="M617.56,475l12.73,5.13,30.54,12.31,36.81,14.84,31.81,12.83c5.15,2.07,10.26,4.3,15.47,6.24l.22.08c2.25.91,5.71.16,7.71-1a10,10,0,0,0,3.58-13.69l-1.56-2a10,10,0,0,0-4.41-2.57L737.73,502l-30.54-12.32-36.81-14.84L638.57,462c-5.15-2.08-10.26-4.31-15.47-6.24l-.22-.09c-2.25-.91-5.71-.16-7.71,1a10,10,0,0,0-3.58,13.68l1.56,2a10.07,10.07,0,0,0,4.41,2.58Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    function renderLeftLoweredEyebrowSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="left-lowered-eyebrow" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M603.1,452.29a320.74,320.74,0,0,1,33.51-6.66L634,446a150.31,150.31,0,0,1,39.75-.48l-2.66-.36c3.28.45,6.54,1,9.82,1.41l-2.66-.35a222.52,222.52,0,0,1,29.48,6.1c5,1.4,11.11-1.72,12.3-7a10.19,10.19,0,0,0-7-12.3,239.34,239.34,0,0,0-34.58-6.78l2.65.36a142.93,142.93,0,0,0-33.43-1.95,236.67,236.67,0,0,0-33.1,4.54c-5.61,1.14-11.19,2.44-16.76,3.81-5.08,1.25-8.61,7.26-7,12.3a10.21,10.21,0,0,0,12.3,7Z" style="fill:#592d3d"/>',
                    '<path d="M261.26,502.22l14.13-1.48,33.67-3.52L350,492.93l35.18-3.69c5.72-.59,11.44-1.17,17.16-1.79l.24,0c2.73-.28,5.07-.92,7.07-2.93a10,10,0,0,0,0-14.14c-1.83-1.69-4.48-3.2-7.07-2.93l-14.13,1.48-33.67,3.53-41,4.29-35.18,3.68c-5.72.6-11.44,1.18-17.16,1.8l-.24,0c-2.73.29-5.07.93-7.07,2.93a10,10,0,0,0,0,14.15c1.83,1.68,4.48,3.2,7.07,2.92Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    function renderNormalEyebrowSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="normal-eyebrows" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M600.89,460.57a318.14,318.14,0,0,1,33.51-6.65l-2.66.35c13.18-1.74,26.54-2.25,39.75-.48l-2.66-.36c3.27.46,6.54,1,9.82,1.42l-2.66-.36a221,221,0,0,1,29.48,6.11c5,1.39,11.1-1.73,12.3-7a10.19,10.19,0,0,0-7-12.3,239.21,239.21,0,0,0-34.59-6.78l2.66.36a143,143,0,0,0-33.44-1.95,235.08,235.08,0,0,0-33.09,4.55c-5.62,1.13-11.2,2.43-16.76,3.8-5.08,1.25-8.62,7.26-7,12.3a10.19,10.19,0,0,0,12.3,7Z" style="fill:#592d3d"/>',
                    '<path d="M286.14,460.6a202.56,202.56,0,0,1,29.25-6.19l-2.66.36a195.53,195.53,0,0,1,51.38.08l-2.66-.35a218.94,218.94,0,0,1,29.45,6.1c5,1.4,11.1-1.73,12.3-7a10.19,10.19,0,0,0-7-12.3A227.26,227.26,0,0,0,352,433.6a208.27,208.27,0,0,0-71.22,7.71,10.39,10.39,0,0,0-6,4.6,10.2,10.2,0,0,0-1,7.7c1.65,5.11,6.91,8.54,12.3,7Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    function renderSeriousEyebrowSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="serious-eyebrows" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M407.29,474.84H286.65c-5.56,0-11.12-.08-16.68,0h-.24c-5.23,0-10.24,4.6-10,10a10.17,10.17,0,0,0,10,10H390.37c5.55,0,11.12.08,16.68,0h.24c5.23,0,10.24-4.6,10-10a10.18,10.18,0,0,0-10-10Z" style="fill:#592d3d"/>',
                    '<path d="M726.32,474.84H605.68c-5.56,0-11.12-.08-16.68,0h-.24c-5.23,0-10.24,4.6-10,10a10.17,10.17,0,0,0,10,10H709.4c5.56,0,11.12.08,16.68,0h.24c5.23,0,10.24-4.6,10-10a10.18,10.18,0,0,0-10-10Z" style="fill:#592d3d"/>'
                )
            )
        );
    }
}
