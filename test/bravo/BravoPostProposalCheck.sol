pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {GovernorBravoProposal} from "@forge-proposal-simulator/src/proposals/GovernorBravoProposal.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract BravoPostProposalCheck is Test {
    Addresses public addresses;

    function setUp() public {
        string[] memory inputs = new string[](2);
        inputs[0] = "./get-latest-proposal.sh";
        inputs[1] = "BravoProposal";

        string memory output = string(vm.ffi(inputs));

        GovernorBravoProposal bravoProposal = GovernorBravoProposal(deployCode(output));
        vm.makePersistent(address(bravoProposal));

        // Execute proposals
        bravoProposal.run();

        // Get the addresses contract
        addresses = bravoProposal.addresses();
    }
}
