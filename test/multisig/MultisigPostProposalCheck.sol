pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract MultisigPostProposalCheck is Test {
    Addresses public addresses;

    function setUp() public virtual {
        string[] memory inputs = new string[](2);
        inputs[0] = "./get-latest-proposal.sh";
        inputs[1] = "MultisigProposal";

        string memory output = string(vm.ffi(inputs));

        MultisigProposal multisigProposal = MultisigProposal(deployCode(output));
        vm.makePersistent(address(multisigProposal));

        // Execute proposals
        multisigProposal.run();

        addresses = multisigProposal.addresses();
    }
}
