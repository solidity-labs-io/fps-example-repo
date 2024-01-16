pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {MULTISIG_01} from "proposals/MULTISIG_01.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {TestSuite} from "@forge-proposal-simulator/test/TestSuite.t.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract MultisigPostProposalCheck is Test {
    string public constant ADDRESSES_PATH = "./addresses/Addresses.json";
    TestSuite public suite;
    Addresses public addresses;
    bytes public constant SAFE_BYTECODE =
        hex"608060405273ffffffffffffffffffffffffffffffffffffffff600054167fa619486e0000000000000000000000000000000000000000000000000000000060003514156050578060005260206000f35b3660008037600080366000845af43d6000803e60008114156070573d6000fd5b3d6000f3fea2646970667358221220d1429297349653a4918076d650332de1a1068c5f3e07c5c82360c277770b955264736f6c63430007060033";

    function setUp() public virtual {
        // Create proposals contracts
        MULTISIG_01 multisigProposal = new MULTISIG_01();

        // Populate addresses array
        address[] memory proposalsAddresses = new address[](1);
        proposalsAddresses[0] = address(multisigProposal);

        // Deploy TestSuite contract
        suite = new TestSuite(ADDRESSES_PATH, proposalsAddresses);

        // Get addresses object
        addresses = suite.addresses();

        // Set safe bytecode to multisig address
        vm.etch(addresses.getAddress("DEV_MULTISIG"), SAFE_BYTECODE);

        suite.setDebug(true);
        // Execute proposals
        suite.testProposals();

        // Proposals execution may change addresses, so we need to update the addresses object.
        addresses = suite.addresses();
    }
}
