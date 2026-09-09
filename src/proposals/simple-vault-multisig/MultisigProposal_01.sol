pragma solidity ^0.8.0;

import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";

contract MultisigProposal_01 is MultisigProposal {
    function name() public pure override returns (string memory) {
        return "MULTISIG_MOCK";
    }

    function description() public pure override returns (string memory) {
        return "Multisig proposal mock";
    }

    function run() public override {
        setPrimaryForkId(vm.createSelectFork("sepolia"));

        string memory addressesFolderPath = "./addresses";
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 11155111;

        setAddresses(new Addresses(addressesFolderPath, chainIds));

        super.run();
    }

    function deploy() public override {
        address multisig = addresses.getAddress("DEV_MULTISIG");
        if (!addresses.isAddressSet("MULTISIG_VAULT")) {
            Vault multisigVault = new Vault();

            addresses.addAddress("MULTISIG_VAULT", address(multisigVault), true);

            multisigVault.transferOwnership(multisig);
        }

        if (!addresses.isAddressSet("MULTISIG_TOKEN")) {
            Token token = new Token();
            addresses.addAddress("MULTISIG_TOKEN", address(token), true);
            token.transferOwnership(multisig);

            // During forge script execution, the deployer of the contracts is
            // the DEPLOYER_EOA. However, when running through forge test, the deployer of the contracts is this contract.
            uint256 balance = token.balanceOf(address(this)) > 0
                ? token.balanceOf(address(this))
                : token.balanceOf(addresses.getAddress("DEPLOYER_EOA"));

            token.transfer(multisig, balance);
        }
    }

    function build() public override buildModifier(addresses.getAddress("DEV_MULTISIG")) {
        address multisig = addresses.getAddress("DEV_MULTISIG");

        /// STATICCALL -- not recorded for the run stage
        address multisigVault = addresses.getAddress("MULTISIG_VAULT");
        address token = addresses.getAddress("MULTISIG_TOKEN");
        uint256 balance = Token(token).balanceOf(address(multisig));

        Vault(multisigVault).whitelistToken(token, true);

        /// CALLS -- mutative and recorded
        Token(token).approve(multisigVault, balance);
        Vault(multisigVault).deposit(token, balance);
    }

    function simulate() public override {
        address multisig = addresses.getAddress("DEV_MULTISIG");

        _simulateActions(multisig);
    }

    function validate() public view override {
        Vault multisigVault = Vault(addresses.getAddress("MULTISIG_VAULT"));
        Token token = Token(addresses.getAddress("MULTISIG_TOKEN"));
        address multisig = addresses.getAddress("DEV_MULTISIG");

        uint256 balance = token.balanceOf(address(multisigVault));
        (uint256 amount,) = multisigVault.deposits(address(token), multisig);
        assertEq(amount, balance);

        assertTrue(multisigVault.tokenWhitelist(address(token)));

        assertEq(token.balanceOf(address(multisigVault)), token.totalSupply());

        assertEq(token.totalSupply(), 10_000_000e18);

        assertEq(token.owner(), multisig);

        assertEq(multisigVault.owner(), multisig);

        assertFalse(multisigVault.paused());
    }
}
