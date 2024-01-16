pragma solidity ^0.8.0;

import {ScriptSuite} from "@forge-proposal-simulator/script/ScriptSuite.s.sol";
import {MULTISIG_01} from "proposals/MULTISIG_01.sol";

// @notice MultisigScript is a script that run MULTISIG_01 proposal
// MULTISIG_01 proposal deploys a Vault contract and an ERC20 token contract
// Then the proposal transfers ownership of both Vault and ERC20 to the multisig address
// Finally the proposal whitelist the ERC20 token in the Vault contract
// @dev Use this script to simulates or run a single proposal
// Use this as a template to create your own script
// `forge script script/Multisig.s.sol:MultisigScript -vvvv --rpc-url {rpc} --broadcast --verify --etherscan-api-key {key}`
contract MultisigScript is ScriptSuite {
    string public constant ADDRESSES_PATH = "./addresses/addresses.json";

    constructor() ScriptSuite(ADDRESSES_PATH, new MULTISIG_01()) {}

    bytes public constant SAFE_BYTECODE =
        hex"608060405273ffffffffffffffffffffffffffffffffffffffff600054167fa619486e0000000000000000000000000000000000000000000000000000000060003514156050578060005260206000f35b3660008037600080366000845af43d6000803e60008114156070573d6000fd5b3d6000f3fea2646970667358221220d1429297349653a4918076d650332de1a1068c5f3e07c5c82360c277770b955264736f6c63430007060033";

    function run() public override {
        proposal.setDebug(true);

        /// only set the safe bytecode if testing locally
        if (block.chainid == 31337) {
            // Set Gnosis Safe bytecode
            vm.etch(addresses.getAddress("DEV_MULTISIG"), SAFE_BYTECODE);
        }

        // Execute proposal
        super.run();
    }
}
