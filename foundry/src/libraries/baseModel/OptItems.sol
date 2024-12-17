// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {SVGBody} from "src/libraries/baseModel/SVGBody.sol";
import {Colors, Errors} from "src/types/Constants.sol";
import {BytesConverter} from "src/libraries/BytesConverter.sol";

library OptItems {
    using Colors for bytes3;

    enum MaskColor {
        WHITE,
        BLUE,
        BLACK,
        GREEN,
        RED
    }

    /// @dev Retrieves the base and shadow color for a hat
    /// @param id The hat color id
    function getColorForFaceMask(uint8 id) internal pure returns (bytes3 baseColor, bytes3 shadowColor) {
        if (id == uint8(MaskColor.WHITE)) {
            return (Colors.WHITE_BASE, Colors.WHITE_SHADOW);
        } else if (id == uint8(MaskColor.BLUE)) {
            return (Colors.BLUE_BASE, Colors.BLUE_SHADOW);
        } else if (id == uint8(MaskColor.BLACK)) {
            return (Colors.BLACK_BASE, Colors.BLACK_SHADOW);
        } else if (id == uint8(MaskColor.GREEN)) {
            return (Colors.GREEN_BASE, Colors.GREEN_SHADOW);
        } else if (id == uint8(MaskColor.RED)) {
            return (Colors.RED_BASE, Colors.RED_SHADOW);
        } else {
            revert Errors.InvalidColor(id);
        }
    }

    /// @dev Retrieves the base and shadow color for a shape
    /// @param id The shape color id
    function getColorForShape(uint8 id) internal pure returns (bytes3 baseColor, bytes3 shadowColor) {
        if (id == 1) {
            return (Colors.WHITE_BASE, Colors.WHITE_SHADOW);
        } else if (id == 2) {
            return (Colors.BLUE_BASE, Colors.BLUE_SHADOW);
        } else if (id == 3) {
            return (Colors.BLACK_BASE, Colors.BLACK_SHADOW);
        } else if (id == 4) {
            return (Colors.GREEN_BASE, Colors.GREEN_SHADOW);
        } else if (id == 5) {
            return (Colors.RED_BASE, Colors.RED_SHADOW);
        } else {
            revert Errors.InvalidColor(id);
        }
    }

    /// @dev SVG for face mask
    function faceMaskSVG(uint8 id) internal pure returns (string memory) {
        (bytes3 baseColor, bytes3 shadowColor) = getColorForFaceMask(id);

        return SVGBody.fullSVG(
            'id="face-mask" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M289.63,652.2q6.38,8,13.32,15.47,6.76,7.26,14,14a204.78,204.78,0,0,0,16.07,13.62q8.34,6.34,17.24,11.82c24,13.28,49.91,22.39,76.71,28.3,6.7,1.47,13.46,2.74,20.24,3.77,69.83,6.22,147.18,6.22,208.41-32.65q8.88-6.12,17.25-12.91c15.56-12.65,28-26.65,40.9-44.33-83.93,0-138.94-94.73-207.41-94.73S367.92,652.2,289.63,652.2Z" fill=',
                    BytesConverter.bytesToHex(shadowColor),
                    " />",
                    '<path d="M291.53,666.4q6.25,7.85,13.08,15.2,6.64,7.14,13.79,13.78a199.59,199.59,0,0,0,15.8,13.38c5.46,4.16,11.12,8,16.93,11.62,23.55,13,49,22,75.37,27.8,6.59,1.45,13.23,2.7,19.89,3.71C515,758,591,758,651.16,719.81q8.73-6,16.94-12.69a268.58,268.58,0,0,0,41.39-42c-82.46,0-137.71-94.64-205-94.64S368.44,666.4,291.53,666.4Z" fill=',
                    BytesConverter.bytesToHex(baseColor),
                    " stroke=",
                    BytesConverter.bytesToHex(Colors.DEFAULT_STROKE),
                    ' strokeMiterlimit={10} strokeWidth="12px" />',
                    '<path d="M453.37,752.49l5.5.43,1.32.1c1.57.11,3.14.23,4.72.33l1.29.09,5.18.33,2,.12,5,.26,2.16.1,3.35.15,2.56.1,4.46.14,3,.08,2.41,0c1.73,0,3.46.06,5.19.08h1.91q5.58,0,11.16-.06l1.1,0c2.44,0,4.87-.11,7.3-.2h.28q6-.23,12-.62l.31,0c10.79-.73,21.53-1.92,32.13-3.68h0q4-.66,7.95-1.43c-33.29-9.82-129.24-43.29-193-117.69-29.32,19.08-59.55,35.28-91.16,35.28l.35.44,2.44,3,.75.9c.8,1,1.62,1.93,2.44,2.88l1.57,1.82.53.6c.65.74,1.31,1.49,2,2.22s1.31,1.44,2,2.16c.86.94,1.73,1.87,2.6,2.79l1.21,1.28c1.29,1.34,2.59,2.68,3.91,4l.26.27c1.29,1.28,2.6,2.55,3.91,3.81l1.58,1.5c.95.89,1.9,1.78,2.86,2.66l1.16,1.06c1,.94,2.09,1.86,3.14,2.78,1.54,1.35,3.1,2.66,4.68,3.95l.42.35q2.44,2,4.93,3.89c5.46,4.16,11.12,8,16.93,11.62a262,262,0,0,0,46.16,19.89c2.07.68,4.15,1.32,6.24,2q11.36,3.4,23,6,5.69,1.26,11.42,2.29c2.82.51,5.64,1,8.47,1.42l5.71.49Z" fill=',
                    BytesConverter.bytesToHex(shadowColor),
                    " />",
                    '<path d="M579.81,624.61c-6.52-1.65-13-3.05-19.57-4.22s-13.09-2.18-19.63-3-13.12-1.45-19.68-1.89-13.14-.64-19.71-.65h-4.93l-4.93.13c-1.64,0-3.28.11-4.92.19s-3.29.13-4.92.26c-6.57.38-13.11,1.09-19.66,1.87a398,398,0,0,0-39.21,7.32,159.22,159.22,0,0,1,38.13-13.52c3.32-.66,6.64-1.41,10-1.88,1.68-.25,3.35-.56,5-.75l5.06-.6a192.24,192.24,0,0,1,20.36-1c6.79,0,13.59.39,20.34,1.11a193.91,193.91,0,0,1,20.08,3.25,180.43,180.43,0,0,1,19.57,5.41A118.4,118.4,0,0,1,579.81,624.61Z" fill=',
                    BytesConverter.bytesToHex(Colors.DEFAULT_STROKE),
                    " />",
                    '<path d="M364.82,686.87c11.06,3.46,22.25,6.26,33.51,8.69,2.81.59,5.63,1.2,8.45,1.76s5.64,1.12,8.48,1.58c5.66,1,11.32,2,17,2.77,11.38,1.57,22.76,2.94,34.2,3.74s22.88,1.26,34.33,1.29l8.59,0,8.58-.26c2.86,0,5.72-.22,8.58-.37s5.72-.26,8.57-.53c11.43-.76,22.81-2.16,34.18-3.69a531.12,531.12,0,0,0,67.44-15A312.64,312.64,0,0,1,570.36,708c-5.73,1-11.45,2.24-17.24,3-2.89.4-5.77.88-8.67,1.19l-8.7.94c-11.63,1-23.3,1.71-35,1.61s-23.35-.61-35-1.76-23.17-2.82-34.6-5.14a342.06,342.06,0,0,1-33.87-8.46A234,234,0,0,1,364.82,686.87Z" fill=',
                    BytesConverter.bytesToHex(Colors.DEFAULT_STROKE),
                    " />",
                    '<path d="M584.88,662.69c-14.62,1.67-29.24,2.5-43.86,3.13s-29.25.86-43.87.87-29.25-.27-43.87-.86-29.24-1.47-43.86-3.14c14.62-1.68,29.24-2.51,43.86-3.15s29.25-.86,43.87-.85,29.24.28,43.87.86S570.26,661,584.88,662.69Z" fill=',
                    BytesConverter.bytesToHex(Colors.DEFAULT_STROKE),
                    " />",
                    '<path d="M291.53,666.4q6.25,7.85,13.08,15.2,6.64,7.14,13.79,13.78a199.59,199.59,0,0,0,15.8,13.38c5.46,4.16,11.12,8,16.93,11.62,23.55,13,49,22,75.37,27.8,6.59,1.45,13.23,2.7,19.89,3.71C515,758,591,758,651.16,719.81q8.73-6,16.94-12.69a268.58,268.58,0,0,0,41.39-42c-82.46,0-137.71-94.64-205-94.64S368.44,666.4,291.53,666.4Z" fill="none" stroke=',
                    BytesConverter.bytesToHex(Colors.DEFAULT_STROKE),
                    ' strokeMiterlimit={10} strokeWidth="12px" />',
                    '<path d="M673,659s48.64-10.61,84.3-88.54" fill="none" stroke=',
                    BytesConverter.bytesToHex(Colors.DEFAULT_STROKE),
                    ' strokeMiterlimit={10} strokeWidth="12px" />',
                    '<path d="M330,659.06s-53.47-13.43-87-87.61" fill="none" stroke=',
                    BytesConverter.bytesToHex(Colors.DEFAULT_STROKE),
                    ' strokeMiterlimit={10} strokeWidth="12px" />'
                )
            )
        );
    }

    /// @dev SVG for mask
    function maskSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="mask" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M1000,0H0V718.31H179.2c38.38,142.38,167.45,247.1,320.8,247.1s282.42-104.72,320.8-247.1H1000Z" fill="white"/>'
                )
            )
        );
    }

    /// @dev SVG for left lashes
    function leftLashes() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="left-lashes" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M243.89,489.13c5.64,15.83,20.9,24.06,33.4,26.94,13.06-20.24,56.65-28.92,89.37-17.44,27.8,5-10.81-25.57-72.47-9-2.31.85-14.56,2.95-30.28-9.19-2.19-1.69,4.68,13.71,12.5,20C265.06,500.21,263.2,500.22,243.89,489.13Z" fill=white fillRule="evenodd" />'
                )
            )
        );
    }

    /// @dev SVG for right lashes
    function rightLashes() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="right-lashes" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M721.21,500.43c7.82-6.25,14.69-21.65,12.5-20-15.72,12.14-28,10-30.28,9.19-61.66-16.6-100.28,14-72.48,9,32.73-11.48,76.32-2.8,89.38,17.44,12.5-2.88,27.76-11.11,33.4-26.94C734.42,500.22,732.56,500.21,721.21,500.43Z" fill=white fillRule="evenodd"/>'
                )
            )
        );
    }

    /// @dev SVG for lashes
    function lashesSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="lashes" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(abi.encodePacked(leftLashes(), rightLashes()))
        );
    }

    /// @dev SVG for shapes
    function shapeSVG(uint8 color) internal pure returns (string memory) {
        (bytes3 baseColor,) = getColorForShape(color);
        return SVGBody.fullSVG(
            'id="shapes" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<circle cx="500" cy="630.1601" r="332.441995" fill=', BytesConverter.bytesToHex(baseColor), " />"
                )
            )
        );
    }

    /// @dev Returns the SVG for the given item
    function getOptItems(uint8 id, uint8 color) internal pure returns (string memory) {
        if (id == 1) {
            return faceMaskSVG(color);
        } else if (id == 2) {
            return maskSVG();
        } else if (id == 3) {
            return lashesSVG();
        } else if (id == 4) {
            return shapeSVG(color);
        } else {
            revert Errors.InvalidType(id);
        }
    }
}
