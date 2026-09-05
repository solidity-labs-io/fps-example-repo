pragma solidity ^0.8.0;

import {MockCallOnlyMultisigProposal} from "./MockCallOnlyMultisigProposal.sol";
import {MockSafeTarget} from "./MockSafeTarget.sol";

contract MockMixedOperationMultisigProposal is MockCallOnlyMultisigProposal {
    bytes32 public delegateSlot;
    bytes32 public delegateValue;

    constructor(address _multisig, MockSafeTarget _target, bytes32 _delegateSlot, bytes32 _delegateValue)
        MockCallOnlyMultisigProposal(_multisig, _target)
    {
        delegateSlot = _delegateSlot;
        delegateValue = _delegateValue;
    }

    function name() public pure override returns (string memory) {
        return "MIXED_OPERATION_MULTISIG_MOCK";
    }

    function description() public pure override returns (string memory) {
        return "Mock mixed-operation multisig proposal";
    }

    function build() public override buildModifier(multisig) {
        target.recordCall(11);
        target.writeSlot(delegateSlot, delegateValue);
        target.recordCall(22);
    }

    function isDelegateCall(uint256 actionIndex) public pure override returns (bool) {
        return actionIndex == 1;
    }

    function simulate() public override {
        _simulateActions(multisig);
    }
}
