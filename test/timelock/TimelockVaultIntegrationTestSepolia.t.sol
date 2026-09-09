pragma solidity ^0.8.0;

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";
import {TimelockPostProposalCheck} from "./TimelockPostProposalCheck.sol";

// @dev This test contract extends TimelockPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract TimelockVaultIntegrationTestSepolia is TimelockPostProposalCheck {
    function test_addTokenToWhitelist() public {
        Vault timelockVault = Vault(addresses.getAddress("TIMELOCK_VAULT"));
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK");
        Token token = new Token();

        vm.prank(timelock);

        timelockVault.whitelistToken(address(token), true);

        assertTrue(timelockVault.tokenWhitelist(address(token)), "Token should be whitelisted");
    }

    function test_depositToVault() public {
        Vault timelockVault = Vault(addresses.getAddress("TIMELOCK_VAULT"));
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK");
        address token = addresses.getAddress("TIMELOCK_TOKEN");

        (uint256 prevDeposits,) = timelockVault.deposits(address(token), timelock);
        uint256 depositAmount = 100;

        vm.startPrank(timelock);
        Token(token).mint(timelock, depositAmount);
        Token(token).approve(address(timelockVault), depositAmount);
        timelockVault.deposit(address(token), depositAmount);

        (uint256 amount,) = timelockVault.deposits(address(token), timelock);
        assertTrue(amount == prevDeposits + depositAmount, "Token should be deposited");
    }
}
