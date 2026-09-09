pragma solidity ^0.8.0;

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {GovernorBravoDelegator} from "@comp-governance/GovernorBravoDelegator.sol";
import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";

import {MockERC20Votes} from "src/mocks/bravo/MockERC20Votes.sol";
import {Timelock} from "src/mocks/bravo/Timelock.sol";
import {GovernorBravoDelegate} from "src/mocks/bravo/GovernorBravoDelegate.sol";

/// @notice Governor Bravo deployment contract
/// DO_PRINT=false DO_BUILD=false DO_DEPLOY=true DO_VALIDATE=true forge script script/DeployGovernorBravo.s.sol:DeployGovernorBravo --fork-url sepolia -vvvvv
contract DeployGovernorBravo is MultisigProposal {
    function name() public pure override returns (string memory) {
        return "GOVERNOR_BRAVO_DEPLOY";
    }

    function description() public pure override returns (string memory) {
        return "Deploy Governor BRAVO contract";
    }

    function deploy() public override {
        address deployer = addresses.getAddress("DEPLOYER_EOA");

        if (!addresses.isAddressSet("PROTOCOL_TIMELOCK_BRAVO")) {
            // Deploy and configure the timelock
            Timelock timelock = new Timelock(deployer, 1);

            // Add PROTOCOL_TIMELOCK_BRAVO address
            addresses.addAddress("PROTOCOL_TIMELOCK_BRAVO", address(timelock), true);
        }

        if (!addresses.isAddressSet("PROTOCOL_GOVERNANCE_TOKEN")) {
            // Deploy the governance token
            MockERC20Votes govToken = new MockERC20Votes("Governance Token", "GOV");

            govToken.mint(deployer, 1e21);

            // Add PROTOCOL_GOVERNANCE_TOKEN address
            addresses.addAddress("PROTOCOL_GOVERNANCE_TOKEN", address(govToken), true);
        }

        if (!addresses.isAddressSet("PROTOCOL_GOVERNOR")) {
            // Deploy the GovernorBravoDelegate implementation
            GovernorBravoDelegate implementation = new GovernorBravoDelegate();

            // Deploy and configure the GovernorBravoDelegator
            GovernorBravoDelegator governor = new GovernorBravoDelegator(
                addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO"), // timelock
                addresses.getAddress("PROTOCOL_GOVERNANCE_TOKEN"), // governance token
                deployer, // admin
                address(implementation), // implementation
                60, // voting period
                1, // voting delay
                1e21 // proposal threshold
            );

            // Add PROTOCOL_GOVERNOR address
            addresses.addAddress("PROTOCOL_GOVERNOR", address(governor), true);
        }

        Timelock(payable(addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO")))
            .queueTransaction(
                addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO"),
                0,
                "",
                abi.encodeWithSignature("setPendingAdmin(address)", addresses.getAddress("PROTOCOL_GOVERNOR")),
                block.timestamp + 180
            );

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
        MockERC20Votes govToken = MockERC20Votes(addresses.getAddress("PROTOCOL_GOVERNANCE_TOKEN"));

        // ensure governance token is minted to deployer address
        assertEq(govToken.balanceOf(addresses.getAddress("DEPLOYER_EOA")), 1e21);
    }
}
