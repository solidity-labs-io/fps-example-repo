pragma solidity ^0.8.0;

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";
import {OZGovernorPostProposalCheck} from "./OZGovernorPostProposalCheck.sol";

// @dev This test contract extends OZGovernorPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract OZGovernorVaultIntegrationTestSepolia is OZGovernorPostProposalCheck {
    function test_addTokenToWhitelist() public {
        Vault ozGovernorVault = Vault(addresses.getAddress("OZ_GOVERNOR_VAULT"));
        address ozGovernorTimelock = addresses.getAddress("OZ_GOVERNOR_TIMELOCK");
        Token token = new Token();

        vm.prank(ozGovernorTimelock);

        ozGovernorVault.whitelistToken(address(token), true);

        assertTrue(ozGovernorVault.tokenWhitelist(address(token)), "Token should be whitelisted");
    }

    function test_depositToVault() public {
        Vault ozGovernorVault = Vault(addresses.getAddress("OZ_GOVERNOR_VAULT"));
        address ozGovernorTimelock = addresses.getAddress("OZ_GOVERNOR_TIMELOCK");
        address governanceToken = addresses.getAddress("OZ_GOVERNOR_VAULT_TOKEN");
        (uint256 prevDeposit,) = ozGovernorVault.deposits(governanceToken, ozGovernorTimelock);
        uint256 depositAmount = 100;

        vm.startPrank(ozGovernorTimelock);
        Token(governanceToken).mint(ozGovernorTimelock, depositAmount);
        Token(governanceToken).approve(address(ozGovernorVault), depositAmount);
        ozGovernorVault.deposit(address(governanceToken), depositAmount);

        (uint256 amount,) = ozGovernorVault.deposits(governanceToken, ozGovernorTimelock);
        assertTrue(amount == (prevDeposit + depositAmount), "Token should be deposited");
    }
}
