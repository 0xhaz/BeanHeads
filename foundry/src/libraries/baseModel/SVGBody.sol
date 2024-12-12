// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

library SVGBody {
    /// @dev Generates a full SVG document with the provided content
    /// @param attributes The attributes for the <svg> tag (e.g., 'xmlns="http://www.w3.org/2000/svg"')
    /// @param children Nested SVG content
    function fullSVG(string memory attributes, string memory children) internal pure returns (string memory) {
        return string(abi.encodePacked("<svg ", attributes, ">", children, "</svg>"));
    }

    /// @dev Generates an SVG Wrapper for a component
    /// @param tag the SVG tag (e.g., "g", "circle", etc)
    /// @param attributes The attributes for the tag (e.g, 'id="group1")
    /// @param children Nested SVG content
    function base(string memory tag, string memory attributes, string memory children)
        internal
        pure
        returns (string memory)
    {
        string memory openingTag = bytes(attributes).length > 0
            ? string(abi.encodePacked("<", tag, " ", attributes, ">"))
            : string(abi.encodePacked("<", tag, ">"));

        return string(abi.encodePacked(openingTag, children, "</", tag, ">"));
    }
}
