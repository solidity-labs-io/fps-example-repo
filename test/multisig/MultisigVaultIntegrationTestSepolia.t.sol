pragma solidity ^0.8.0;

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";
import {MultisigPostProposalCheck} from "./MultisigPostProposalCheck.sol";

// @dev This test contract inherits MultisigPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract MultisigVaultIntegrationTestSepolia is MultisigPostProposalCheck {
    // Tests adding a token to the whitelist in the Vault contract
    function test_addTokenToWhitelist() public {
        // Retrieves the Vault instance using its address from the Addresses contract
        Vault multisigVault = Vault(addresses.getAddress("MULTISIG_VAULT"));
        // Retrieves the address of the multisig wallet
        address multisig = addresses.getAddress("DEV_MULTISIG");
        // Creates a new instance of Token
        Token token = new Token();

        // Sets the next caller of the function to be the multisig address
        vm.prank(multisig);

        // Whitelists the newly created token in the Vault
        multisigVault.whitelistToken(address(token), true);

        // Asserts that the token is successfully whitelisted
        assertTrue(multisigVault.tokenWhitelist(address(token)), "Token should be whitelisted");
    }

    // Tests deposit functionality in the Vault contract
    function test_depositToVault() public {
        // Retrieves the Vault instance using its address from the Addresses contract
        Vault multisigVault = Vault(addresses.getAddress("MULTISIG_VAULT"));
        // Retrieves the address of the multisig wallet
        address multisig = addresses.getAddress("DEV_MULTISIG");
        // Retrieves the address of the token to be deposited
        address token = addresses.getAddress("MULTISIG_TOKEN");

        (uint256 prevDeposits,) = multisigVault.deposits(address(token), multisig);

        uint256 depositAmount = 100;

        // Starts a prank session with the multisig address as the caller
        vm.startPrank(multisig);
        // Mints 100 tokens to the multisig contract's address
        Token(token).mint(multisig, depositAmount);
        // Approves the Vault to spend depositAmount tokens
        Token(token).approve(address(multisigVault), depositAmount);
        // Deposits depositAmount tokens into the Vault
        multisigVault.deposit(address(token), depositAmount);

        // Retrieves the deposit amount of the token in the Vault for the multisig address
        (uint256 amount,) = multisigVault.deposits(address(token), multisig);
        // Asserts that the deposit amount is equal to previous deposit + depositAmount
        assertTrue(amount == prevDeposits + depositAmount, "Token should be deposited");
    }
}
