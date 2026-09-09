pragma solidity ^0.8.0;

import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";
import {MockSafeTarget} from "./MockSafeTarget.sol";

contract MockCallOnlyMultisigProposal is MultisigProposal {
    address public multisig;
    MockSafeTarget public target;

    constructor(address _multisig, MockSafeTarget _target) {
        multisig = _multisig;
        target = _target;
    }

    function name() public pure virtual override returns (string memory) {
        return "CALL_ONLY_MULTISIG_MOCK";
    }

    function description() public pure virtual override returns (string memory) {
        return "Mock call-only multisig proposal";
    }

    function build() public virtual override buildModifier(multisig) {
        target.recordCall(11);
        target.recordCall(22);
    }
}
