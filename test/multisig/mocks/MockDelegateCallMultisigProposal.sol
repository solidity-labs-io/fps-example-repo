pragma solidity ^0.8.0;

import {MockCallOnlyMultisigProposal} from "./MockCallOnlyMultisigProposal.sol";
import {MockSafeTarget} from "./MockSafeTarget.sol";

contract MockDelegateCallMultisigProposal is MockCallOnlyMultisigProposal {
    bytes32 public delegateSlot;
    bytes32 public delegateValue;

    constructor(address _multisig, MockSafeTarget _target, bytes32 _delegateSlot, bytes32 _delegateValue)
        MockCallOnlyMultisigProposal(_multisig, _target)
    {
        delegateSlot = _delegateSlot;
        delegateValue = _delegateValue;
    }

    function name() public pure override returns (string memory) {
        return "DELEGATE_CALL_MULTISIG_MOCK";
    }

    function description() public pure override returns (string memory) {
        return "Mock delegatecall multisig proposal";
    }

    function build() public override buildModifier(multisig) {
        target.recordCall(11);
        target.writeSlot(delegateSlot, delegateValue);
        target.recordCall(22);
    }

    function isDelegateCall() public pure override returns (bool) {
        return true;
    }

    function simulate() public override {
        _simulateActions(multisig);
    }
}
