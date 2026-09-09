pragma solidity ^0.8.0;

import {TimelockProposal} from "@forge-proposal-simulator/src/proposals/TimelockProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Token} from "src/mocks/vault/Token.sol";
import {TokenWrapper} from "src/mocks/state-diff/TokenWrapper.sol";

contract StateDiffTimelockProposal_01 is TimelockProposal {
    function name() public pure override returns (string memory) {
        return "STATE_DIFF_TIMELOCK_MOCK";
    }

    function description() public pure override returns (string memory) {
        return "state diff timelock proposal mock";
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

    function deploy() public override {
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK");

        // mint 100 eth to timelock contract
        vm.deal(timelock, 100 ether);

        Token token = new Token();

        // add TOKEN address
        addresses.addAddress("TOKEN", address(token), true);

        TokenWrapper tokenWrapper = new TokenWrapper(address(token));

        // transfer 100 tokens to token wrapper contract
        token.transfer(address(tokenWrapper), 100 ether);

        // add TOKEN_WRAPPER address
        addresses.addAddress("TOKEN_WRAPPER", address(tokenWrapper), true);

        // transfer ownership to timelock controller
        tokenWrapper.transferOwnership(timelock);
    }

    function build() public override buildModifier(addresses.getAddress("PROTOCOL_TIMELOCK")) {
        TokenWrapper tokenWrapper = TokenWrapper(addresses.getAddress("TOKEN_WRAPPER"));
        tokenWrapper.mint{value: 10 ether}();

        // approve token wrapper to transfer token
        Token(addresses.getAddress("TOKEN")).approve(address(tokenWrapper), 10 ether);
        tokenWrapper.redeemTokens(10 ether);
    }

    function simulate() public override {
        address dev = addresses.getAddress("DEPLOYER_EOA");

        /// Dev is proposer and executor
        _simulateActions(dev, dev);
    }

    function validate() public view override {}
}
