// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IProxy} from "@forge-proposal-simulator/src/interface/IProxy.sol";
import {MockUpgrade} from "@forge-proposal-simulator/mocks/MockUpgrade.sol";

import {Addresses} from "@addresses/Addresses.sol";
import {MockProxyUpgradeAction} from "src/mocks/arbitrum/MockProxyUpgradeAction.sol";
import {ArbitrumProposal} from "./ArbitrumProposal.sol";

interface IUpgradeExecutor {
    function execute(address upgrader, bytes memory upgradeCalldata) external payable;
}

/// @title ArbitrumProposal_01
/// @notice This is a example proposal that upgrades the L2 weth gateway
contract ArbitrumProposal_01 is ArbitrumProposal {
    constructor() {
        executionChain = ProposalExecutionChain.ARB_ONE;
    }

    function name() public pure override returns (string memory) {
        return "ARBITRUM_PROPOSAL_01";
    }

    function description() public pure override returns (string memory) {
        return "This proposal upgrades the L2 weth gateway";
    }

    function run() public override {
        string memory addressesFolderPath = "./addresses";
        uint256[] memory chainIds = new uint256[](2);
        chainIds[0] = 1;
        chainIds[1] = 42161;
        addresses = new Addresses(addressesFolderPath, chainIds);
        vm.makePersistent(address(addresses));

        setPrimaryForkId(vm.createFork("arbitrum"));

        setEthForkId(vm.createFork("ethereum"));

        vm.selectFork(primaryForkId);

        setGovernor(addresses.getAddress("ARBITRUM_L2_CORE_GOVERNOR"));

        super.run();
    }

    function deploy() public override {
        if (!addresses.isAddressSet("ARBITRUM_L2_WETH_GATEWAY_IMPLEMENTATION")) {
            address mockUpgrade = address(new MockUpgrade());

            addresses.addAddress("ARBITRUM_L2_WETH_GATEWAY_IMPLEMENTATION", mockUpgrade, true);
        }

        if (!addresses.isAddressSet("PROXY_UPGRADE_ACTION")) {
            address gac = address(new MockProxyUpgradeAction());
            addresses.addAddress("PROXY_UPGRADE_ACTION", gac, true);
        }
    }

    function build() public override buildModifier(addresses.getAddress("ARBITRUM_ALIASED_L1_TIMELOCK")) {
        IUpgradeExecutor upgradeExecutor = IUpgradeExecutor(addresses.getAddress("ARBITRUM_L2_UPGRADE_EXECUTOR"));

        upgradeExecutor.execute(
            addresses.getAddress("PROXY_UPGRADE_ACTION"),
            abi.encodeWithSelector(
                MockProxyUpgradeAction.perform.selector,
                addresses.getAddress("ARBITRUM_L2_PROXY_ADMIN"),
                addresses.getAddress("ARBITRUM_L2_WETH_GATEWAY_PROXY"),
                addresses.getAddress("ARBITRUM_L2_WETH_GATEWAY_IMPLEMENTATION")
            )
        );
    }

    function validate() public override {
        IProxy proxy = IProxy(addresses.getAddress("ARBITRUM_L2_WETH_GATEWAY_PROXY"));

        // implementation() caller must be the owner
        vm.startPrank(addresses.getAddress("ARBITRUM_L2_PROXY_ADMIN"));
        require(
            proxy.implementation() == addresses.getAddress("ARBITRUM_L2_WETH_GATEWAY_IMPLEMENTATION"),
            "Proxy implementation not set"
        );
        vm.stopPrank();
    }
}
