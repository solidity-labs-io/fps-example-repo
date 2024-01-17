pragma solidity ^0.8.0;

import { TimelockProposal } from "@forge-proposal-simulator/proposals/TimelockProposal.sol";
import { Addresses } from "@forge-proposal-simulator/addresses/Addresses.sol";
import { Vault } from "@forge-proposal-simulator/examples/Vault.sol";
import { MockToken } from "@forge-proposal-simulator/examples/MockToken.sol";

// TIMELOCK_01 proposal deploys a Vault contract and an ERC20 token contract
// Then the proposal transfers ownership of both Vault and ERC20 to the timelock address
// Finally the proposal whitelist the ERC20 token in the Vault contract
contract TIMELOCK_01 is TimelockProposal {
    // Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "TIMELOCK_01";
    }

    // Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "Timelock proposal mock";
    }

    // Deploys a vault contract and an ERC20 token contract.
    function _deploy(Addresses addresses, address) internal override {
        // Deploy needed contracts
        Vault timelockVault = new Vault();
        MockToken token = new MockToken();

        // Add deployed contracts to the address registry
        addresses.addAddress("VAULT", address(timelockVault));
        addresses.addAddress("TOKEN_1", address(token));
    }

    // Transfers vault ownership to timelock.
    // Transfer token ownership to timelock.
    // Transfers all tokens to timelock.
    function _afterDeploy(
        Addresses addresses,
        address deployer
    ) internal override {
        // Get needed addresses from addresses registry
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK");
        Vault timelockVault = Vault(addresses.getAddress("VAULT"));
        MockToken token = MockToken(addresses.getAddress("TOKEN_1"));

        // Transfer ownership of the contracts to the multisig address
        timelockVault.transferOwnership(timelock);
        token.transferOwnership(timelock);

        // Transfer tokens from deployer to multisig address
        token.transfer(timelock, token.balanceOf(address(deployer)));
    }

    // Sets up actions for the proposal, in this case, setting the MockToken to active.
    function _build(Addresses addresses) internal override {
        // Get vault and token addresses (deployed on _deploy step)
        address timelockVault = addresses.getAddress("VAULT");
        address token = addresses.getAddress("TOKEN_1");

        // Push action to whitelist the MockToken
        _pushAction(
            timelockVault,
            abi.encodeWithSignature(
                "whitelistToken(address,bool)",
                token,
                true
            ),
            "Set token to active"
        );
    }

    // Executes the proposal actions.
    function _run(Addresses addresses, address) internal override {
        // Call parent _run function to check if there are actions to execute
        super._run(addresses, address(0));

        // Get needed addresses from addresses registry
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK");
        address proposer = addresses.getAddress("TIMELOCK_PROPOSER");
        address executor = addresses.getAddress("TIMELOCK_EXECUTOR");

        // Simulates actions on TimelockController
        _simulateActions(timelock, proposer, executor);
    }

    // Validates the post-execution state.
    function _validate(Addresses addresses, address) internal override {
        // Get needed addresses from addresses registry
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK");
        Vault timelockVault = Vault(addresses.getAddress("VAULT"));
        MockToken token = MockToken(addresses.getAddress("TOKEN_1"));

        // Validate post-execution state
        // Vault ownership should be transferred to timelock
        assertEq(timelockVault.owner(), timelock);
        // Token should be whitelisted on the Vault contract
        assertTrue(timelockVault.tokenWhitelist(address(token)));
        // Vault should not be paused
        assertFalse(timelockVault.paused());
        // Token ownership should be transferred to timelock
        assertEq(token.owner(), timelock);
        // Token balance of multisig should be equal to total supply
        assertEq(token.balanceOf(timelock), token.totalSupply());
    }
}
