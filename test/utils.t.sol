// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

library Utils {
    function _oneByte(bytes memory b1) internal pure returns (bytes[] memory) {
        bytes[] memory result = new bytes[](1);
        result[0] = b1;
        return result;
    }

    function _twoBytes(bytes memory b1, bytes memory b2) internal pure returns (bytes[] memory) {
        bytes[] memory result = new bytes[](2);
        result[0] = b1;
        result[1] = b2;
        return result;
    }

    function _threeBytes(bytes memory b1, bytes memory b2, bytes memory b3) internal pure returns (bytes[] memory) {
        bytes[] memory result = new bytes[](3);
        result[0] = b1;
        result[1] = b2;
        result[2] = b3;
        return result;
    }
}
