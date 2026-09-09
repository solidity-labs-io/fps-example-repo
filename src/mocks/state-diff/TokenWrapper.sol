// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/Ownable.sol";

contract TokenWrapper is Ownable {
    address internal _tokenAddress;

    constructor(address tokenAddress) {
        _tokenAddress = tokenAddress;
    }

    function mint() external payable onlyOwner {
        ERC20(_tokenAddress).transfer(msg.sender, msg.value);
    }

    function redeemTokens(uint256 tokenAmount) external onlyOwner {
        require(ERC20(_tokenAddress).balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");

        require(address(this).balance >= tokenAmount, "Insufficient ETH balance in contract");

        ERC20(_tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        payable(msg.sender).transfer(tokenAmount);
    }
}
