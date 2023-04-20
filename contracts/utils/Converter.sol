// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Converter {
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < bytesArray.length; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function stringToBytes32(string memory str) public pure returns (bytes32 result) {
        bytes memory temp = bytes(str);
        assembly {
            result := mload(add(temp, 32))
        }
    }

    function getAsciiValue(string memory _str, uint _index) public pure returns (uint) {
        bytes memory strBytes = bytes(_str);
        require(_index < strBytes.length, "Index out of bounds");

        // Convert character to ASCII value
        uint asciiValue = uint8(strBytes[_index]);

        return asciiValue;
    }
}
