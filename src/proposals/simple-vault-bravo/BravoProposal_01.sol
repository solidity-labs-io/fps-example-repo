// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {GovernorBravoProposal} from "@forge-proposal-simulator/src/proposals/GovernorBravoProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";

contract BravoProposal_01 is GovernorBravoProposal {
    function name() public pure override returns (string memory) {
        return "BRAVO_MOCK";
    }

    function description() public pure override returns (string memory) {
        return "Bravo proposal mock";
    }

    function run() public override {
        setPrimaryForkId(vm.createSelectFork("sepolia"));

        string memory addressesFolderPath = "./addresses";
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 11155111;

        setAddresses(new Addresses(addressesFolderPath, chainIds));

        setGovernor(addresses.getAddress("PROTOCOL_GOVERNOR"));

        super.run();
    }

    function deploy() public override {
        address owner = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");
        if (!addresses.isAddressSet("BRAVO_VAULT")) {
            Vault bravoVault = new Vault();

            addresses.addAddress("BRAVO_VAULT", address(bravoVault), true);
            bravoVault.transferOwnership(owner);
        }

        if (!addresses.isAddressSet("BRAVO_VAULT_TOKEN")) {
            Token token = new Token();
            addresses.addAddress("BRAVO_VAULT_TOKEN", address(token), true);
            token.transferOwnership(owner);

            // During forge script execution, the deployer of the contracts is
            // the DEPLOYER_EOA. However, when running through forge test, the deployer of the contracts is this contract.
            uint256 balance = token.balanceOf(address(this)) > 0
                ? token.balanceOf(address(this))
                : token.balanceOf(addresses.getAddress("DEPLOYER_EOA"));

            token.transfer(address(owner), balance);
        }
    }

    function build() public override buildModifier(addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO")) {
        /// STATICCALL -- not recorded for the run stage
        address bravoVault = addresses.getAddress("BRAVO_VAULT");
        address token = addresses.getAddress("BRAVO_VAULT_TOKEN");
        uint256 balance = Token(token).balanceOf(addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO"));

        Vault(bravoVault).whitelistToken(token, true);

        /// CALLS -- mutative and recorded
        Token(token).approve(bravoVault, balance);
        Vault(bravoVault).deposit(token, balance);
    }

    function validate() public view override {
        Vault bravoVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        Token token = Token(addresses.getAddress("BRAVO_VAULT_TOKEN"));

        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");

        uint256 balance = token.balanceOf(address(bravoVault));
        (uint256 amount,) = bravoVault.deposits(address(token), address(timelock));
        assertEq(amount, balance);

        assertTrue(bravoVault.tokenWhitelist(address(token)));

        assertEq(token.balanceOf(address(bravoVault)), token.totalSupply());

        assertEq(token.totalSupply(), 10_000_000e18);

        assertEq(token.owner(), address(timelock));

        assertEq(bravoVault.owner(), address(timelock));

        assertFalse(bravoVault.paused());
    }
}
