// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {GovernorBravoProposal} from "@forge-proposal-simulator/src/proposals/GovernorBravoProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";

contract BravoProposal_02 is GovernorBravoProposal {
    function name() public pure override returns (string memory) {
        return "BRAVO_MOCK_02";
    }

    function description() public pure override returns (string memory) {
        return "Bravo proposal mock 2";
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

    function build() public override buildModifier(addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO")) {
        /// STATICCALL -- not recorded for the run stage
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");
        Vault bravoVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        address token = addresses.getAddress("BRAVO_VAULT_TOKEN");
        (uint256 amount,) = bravoVault.deposits(address(token), timelock);

        /// CALLS -- mutative and recorded
        bravoVault.withdraw(token, payable(timelock), amount);
    }

    function validate() public view override {
        Vault bravoVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        Token token = Token(addresses.getAddress("BRAVO_VAULT_TOKEN"));

        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");

        uint256 balance = token.balanceOf(address(bravoVault));
        assertEq(balance, 0);

        (uint256 amount,) = bravoVault.deposits(address(token), address(timelock));
        assertEq(amount, 0);

        assertEq(token.balanceOf(address(timelock)), 10_000_000e18);
    }
}
