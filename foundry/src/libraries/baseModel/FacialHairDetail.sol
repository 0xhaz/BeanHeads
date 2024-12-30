// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {SVGBody} from "./SVGBody.sol";

library FacialHairDetail {
    error FacialHairDetail__InvalidFacialHairType();

    /// @dev SVG content for a medium beard
    function mediumBeardSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="medium-beard" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M670.06,788.32q3.3-3.32,6.5-6.71c45.16-54.71,48.7-112.39,57.87-148.37V619l-2.44.84c.83-1.52,1.65-3,2.44-4.56-.06-.1-3.49,3.38-3.55,3.28A33.65,33.65,0,0,1,725.8,622l-32.55,11.28a220.36,220.36,0,0,1-43.89,3.82c-63-.26-63.24-14.87-113.2-20l-96.49,1.58c-25.69,3.84-37.06,11.81-88,12.85-44.15.9-83.62-10-83.62-10v12.68c14,36.84,4.58,64.43,29,110.49,0-.65,0-1.31-.05-2-4.39-21.71,0-41.57,2.12-49.19.21-1.88.36-2.92.36-2.92v-.07c0-.12,0-.2,0-.2l0,.1c0,.14.11.45.22.9.23-.72.36-1.11.36-1.11s.89,4.91,2.54,12.74c3.93,15.48,11.16,43,19.45,70.08.92,2.43,1.87,4.81,2.84,7.11.07.21.15.44.23.65,27.94,29.88,62.13,55.36,93.14,74.5,3.34,2,6.51,3.87,9.48,5.61a86.4,86.4,0,0,1,2.41-43.06s.07.38.21,1.08c.24-.77.4-1.19.4-1.19s11.43,47.45,34.52,62.83c.57.24,1.15.47,1.73.66l-.44.16.1.06c.58.33,1.18.65,1.77,1a208.45,208.45,0,0,0,21.34,8.53c5.41,1.57,9.84,2.39,12,2.39,4.75,0,32-10.61,48.69-49.07,1.1-3.27,1.63-5.32,1.63-5.32l.28.69c.11-.27.22-.53.32-.8A56,56,0,0,1,560.7,869a526,526,0,0,0,72.06-47.55l0-.11c.27-.64.53-1.29.8-1.94l.06-.13.81-2v0l.84-2.08v0c14.48-35.83,23.58-89,23.58-89,.06-.18.28.09.6.74,0-.55,0-.85,0-.85S675.72,748.49,670.06,788.32Z" style="fill:#fff"/>',
                    '<path d="M670.06,788.32q3.3-3.32,6.5-6.71c45.16-54.71,48.7-112.39,57.87-148.37V619l-2.44.84c.83-1.52,1.65-3,2.44-4.56-.06-.1-3.49,3.38-3.55,3.28A33.65,33.65,0,0,1,725.8,622l-32.55,11.28a220.36,220.36,0,0,1-43.89,3.82c-63-.26-63.24-14.87-113.2-20l-96.49,1.58c-25.69,3.84-37.06,11.81-88,12.85-44.15.9-83.62-10-83.62-10v12.68c14,36.84,4.58,64.43,29,110.49,0-.65,0-1.31-.05-2-4.39-21.71,0-41.57,2.12-49.19.21-1.88.36-2.92.36-2.92v-.07c0-.12,0-.2,0-.2l0,.1c0,.14.11.45.22.9.23-.72.36-1.11.36-1.11s.89,4.91,2.54,12.74c3.93,15.48,11.16,43,19.45,70.08.92,2.43,1.87,4.81,2.84,7.11.07.21.15.44.23.65,27.94,29.88,62.13,55.36,93.14,74.5,3.34,2,6.51,3.87,9.48,5.61a86.4,86.4,0,0,1,2.41-43.06s.07.38.21,1.08c.24-.77.4-1.19.4-1.19s11.43,47.45,34.52,62.83c.57.24,1.15.47,1.73.66l-.44.16.1.06c.58.33,1.18.65,1.77,1a208.45,208.45,0,0,0,21.34,8.53c5.41,1.57,9.84,2.39,12,2.39,4.75,0,32-10.61,48.69-49.07,1.1-3.27,1.63-5.32,1.63-5.32l.28.69c.11-.27.22-.53.32-.8A56,56,0,0,1,560.7,869a526,526,0,0,0,72.06-47.55l0-.11c.27-.64.53-1.29.8-1.94l.06-.13.81-2v0l.84-2.08v0c14.48-35.83,23.58-89,23.58-89,.06-.18.28.09.6.74,0-.55,0-.85,0-.85S675.72,748.49,670.06,788.32Z" style="fill:#fff"/>',
                    '<path d="M670.06,788.32q3.3-3.32,6.5-6.71c45.16-54.71,48.7-112.39,57.87-148.37V619l-2.44.84c.83-1.52,1.65-3,2.44-4.56-.06-.1-3.49,3.38-3.55,3.28A33.65,33.65,0,0,1,725.8,622l-32.55,11.28a220.36,220.36,0,0,1-43.89,3.82c-63-.26-78.3-19.69-113.2-20s-76.95-1.23-96.49,1.58-37.06,11.81-88,12.85c-44.15.9-83.62-10-83.62-10v12.68c14,36.84,4.58,64.43,29,110.49,0-.65,0-1.31-.05-2-4.39-21.71,0-41.57,2.12-49.19.21-1.88.36-2.92.36-2.92v-.07c0-.12,0-.2,0-.2l0,.1c0,.14.11.45.22.9.23-.72.36-1.11.36-1.11s.89,4.91,2.54,12.74c3.93,15.48,11.16,43,19.45,70.08.92,2.43,1.87,4.81,2.84,7.11.07.21.15.44.23.65,27.94,29.88,62.13,55.36,93.14,74.5,3.34,2,6.51,3.87,9.48,5.61a86.4,86.4,0,0,1,2.41-43.06s.07.38.21,1.08c.24-.77.4-1.19.4-1.19s11.43,47.45,34.52,62.83c.57.24,1.15.47,1.73.66l-.44.16.1.06c.58.33,1.18.65,1.77,1a208.45,208.45,0,0,0,21.34,8.53c5.41,1.57,9.84,2.39,12,2.39,4.75,0,32-10.61,48.69-49.07,1.1-3.27,1.63-5.32,1.63-5.32l.28.69c.11-.27.22-.53.32-.8A56,56,0,0,1,560.7,869a526,526,0,0,0,72.06-47.55l0-.11c.27-.64.53-1.29.8-1.94l.06-.13.81-2v0l.84-2.08v0c14.48-35.83,23.58-89,23.58-89,.06-.18.28.09.6.74,0-.55,0-.85,0-.85S675.72,748.49,670.06,788.32Z" style="fill:#fff"/>',
                    '<path d="M343.5,706.91a23.12,23.12,0,0,0,13.79,5.8C343,701.34,337.78,690.32,336,685.36A271.66,271.66,0,0,1,326,630.81a329.37,329.37,0,0,1-57.87-9.33v12.68c14,36.84,4.58,64.43,29,110.49,0-.65,0-1.31-.05-2-4.39-21.71,0-41.57,2.12-49.19.21-1.88.36-2.92.36-2.92v-.07c0-.12,0-.2,0-.2l0,.1c0,.14.11.45.22.9.23-.72.36-1.11.36-1.11s.89,4.91,2.54,12.74c3.93,15.48,11.16,43,19.45,70.08.92,2.43,1.87,4.81,2.84,7.11.07.21.15.44.23.65,27.94,29.88,62.13,55.36,93.14,74.5,3.34,2,6.51,3.87,9.48,5.61a86.4,86.4,0,0,1,2.41-43.06s.07.38.21,1.08c.24-.77.4-1.19.4-1.19s11.43,47.45,34.52,62.83c.57.24,1.15.47,1.73.66l-.44.16.1.06c.58.33,1.18.65,1.77,1a208.45,208.45,0,0,0,21.34,8.53c5.41,1.57,9.84,2.39,12,2.39,3.53,0,19.51-5.88,34.33-24.72C466.94,846.06,380.78,800,343.5,706.91Z" style="fill:#E2E2E2"/>',
                    '<path d="M433.87,816.78s9.49,9,29.29,4.09c-1.47,3.55-5.93,5.4-5.93,5.4s6.17,8.13,19.06,7.75c0,0-7.73,4.8-15.53,1.65A169.67,169.67,0,0,0,442.41,834l-13.51-9.38Z" style="fill:#E2E2E2"/>',
                    '<path d="M351.7,631.52q-2.64.48-5.28.84c-.89.11-1.77.25-2.65.35l-2.66.24-5.32.38c-1.78.08-3.56.09-5.33.14-3.56.07-7.11-.07-10.67-.2s-7.1-.37-10.64-.71-7.07-.7-10.61-1.1-7.05-1-10.56-1.56a196.89,196.89,0,0,1-21-4.57l-3.85-1.08,2.1-7.57,3.88.94c6.61,1.61,13.47,3.13,20.27,4.49s13.68,2.64,20.57,3.72c3.44.59,6.89,1,10.35,1.56s6.92,1,10.39,1.31C337.67,629.65,344.64,630.36,351.7,631.52Z" style="fill:#592d3d"/>',
                    '<path d="M669.31,789.07c10.26-10.26,9.29-9.63,17.79-20.94-1.5-34.48-30-53.71-30-53.71L659,726.08c.84.16,7.91,18.47,7.56,46.08Z" style="fill:#E2E2E2"/>',
                    '<path d="M575.36,859.87c-5.72-24.9-22.42-29.15-22.42-29.15l3.21,19.45a96.48,96.48,0,0,1,3.9,19.14c5-2.72,10.16-5.66,15.45-8.78Z" style="fill:#E2E2E2"/>',
                    '<path d="M340.09,735.62a90.52,90.52,0,0,0,6.59,20.14A121.79,121.79,0,0,0,357,773.89l3.09,4.18c.53.68,1,1.42,1.56,2.07l1.66,2c1.13,1.31,2.19,2.68,3.35,4l3.56,3.78c.6.62,1.16,1.28,1.77,1.89l1.9,1.78,3.77,3.58c2.58,2.32,5.33,4.45,7.94,6.75l-6.28,3.32-.06-4c.05-1.32.07-2.64.2-4s.23-2.65.46-4c.11-.66.18-1.32.32-2l.43-2a43.84,43.84,0,0,1,2.52-7.67A35,35,0,0,1,385,780c.34-.6.73-1.18,1.13-1.77.21-.29.4-.57.64-.87s.42-.54.78-.95l4.46-5.06.56,6.55c.1,1.09.3,2.4.53,3.61s.51,2.46.84,3.68a48,48,0,0,0,2.51,7.14,36.29,36.29,0,0,0,3.9,6.55,29,29,0,0,0,5.62,5.42,23.79,23.79,0,0,1-7-4.07,31.32,31.32,0,0,1-5.54-6.17,43.85,43.85,0,0,1-4-7.32c-.54-1.28-1-2.58-1.46-3.91a34,34,0,0,1-1.11-4.16l5,1.49c0,.08-.22.35-.34.55s-.26.46-.39.69c-.25.48-.5,1-.73,1.48a33.23,33.23,0,0,0-1.24,3.15,44.39,44.39,0,0,0-1.62,6.69,55.25,55.25,0,0,0-.65,6.94c-.06,1.16,0,2.34,0,3.51l.16,3.53.4,8.64-6.68-5.32c-1.44-1.15-2.87-2.29-4.29-3.46l-2.14-1.75c-.7-.59-1.44-1.14-2.09-1.79l-4-3.83-2-1.91c-.64-.67-1.25-1.36-1.86-2.05l-3.67-4.15c-1.21-1.39-2.26-2.92-3.38-4.39a105.25,105.25,0,0,1-6.17-9.19,91.82,91.82,0,0,1-8.63-20.3C340.61,750.19,339.43,742.84,340.09,735.62Z" style="fill:#592d3d"/>',
                    '<path d="M638.78,724.34A5.35,5.35,0,0,1,640,726a16.7,16.7,0,0,1,.84,1.94A33.87,33.87,0,0,1,642,732a58.47,58.47,0,0,1,1.08,8.32,94.26,94.26,0,0,1-.54,16.71,109.35,109.35,0,0,1-9,32.28A90.58,90.58,0,0,1,614.3,817a70.11,70.11,0,0,1-28.51,17,111.55,111.55,0,0,0,23.91-21.31A118.63,118.63,0,0,0,626.25,786a157.47,157.47,0,0,0,10.09-30,151.49,151.49,0,0,0,2.81-15.76c.32-2.65.54-5.32.63-8a33.51,33.51,0,0,0-.08-4,14.64,14.64,0,0,0-.26-2A5.74,5.74,0,0,0,638.78,724.34Z" style="fill:#fff"/>',
                    '<path d="M262.51,621.57c22.24,43.9,7.22,72.38,35.18,124.3-7-29,2.43-55.68,2.43-55.68S310,744.78,325,780.12c7.28,23.46,69.85,61.4,103.55,81.17a86.33,86.33,0,0,1,2.32-43.58s11.89,49.36,35.91,63.71c13.43,7.58,30.15,11.89,35.13,11.89s34.53-11.58,50.92-54.5a56,56,0,0,1,7.9,30.68c22.18-12,53.39-25.68,72.45-47.65C659.52,787.15,659.52,726,659.52,726S676,748.85,669.93,789.3c61.76-68.3,54.34-143.14,71.42-175.57" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M734.38,616.77a3.8,3.8,0,0,0,1.16,1.29,4,4,0,0,0,2.15.7,3.81,3.81,0,0,0,1.68-.34h0l-.09,0-.2.11-.48.24-1,.51-2,1q-2,1-4,2c-2.69,1.32-5.41,2.57-8.13,3.81s-5.5,2.41-8.27,3.57-5.6,2.23-8.47,3.26c-1.44.51-2.89,1-4.39,1.43a39.36,39.36,0,0,1-4.75,1.15c-.47.08-.81.11-1.18.16l-1.12.13c-.74.09-1.48.16-2.23.23-1.49.14-3,.3-4.49.4a85.55,85.55,0,0,1-18.09-.43c5.86-1.58,11.62-2.89,17.37-4.29l8.59-2a35.39,35.39,0,0,0,3.81-1.36c1.31-.52,2.63-1.14,4-1.72,2.65-1.19,5.29-2.47,7.93-3.77s5.29-2.61,7.93-3.93l7.94-4,4-2,2-1,1-.48.53-.25.3-.13.16-.08.05,0a4.11,4.11,0,0,1,5.19,1.57l2.13,3.38-7.06,4.19Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    /// @dev SVG content for stubble
    function stubbleSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="stubble" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M664.05,702.32c28.31-23,54.41-54.72,70.68-86.1-.06-.1-3.49,3.38-3.55,3.28S710.11,638.28,649.66,638c-76.3-.31-60.54-21.68-152.51-21.68-81.42,0-68.49,11.89-145.15,16.15-62.09,3.45-83.62-13-83.62-13l-.2.33a261.18,261.18,0,0,0,40.56,57.53c4.32,4.65,8.86,9.18,13.48,13.48a193.3,193.3,0,0,0,15.35,13c5.18,3.95,10.67,7.72,16.33,11.21,21.71,12,46.48,21.14,73.63,27.13,6.49,1.43,13,2.64,19.31,3.6,65.81,5.85,141.08,6.7,200.74-31.12C653.21,710.78,658.75,706.63,664.05,702.32Z" style="opacity:.15"/>',
                    '<circle cx="311.27" cy="659.14" r="4.18" style="fill:#592d3d"/>',
                    '<circle cx="338.27" cy="663.32" r="2.96" style="fill:#592d3d"/>',
                    '<circle cx="400.81" cy="707.98" r="2.96" style="fill:#592d3d"/>',
                    '<circle cx="506.59" cy="711.31" r="2.96" style="fill:#592d3d"/>',
                    '<circle cx="517.39" cy="704.5" r="2.96" style="fill:#592d3d"/>',
                    '<circle cx="578.09" cy="701.54" r="2.96" style="fill:#592d3d"/>',
                    '<circle cx="581.05" cy="683.15" r="2.96" style="fill:#592d3d"/>',
                    '<circle cx="391.45" cy="690.72" r="5.37" style="fill:#592d3d"/>',
                    '<circle cx="600.21" cy="707.45" r="2.09" style="fill:#592d3d"/>',
                    '<circle cx="642.72" cy="696.08" r="4.18" style="fill:#592d3d"/>',
                    '<circle cx="462.32" cy="724.04" r="4.18" style="fill:#592d3d"/>',
                    '<circle cx="642.72" cy="663.22" r="2.96" style="fill:#592d3d"/>',
                    '<circle cx="653.82" cy="673.06" r="2.96" style="fill:#592d3d"/>'
                )
            )
        );
    }

    /// @dev Returns the SVG content for a facial hair detail
    function getFacialHairById(uint8 id) internal pure returns (string memory) {
        if (id == 0) {
            return "";
        } else if (id == 1) {
            return mediumBeardSVG();
        } else if (id == 2) {
            return stubbleSVG();
        } else {
            revert FacialHairDetail__InvalidFacialHairType();
        }
    }
}
