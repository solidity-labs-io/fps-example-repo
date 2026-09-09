pragma solidity ^0.8.0;

contract MockMultiSend {
    function multiSend(bytes memory transactions) external payable {
        uint256 offset;

        while (offset < transactions.length) {
            uint8 operation = uint8(transactions[offset]);
            address to = _readAddress(transactions, offset + 1);
            uint256 value = _readUint256(transactions, offset + 21);
            uint256 dataLength = _readUint256(transactions, offset + 53);
            bytes memory data = new bytes(dataLength);

            for (uint256 i = 0; i < dataLength; i++) {
                data[i] = transactions[offset + 85 + i];
            }

            bool success;
            bytes memory returndata;

            if (operation == 0) {
                (success, returndata) = to.call{value: value}(data);
            } else if (operation == 1) {
                (success, returndata) = to.delegatecall(data);
            } else {
                revert("Invalid operation");
            }

            _verifyCallResult(success, returndata);
            offset += 85 + dataLength;
        }
    }

    function _readAddress(bytes memory data, uint256 offset) internal pure returns (address value) {
        require(data.length >= offset + 20, "Read out of bounds");

        assembly {
            value := shr(96, mload(add(add(data, 0x20), offset)))
        }
    }

    function _readUint256(bytes memory data, uint256 offset) internal pure returns (uint256 value) {
        require(data.length >= offset + 32, "Read out of bounds");

        assembly {
            value := mload(add(add(data, 0x20), offset))
        }
    }

    function _verifyCallResult(bool success, bytes memory returndata) internal pure {
        if (success) return;

        assembly {
            revert(add(returndata, 0x20), mload(returndata))
        }
    }
}
