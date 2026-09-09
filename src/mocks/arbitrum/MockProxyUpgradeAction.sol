// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProxyAdmin} from "@forge-proposal-simulator/src/interface/IProxyAdmin.sol";

/// @title ProxyUpgradeAction
/// @dev Arbitrum upgrades must be done through a delegate call to a GAC deployed contract
contract MockProxyUpgradeAction {
    function perform(address admin, address payable target, address newLogic) public payable {
        IProxyAdmin(admin).upgrade(target, newLogic);
    }
}
