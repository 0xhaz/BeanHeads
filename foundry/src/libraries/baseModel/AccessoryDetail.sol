// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {SVGBody} from "./SVGBody.sol";
import {Errors} from "src/types/Constants.sol";

library AccessoryDetail {
    enum AccessoryType {
        NONE,
        ROUNDGLASSES,
        SHADES,
        TINYGLASSES
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev SVG content for "round glasses" accessories

    function roundGlassesSVG() internal pure returns (string memory) {
        return renderRoundGlassesSVG();
    }

    /// @dev SVG content for "shades" accessory
    function shadesSVG() internal pure returns (string memory) {
        return renderShadeSVG();
    }

    /// @dev execute the SVG content for "tiny glasses" accessory
    function tinyGlassesSVG() internal pure returns (string memory) {
        return rendertinyGlassesSVG();
    }

    /// @dev Returns the SVG and name for a specific accessory ID
    function getAccessoryById(uint8 id) internal pure returns (string memory svg, string memory name) {
        if (id == uint8(AccessoryType.NONE)) return ("", "");
        string[4] memory accessories = ["", roundGlassesSVG(), shadesSVG(), tinyGlassesSVG()];
        if (id >= accessories.length) revert Errors.InvalidType(id);

        svg = accessories[id];
        name = getAccessoryName(id);
        return (svg, name);
    }

    function getAccessoryName(uint8 id) internal pure returns (string memory) {
        string[4] memory accessoryNames = ["None", "Round Glasses", "Shades", "Tiny Glasses"];

        if (id >= accessoryNames.length) revert Errors.InvalidType(id);
        return accessoryNames[id];
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev SVG content for "round glasses" accessories
    function renderRoundGlassesSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="round-glasses" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<circle cx="338.9" cy="548.55" r="93.31" style="fill:#fff;opacity:.2"/>',
                    '<path d="M744.47,606.82a103.27,103.27,0,0,1-188.33-51.49c-37-14.6-74.43-14.47-114.19.39a103.43,103.43,0,0,1-103,96.13c-32.48,0-76-36.5-71-28.39,14,20.69,47,36.45,72.54,36.45,54.55,0,97.87-39.29,101.56-92.92,39.76-14.85,77.23-15,114.19-.39,3.5,53.82,48.39,93.53,103.07,93.53C704,660.13,729.4,626,744.47,606.82Z" style="opacity:.15"/>',
                    '<path d="M320,648.75,443.07,525.67a93.05,93.05,0,0,0-10-17.27L302.72,638.76A93.1,93.1,0,0,0,320,648.75Z" style="fill:#fff;opacity:.4"/>',
                    '<circle cx="338.9" cy="548.55" r="93.31" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:20px"/>',
                    '<circle cx="659.21" cy="548.55" r="93.31" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:20px"/>',
                    '<path d="M432.77,548.55c45.2-18.31,89.61-19,133.14,0" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:20px"/>',
                    ' <path d="M314.7,492.5c2.06,6.5-5.94,11.5-11.94,12.5-6,0-10-4-12-9-1-5,0-10,4-13,5-2,12-4,16.45,1.13A11.66,11.66,0,0,1,314.7,492.5Z" style="fill:#fff"/>',
                    ' <path d="M325.37,488.67c-.61,4.33-6.61,4.33-7.61.33,0-3,1-4,3.85-4.1A3.76,3.76,0,0,1,325.37,488.67Z" style="fill:#fff"/>',
                    '<circle cx="659.21" cy="548.55" r="93.31" style="fill:#fff;opacity:.2"/>',
                    '<path d="M645.19,640.81,751.47,534.52a94.74,94.74,0,0,0-2.41-11.22L634,638.4A94.31,94.31,0,0,0,645.19,640.81Z" style="fill:#fff;opacity:.4"/>',
                    '<circle cx="659.21" cy="548.55" r="93.31" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:20px"/>',
                    '<path d="M635,492.5c2.06,6.5-5.94,11.5-11.94,12.5-6,0-10-4-12-9-1-5,0-10,4-13,5-2,12-4,16.45,1.13A11.7,11.7,0,0,1,635,492.5Z" style="fill:#fff"/>',
                    '<path d="M645.69,488.67c-.61,4.33-6.61,4.33-7.61.33,0-3,1-4,3.84-4.1A3.77,3.77,0,0,1,645.69,488.67Z" style="fill:#fff"/>'
                )
            )
        );
    }

    /// @dev Render SVG content for "shades" accessory
    function renderShadeSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="shades" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M725,631.82a265.34,265.34,0,0,0,26.3-59.43c-17.24,35.74-49.84,65.46-92.11,65.46A106.75,106.75,0,0,1,552.58,531.22,105.67,105.67,0,0,1,560.41,491H758a105.33,105.33,0,0,1,7.62,33.39c.73-8,1.12-16.19,1.12-24.42a269.16,269.16,0,0,0-1.58-29H575v0H423.14v0H234.83a269.16,269.16,0,0,0-1.58,29c0,4.73.14,9.42.38,14.09A104.92,104.92,0,0,1,240.1,491H437.7a106.7,106.7,0,0,1-98.8,146.82c-38.8,0-68.82-25.83-87.48-56.89a266.14,266.14,0,0,0,24.76,52.84c19.39,12.07,38.25,24.05,62.72,24.05A126.78,126.78,0,0,0,465.53,531.22c0-1.81,0-3.61-.12-5.4,23.38-8.23,45.52-8.35,67.31-.36-.08,1.91-.14,3.83-.14,5.76A126.78,126.78,0,0,0,659.21,657.85C685,657.85,705,645.1,725,631.82ZM535.26,505.18c-23.4-7.55-47.64-7.42-72.33.39A124.62,124.62,0,0,0,459,491h80.1A122.6,122.6,0,0,0,535.26,505.18Z" style="opacity:.15;mix-blend-mode:multiply"/>',
                    '<path d="M233.59,469.82s.41,32.23.41,50.2c0,64.41,40.48,116.63,104.9,116.63A116.68,116.68,0,0,0,444.2,469.82Z" style="fill:#592d3d;opacity:.9500000000000001"/>',
                    '<path d="M553.91,469.82a116.68,116.68,0,0,0,105.3,166.83c64.42,0,107.54-52.22,107.54-116.63,0-18-2.23-50.2-2.23-50.2Z" style="fill:#592d3d;opacity:.9500000000000001"/>',
                    '<path d="M320,626.86,443.07,503.78a93.05,93.05,0,0,0-10-17.27L302.72,616.88A93.62,93.62,0,0,0,320,626.86Z" style="fill:#fff;opacity:.25"/>',
                    '<path d="M455.86,507.53c29.52-12,58.53-12.42,87,0" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:20px"/>',
                    '<path d="M274.28,504.75c2.06,6.51-5.94,11.51-11.94,12.51-6,0-10-4-12-9-1-5,0-10,4-13,5-2,12-4,16.44,1.12A11.7,11.7,0,0,1,274.28,504.75Z" style="fill:#fff"/>',
                    '<path d="M285,500.93c-.61,4.33-6.61,4.33-7.61.33,0-3,1-4,3.84-4.1A3.77,3.77,0,0,1,285,500.93Z" style="fill:#fff"/>',
                    '<path d="M645.19,618.92,751.47,512.64a93.89,93.89,0,0,0-2.41-11.22L634,616.51A94.31,94.31,0,0,0,645.19,618.92Z" style="fill:#fff;opacity:.25"/>',
                    '<path d="M590.68,505.73c2.06,6.51-5.94,11.51-11.94,12.51-6,0-10-4-12-9-1-5,0-10,4-13,5-2,12-4,16.45,1.12A11.69,11.69,0,0,1,590.68,505.73Z" style="fill:#fff"/>',
                    '<path d="M601.35,501.91c-.61,4.33-6.61,4.33-7.61.33,0-3,1-4,3.85-4.1A3.76,3.76,0,0,1,601.35,501.91Z" style="fill:#fff"/>',
                    '<path d="M233.59,469.82s-.34,31.69.41,50.2c2.6,64.36,40.48,116.63,104.9,116.63A116.68,116.68,0,0,0,444.2,469.82Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:20px"/>',
                    '<path d="M553.91,469.82a116.68,116.68,0,0,0,105.3,166.83c64.42,0,107.54-51.53,107.54-115.94,0-18-2.23-50.89-2.23-50.89Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:20px"/>',
                    '<line x1="423.14" y1="469.81" x2="574.97" y2="469.81" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:20px"/>'
                )
            )
        );
    }

    /// @dev Render SVG content for "tiny glasses" accessory
    function rendertinyGlassesSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="tiny-glasses" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 990"',
            string(
                abi.encodePacked(
                    '<circle cx="382.91" cy="594.66" r="33.84" style="fill:#fff;opacity:.20000000298023224;isolation:isolate"/>',
                    '<path d="M375.87,631l43.31-41.74a147.47,147.47,0,0,0-7.57-12.9l-45.87,44.21C367.64,621.9,373.72,630.08,375.87,631Z" style="fill:#fff;opacity:.4000000059604645;isolation:isolate"/>',
                    '<circle cx="382.91" cy="594.66" r="33.84" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M378,580.47c1.22,3.83-3.5,6.78-7,7.37-3.54,0-5.9-2.36-7.08-5.31-.59-2.95,0-5.9,2.36-7.67,2.95-1.18,7.08-2.36,9.7.67A6.85,6.85,0,0,1,378,580.47Z" style="fill:#fff"/>',
                    '<path d="M384.32,578.21a2.29,2.29,0,0,1-4.49.19c0-1.77.59-2.36,2.27-2.42a2.22,2.22,0,0,1,2.22,2.22Z" style="fill:#fff"/>',
                    '<circle cx="615.2" cy="594.66" r="33.84" style="fill:#fff;opacity:.20000000298023224;isolation:isolate"/>',
                    '<path d="M610.12,628.11l38.54-38.54c-.21-1.37-5.91-8.1-6.29-9.44l-41.72,41.74C602,622.24,608.75,627.91,610.12,628.11Z" style="fill:#fff;opacity:.4000000059604645;isolation:isolate"/>',
                    '<circle cx="615.2" cy="594.66" r="33.84" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M607.36,579.91c1,3.25-3,5.75-6,6.25-3,0-5-2-6-4.5-.5-2.5,0-5,2-6.5,2.5-1,6-2,8.23.57A5.85,5.85,0,0,1,607.36,579.91Z" style="fill:#fff"/>',
                    '<path d="M612.7,578a1.94,1.94,0,0,1-3.8.16c0-1.5.5-2,1.92-2A1.88,1.88,0,0,1,612.7,578Z" style="fill:#fff"/>',
                    '<path d="M416.74,594.66q83.68-30,164.63,0" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M615.2,634.5A39.9,39.9,0,0,1,575.6,599c-50-17.65-101.46-17.64-153.1,0a39.81,39.81,0,0,1-50.92,33.84,38,38,0,0,0,54.51-29.91c49.22-16.86,98.28-16.88,145.93,0a38,38,0,0,0,54.51,30A40,40,0,0,1,615.2,634.5Z" style="opacity:.15"/>'
                )
            )
        );
    }
}
