// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {OZGovernorProposal} from "@forge-proposal-simulator/src/proposals/OZGovernorProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";

contract OZGovernorProposal_01 is OZGovernorProposal {
    function name() public pure override returns (string memory) {
        return "OZ_GOVERNOR_PROPOSAL";
    }

    function description() public pure override returns (string memory) {
        return "OZ Governor proposal mock 1";
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

    function deploy() public override {
        address owner = addresses.getAddress("OZ_GOVERNOR_TIMELOCK");
        if (!addresses.isAddressSet("OZ_GOVERNOR_VAULT")) {
            Vault ozGovernorVault = new Vault();

            addresses.addAddress("OZ_GOVERNOR_VAULT", address(ozGovernorVault), true);
            ozGovernorVault.transferOwnership(owner);
        }

        if (!addresses.isAddressSet("OZ_GOVERNOR_VAULT_TOKEN")) {
            Token token = new Token();
            addresses.addAddress("OZ_GOVERNOR_VAULT_TOKEN", address(token), true);
            token.transferOwnership(owner);

            // During forge script execution, the deployer of the contracts is
            // the DEPLOYER_EOA. However, when running through forge test, the deployer of the contracts is this contract.
            uint256 balance = token.balanceOf(address(this)) > 0
                ? token.balanceOf(address(this))
                : token.balanceOf(addresses.getAddress("DEPLOYER_EOA"));

            token.transfer(address(owner), balance);
        }
    }

    function build() public override buildModifier(addresses.getAddress("OZ_GOVERNOR_TIMELOCK")) {
        /// STATICCALL -- not recorded for the run stage
        address ozGovernorVault = addresses.getAddress("OZ_GOVERNOR_VAULT");
        address token = addresses.getAddress("OZ_GOVERNOR_VAULT_TOKEN");
        uint256 balance = Token(token).balanceOf(addresses.getAddress("OZ_GOVERNOR_TIMELOCK"));

        /// CALLS -- mutative and recorded
        Vault(ozGovernorVault).whitelistToken(token, true);
        Token(token).approve(ozGovernorVault, balance);
        Vault(ozGovernorVault).deposit(token, balance);
    }

    function validate() public view override {
        Vault ozGovernorVault = Vault(addresses.getAddress("OZ_GOVERNOR_VAULT"));
        Token token = Token(addresses.getAddress("OZ_GOVERNOR_VAULT_TOKEN"));

        address timelock = addresses.getAddress("OZ_GOVERNOR_TIMELOCK");

        uint256 balance = token.balanceOf(address(ozGovernorVault));
        (uint256 amount,) = ozGovernorVault.deposits(address(token), address(timelock));
        assertEq(amount, balance);

        assertTrue(ozGovernorVault.tokenWhitelist(address(token)));

        assertEq(token.balanceOf(address(ozGovernorVault)), token.totalSupply());

        assertEq(token.totalSupply(), 10_000_000e18);

        assertEq(token.owner(), address(timelock));

        assertEq(ozGovernorVault.owner(), address(timelock));

        assertFalse(ozGovernorVault.paused());
    }
}
