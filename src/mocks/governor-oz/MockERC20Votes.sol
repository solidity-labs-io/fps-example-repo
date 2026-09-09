// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20, ERC20Permit, ERC20Votes} from "@openzeppelin/token/ERC20/extensions/ERC20Votes.sol";

contract MockERC20Votes is ERC20Votes {
    constructor(string memory name_, string memory symbol_) ERC20Permit(name_) ERC20(name_, symbol_) {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
