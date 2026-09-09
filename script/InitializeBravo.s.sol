pragma solidity ^0.8.0;

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";

import {MockGovernorAlpha} from "src/mocks/bravo/MockGovernorAlpha.sol";
import {Timelock} from "src/mocks/bravo/Timelock.sol";
import {GovernorBravoDelegate} from "src/mocks/bravo/GovernorBravoDelegate.sol";

/// @notice Governor Bravo initialization contract
/// DO_PRINT=false DO_BUILD=false DO_DEPLOY=true DO_VALIDATE=true forge script script/InitializeBravo.s.sol:InitializeBravo --fork-url sepolia -vvvvv
contract InitializeBravo is MultisigProposal {
    function name() public pure override returns (string memory) {
        return "INITIALIZE_GOVERNOR_BRAVO";
    }

    function description() public pure override returns (string memory) {
        return "Initialize Governor BRAVO contract";
    }

    function deploy() public override {
        address governor = addresses.getAddress("PROTOCOL_GOVERNOR");

        address payable timelock = payable(addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO"));

        if (!addresses.isAddressSet("PROTOCOL_GOVERNOR_ALPHA")) {
            // Deploy mock GovernorAlpha
            address govAlpha = address(new MockGovernorAlpha());

            addresses.addAddress("PROTOCOL_GOVERNOR_ALPHA", govAlpha, true);
        }

        Timelock(timelock)
            .executeTransaction(
                timelock,
                0,
                "",
                abi.encodeWithSignature("setPendingAdmin(address)", address(governor)),
                vm.envUint("ETA")
            );

        // Initialize GovernorBravo
        GovernorBravoDelegate(governor)._initiate(addresses.getAddress("PROTOCOL_GOVERNOR_ALPHA"));

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
        Timelock timelock = Timelock(payable(addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO")));

        // ensure governor bravo is set as timelock admin
        assertEq(timelock.admin(), addresses.getAddress("PROTOCOL_GOVERNOR"));
    }
}
