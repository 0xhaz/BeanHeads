// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

library BytesConverter {
    /// @dev Converts bytes3 to a string for the color
    function bytesToHex(bytes3 color) internal pure returns (string memory) {
        bytes memory buffer = new bytes(7);
        buffer[0] = "#";
        for (uint256 i; i < 3; ++i) {
            uint8 value = uint8(color[i]);
            buffer[2 * i + 1] = _toHexChar(value >> 4);
            buffer[2 * i + 2] = _toHexChar(value & 0x0f);
        }
        return string(buffer);
    }

    /// @dev Helper to convert uint8 to hex char
    function _toHexChar(uint8 value) private pure returns (bytes1) {
        return bytes1(value < 10 ? value + 48 : value + 87);
    }
}
