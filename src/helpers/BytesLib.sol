pragma solidity ^0.8.0;

library BytesLib {
    function decodeRecoveryArgs(
        bytes memory _calldata
    ) internal pure returns (bytes32) {
        bytes memory data = extractCalldata(_calldata);
        (bytes32 newOwner, bytes32 guradian) = abi.decode(
            data,
            (bytes32, bytes32)
        );
        return guradian;
    }

    function decodeProposeInheritanceArgs(
        bytes memory _calldata
    ) internal pure returns (bytes32) {
        bytes memory data = extractCalldata(_calldata);
        bytes32 beneficiary = abi.decode(data, (bytes32));
        return beneficiary;
    }

    function decodeExecuteInheritanceArgs(
        bytes memory _calldata
    ) internal pure returns (bytes32) {
        bytes memory data = extractCalldata(_calldata);
        (bytes32 beneficiary, uint inheritanceCount) = abi.decode(
            data,
            (bytes32, uint)
        );
        return beneficiary;
    }

    function extractCalldata(
        bytes memory _calldata
    ) internal pure returns (bytes memory) {
        bytes memory data;

        require(_calldata.length >= 4);

        assembly {
            let totalLength := mload(_calldata)
            let targetLength := sub(totalLength, 4)
            data := mload(0x40)

            mstore(data, targetLength)
            mstore(0x40, add(0x20, targetLength))
            mstore(add(data, 0x20), shl(0x20, mload(add(_calldata, 0x20))))

            for {
                let i := 0x1C
            } lt(i, targetLength) {
                i := add(i, 0x20)
            } {
                mstore(
                    add(add(data, 0x20), i),
                    mload(add(add(_calldata, 0x20), add(i, 0x04)))
                )
            }
        }

        return data;
    }

    function getSelector(bytes memory _data) internal pure returns (bytes4) {
        bytes4 selector;
        assembly {
            selector := calldataload(_data)
        }
        return selector;
    }

    // chat gpt
    function bytes32ToUint8Array(
        bytes32 b
    ) public pure returns (uint8[] memory) {
        uint8[] memory array = new uint8[](32);
        for (uint i = 0; i < 32; i++) {
            array[i] = uint8(b[i]);
        }
        return array;
    }

    function bytesToUint8Array(
        bytes memory input
    ) public pure returns (uint8[] memory) {
        uint8[] memory array = new uint8[](input.length);
        for (uint i = 0; i < input.length; i++) {
            array[i] = uint8(input[i]);
        }
        return array;
    }

    function sliceStartEnd(
        bytes memory data,
        uint start,
        uint end
    ) public pure returns (bytes memory) {
        require(start <= end && end <= data.length, "Invalid range");

        bytes memory result = new bytes(end - start);
        for (uint i = start; i < end; i++) {
            result[i - start] = data[i];
        }
        return result;
    }
}
