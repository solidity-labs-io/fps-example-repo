// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title MockArbSys
/// @notice a mocked version of the Arbitrum pre-compiled system contract, add additional methods as needed
contract MockArbSys {
    uint256 public ticketId;

    function sendTxToL1(address _l1Target, bytes memory _data) external payable returns (uint256) {
        (bool success,) = _l1Target.call(_data);
        require(success, "Arbsys: sendTxToL1 failed");
        return ++ticketId;
    }
}
