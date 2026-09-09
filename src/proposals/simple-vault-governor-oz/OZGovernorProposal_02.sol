// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {OZGovernorProposal} from "@forge-proposal-simulator/src/proposals/OZGovernorProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";

contract OZGovernorProposal_02 is OZGovernorProposal {
    function name() public pure override returns (string memory) {
        return "OZ_GOVERNOR_PROPOSAL_02";
    }

    function description() public pure override returns (string memory) {
        return "OZ Governor proposal mock 2";
    }

    function run() public override {
        setPrimaryForkId(vm.createSelectFork("sepolia"));

        string memory addressesFolderPath = "./addresses";
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 11155111;

        setAddresses(new Addresses(addressesFolderPath, chainIds));

        setGovernor(addresses.getAddress("OZ_GOVERNOR"));

        super.run();
    }

    function build() public override buildModifier(addresses.getAddress("OZ_GOVERNOR_TIMELOCK")) {
        /// STATICCALL -- not recorded for the run stage
        address timelock = addresses.getAddress("OZ_GOVERNOR_TIMELOCK");
        Vault ozGovernorVault = Vault(addresses.getAddress("OZ_GOVERNOR_VAULT"));
        address token = addresses.getAddress("OZ_GOVERNOR_VAULT_TOKEN");
        (uint256 amount,) = ozGovernorVault.deposits(address(token), timelock);

        /// CALLS -- mutative and recorded
        ozGovernorVault.withdraw(token, payable(timelock), amount);
    }

    function validate() public view override {
        Vault ozGovernorVault = Vault(addresses.getAddress("OZ_GOVERNOR_VAULT"));
        Token token = Token(addresses.getAddress("OZ_GOVERNOR_VAULT_TOKEN"));

        address timelock = addresses.getAddress("OZ_GOVERNOR_TIMELOCK");

        uint256 balance = token.balanceOf(address(ozGovernorVault));
        assertEq(balance, 0);

        (uint256 amount,) = ozGovernorVault.deposits(address(token), address(timelock));
        assertEq(amount, 0);

        assertEq(token.balanceOf(address(timelock)), 10_000_000e18);
    }
}
