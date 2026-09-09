pragma solidity ^0.8.0;

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";

import {TimelockController} from "@openzeppelin/governance/TimelockController.sol";

import {MockERC20Votes} from "src/mocks/governor-oz/MockERC20Votes.sol";
import {MockOZGovernor} from "src/mocks/governor-oz/MockOZGovernor.sol";

/// @notice OZ Governor deployment contract
/// DO_PRINT=false DO_BUILD=false DO_DEPLOY=true DO_VALIDATE=true forge script script/DeployOZGovernor.s.sol:DeployOZGovernor --fork-url sepolia -vvvvv
contract DeployOZGovernor is MultisigProposal {
    function name() public pure override returns (string memory) {
        return "OZ_GOVERNOR_DEPLOY";
    }

    function description() public pure override returns (string memory) {
        return "Deploy OZ Governor contract";
    }

    function deploy() public override {
        // Get proposer and executor addresses
        address dev = addresses.getAddress("DEPLOYER_EOA");

        if (!addresses.isAddressSet("OZ_GOVERNOR_TIMELOCK")) {
            // Create arrays of addresses to pass to the TimelockController constructor
            address[] memory proposers = new address[](1);
            proposers[0] = dev;
            address[] memory executors = new address[](1);
            executors[0] = address(0);

            // Deploy a new TimelockController
            TimelockController timelock = new TimelockController(60, proposers, executors, dev);

            // Add OZ_GOVERNOR_TIMELOCK address
            addresses.addAddress("OZ_GOVERNOR_TIMELOCK", address(timelock), true);
        }

        if (!addresses.isAddressSet("OZ_GOVERNOR_GOVERNANCE_TOKEN")) {
            // Deploy the governance token
            MockERC20Votes govToken = new MockERC20Votes("Governance Token", "GOV");

            govToken.mint(dev, 1e21);

            // Add OZ_GOVERNOR_GOVERNANCE_TOKEN address
            addresses.addAddress("OZ_GOVERNOR_GOVERNANCE_TOKEN", address(govToken), true);
        }

        if (!addresses.isAddressSet("OZ_GOVERNOR")) {
            // Deploy MockOZGovernor
            MockOZGovernor governor = new MockOZGovernor(
                MockERC20Votes(addresses.getAddress("OZ_GOVERNOR_GOVERNANCE_TOKEN")), // governance token
                TimelockController(payable(addresses.getAddress("OZ_GOVERNOR_TIMELOCK"))) // timelock
            );

            // Add OZ_GOVERNOR address
            addresses.addAddress("OZ_GOVERNOR", address(governor), true);
        }

        // add propose and execute role for governor
        TimelockController(payable(addresses.getAddress("OZ_GOVERNOR_TIMELOCK")))
            .grantRole(keccak256("PROPOSER_ROLE"), addresses.getAddress("OZ_GOVERNOR"));

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
        MockERC20Votes govToken = MockERC20Votes(addresses.getAddress("OZ_GOVERNOR_GOVERNANCE_TOKEN"));

        // ensure governance token is minted to deployer address
        assertEq(govToken.balanceOf(addresses.getAddress("DEPLOYER_EOA")), 1e21);

        TimelockController timelock = TimelockController(payable(addresses.getAddress("OZ_GOVERNOR_TIMELOCK")));

        // ensure OZ Governor has been granted proposer role on timelock
        assertTrue(timelock.hasRole(keccak256("PROPOSER_ROLE"), addresses.getAddress("OZ_GOVERNOR")));
    }
}
