pragma solidity ^0.8.0;

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";
import {BravoPostProposalCheck} from "./BravoPostProposalCheck.sol";

// @dev This test contract extends BravoPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract BravoVaultIntegrationTestSepolia is BravoPostProposalCheck {
    function test_addTokenToWhitelist() public {
        Vault governorVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");
        Token token = new Token();

        vm.prank(timelock);

        governorVault.whitelistToken(address(token), true);

        assertTrue(governorVault.tokenWhitelist(address(token)), "Token should be whitelisted");
    }

    function test_depositToVault() public {
        Vault governorVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");
        address token = addresses.getAddress("BRAVO_VAULT_TOKEN");
        (uint256 prevDeposit,) = governorVault.deposits(token, timelock);
        uint256 depositAmount = 100;

        vm.startPrank(timelock);
        Token(token).mint(timelock, depositAmount);
        Token(token).approve(address(governorVault), depositAmount);
        governorVault.deposit(address(token), depositAmount);

        (uint256 amount,) = governorVault.deposits(token, timelock);
        assertTrue(amount == (prevDeposit + depositAmount), "Token should be deposited");
    }
}
