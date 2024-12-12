// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {SVGBody} from "src/libraries/SVGBody.sol";

library EyesDetail {
    error EyesDetail__InvalidEyeShape();

    string constant CONTENT_EYES = "Content Eyes";
    string constant DIZZY_EYES = "Dizzy Eyes";
    string constant HAPPY_EYES = "Happy Eyes";
    string constant HEART_EYES = "Heart Eyes";
    string constant LEFT_TWITCH_EYE = "Left Twitch Eye";
    string constant NORMAL_EYES = "Normal Eyes";
    string constant SIMPLE_EYES = "Simple Eyes";
    string constant SQUINT_EYES = "Squint Eyes";
    string constant WINK_EYE = "Wink Eye";

    struct Eye {
        string name;
        string svg;
    }

    /// @dev SVG content for the Content Eyes
    function contentEyeSVG() internal pure returns (string memory) {
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
}
