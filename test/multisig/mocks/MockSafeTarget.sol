pragma solidity ^0.8.0;

contract MockSafeTarget {
    address public callSender;
    uint256 public callNumber;

    function recordCall(uint256 number) external {
        callSender = msg.sender;
        callNumber = number;
    }

    function writeSlot(bytes32 slot, bytes32 value) external {
        assembly {
            sstore(slot, value)
        }
    }
}
