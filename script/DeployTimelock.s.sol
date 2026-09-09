pragma solidity ^0.8.0;

import {TimelockController} from "@openzeppelin/governance/TimelockController.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";

/// @notice Governor Bravo deployment contract
/// DO_PRINT=false DO_BUILD=false DO_DEPLOY=true DO_VALIDATE=true forge script script/DeployTimelock.s.sol:DeployTimelock --fork-url sepolia -vvvvv
contract DeployTimelock is MultisigProposal {
    function name() public pure override returns (string memory) {
        return "TIMELOCK_DEPLOY";
    }

    function description() public pure override returns (string memory) {
        return "Deploy TIMELOCK contract";
    }

    function deploy() public override {
        // Get proposer and executor addresses
        address dev = addresses.getAddress("DEPLOYER_EOA");

        if (!addresses.isAddressSet("OZ_GOVERNOR_GOVERNANCE_TOKEN")) {
            // Create arrays of addresses to pass to the TimelockController constructor
            address[] memory proposers = new address[](1);
            proposers[0] = dev;
            address[] memory executors = new address[](1);
            executors[0] = dev;

            // Deploy a new TimelockController
            TimelockController timelockController = new TimelockController(60, proposers, executors, address(0));

            // Add PROTOCOL_TIMELOCK address
            addresses.addAddress("PROTOCOL_TIMELOCK", address(timelockController), true);
        }

        addresses.printJSONChanges();
    }

    function run() public override {
        string memory addressesFolderPath = "./addresses";
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 11155111;

        setAddresses(new Addresses(addressesFolderPath, chainIds));

        super.run();
    }

    function validate() public view override {
        TimelockController timelockController = TimelockController(payable(addresses.getAddress("PROTOCOL_TIMELOCK")));
        address dev = addresses.getAddress("DEPLOYER_EOA");

        // ensure deployer has proposer role
        assertTrue(timelockController.hasRole(timelockController.PROPOSER_ROLE(), dev));

        // ensure deployer has executor role
        assertTrue(timelockController.hasRole(timelockController.EXECUTOR_ROLE(), dev));
    }
}
