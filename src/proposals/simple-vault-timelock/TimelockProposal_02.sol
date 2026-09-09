pragma solidity ^0.8.0;

import {TimelockProposal} from "@forge-proposal-simulator/src/proposals/TimelockProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";

contract TimelockProposal_02 is TimelockProposal {
    function name() public pure override returns (string memory) {
        return "TIMELOCK_MOCK_2";
    }

    function description() public pure override returns (string memory) {
        return "Timelock proposal mock 2";
    }

    function run() public override {
        setPrimaryForkId(vm.createSelectFork("sepolia"));

        string memory addressesFolderPath = "./addresses";
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 11155111;

        setAddresses(new Addresses(addressesFolderPath, chainIds));

        setTimelock(addresses.getAddress("PROTOCOL_TIMELOCK"));

        super.run();
    }

    function build() public override buildModifier(address(timelock)) {
        /// STATICCALL -- not recorded for the run stage
        Vault timelockVault = Vault(addresses.getAddress("TIMELOCK_VAULT"));
        address token = addresses.getAddress("TIMELOCK_TOKEN");
        (uint256 amount,) = timelockVault.deposits(address(token), address(timelock));

        /// CALLS -- mutative and recorded
        timelockVault.withdraw(token, payable(address(timelock)), amount);
    }

    function simulate() public override {
        address dev = addresses.getAddress("DEPLOYER_EOA");

        /// Dev is proposer and executor
        _simulateActions(dev, dev);
    }

    function validate() public view override {
        Vault timelockVault = Vault(addresses.getAddress("TIMELOCK_VAULT"));
        Token token = Token(addresses.getAddress("TIMELOCK_TOKEN"));

        uint256 balance = token.balanceOf(address(timelockVault));
        assertEq(balance, 0);

        (uint256 amount,) = timelockVault.deposits(address(token), address(timelock));
        assertEq(amount, 0);

        assertEq(token.balanceOf(address(timelock)), 10_000_000e18);
    }
}
