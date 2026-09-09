pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {OZGovernorProposal} from "@forge-proposal-simulator/src/proposals/OZGovernorProposal.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract OZGovernorPostProposalCheck is Test {
    Addresses public addresses;

    function setUp() public {
        string[] memory inputs = new string[](2);
        inputs[0] = "./get-latest-proposal.sh";
        inputs[1] = "OZGovernorProposal";

        string memory output = string(vm.ffi(inputs));

        OZGovernorProposal ozGovernorproposal = OZGovernorProposal(deployCode(output));
        vm.makePersistent(address(ozGovernorproposal));

        // Execute proposals
        ozGovernorproposal.run();

        // Get the addresses contract
        addresses = ozGovernorproposal.addresses();
    }
}
