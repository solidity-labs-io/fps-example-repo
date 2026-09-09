pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {TimelockProposal} from "@forge-proposal-simulator/src/proposals/TimelockProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract TimelockPostProposalCheck is Test {
    Addresses public addresses;

    function setUp() public {
        string[] memory inputs = new string[](2);
        inputs[0] = "./get-latest-proposal.sh";
        inputs[1] = "TimelockProposal";

        string memory output = string(vm.ffi(inputs));

        TimelockProposal timelockProposal = TimelockProposal(deployCode(output));
        vm.makePersistent(address(timelockProposal));

        // Execute proposals
        timelockProposal.run();

        // Get the addresses contract
        addresses = timelockProposal.addresses();
    }
}
