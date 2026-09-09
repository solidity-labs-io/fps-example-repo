// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Vm} from "@forge-std/Vm.sol";
import {console} from "@forge-std/console.sol";

import {OZGovernorProposal} from "@forge-proposal-simulator/src/proposals/OZGovernorProposal.sol";
import {
    IGovernor,
    IGovernorTimelockControl,
    IGovernorVotes
} from "@forge-proposal-simulator/src/interface/IGovernor.sol";
import {ITimelockController} from "@forge-proposal-simulator/src/interface/ITimelockController.sol";
import {IVotes} from "@forge-proposal-simulator/src/interface/IVotes.sol";
import {Address} from "@forge-proposal-simulator/utils/Address.sol";

import {MockArbSys} from "src/mocks/arbitrum/MockArbSys.sol";
import {MockArbOutbox} from "src/mocks/arbitrum/MockArbOutbox.sol";

abstract contract ArbitrumProposal is OZGovernorProposal {
    using Address for address;

    /// @notice the target address on L1 Timelock when it's a L2 proposal
    address private constant RETRYABLE_TICKET_MAGIC = 0xa723C008e76E379c55599D2E4d93879BeaFDa79C;

    /// @notice minimum delay for the Arbitrum L1 timelock
    uint256 private constant minDelay = 3 days;

    /// @notice Arbitrum One inbox address on mainnet
    address private constant arbOneInbox = 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;

    /// @notice Arbitrum Nova inbox address on mainnet
    address private constant arbNovaInbox = 0xc4448b71118c9071Bcb9734A0EAc55D18A153949;

    enum ProposalExecutionChain {
        ETH,
        ARB_ONE,
        ARB_NOVA
    }

    /// @notice the chain where the proposal will be executed after L1 settlement
    ProposalExecutionChain internal executionChain;

    /// @notice arbitrum proposals must be settled on the l1 network
    uint256 public ethForkId;

    /// @notice set eth fork id
    function setEthForkId(uint256 _forkId) public {
        ethForkId = _forkId;
    }

    /// @notice mock arb sys precompiled contract on L2
    ///         mock outbox on mainnet
    function preBuildMock() public override {
        // switch to mainnet fork to mock arb outbox
        vm.selectFork(ethForkId);
        address mockOutbox = address(new MockArbOutbox());

        vm.store(addresses.getAddress("ARBITRUM_BRIDGE"), bytes32(uint256(5)), bytes32(uint256(uint160(mockOutbox))));

        vm.selectFork(primaryForkId);

        address arbsys = address(new MockArbSys());
        vm.makePersistent(arbsys);

        vm.etch(addresses.getAddress("ARBITRUM_SYS"), address(arbsys).code);
    }

    /// @notice Arbitrum proposals should have a single action
    function _validateActions() internal view override {
        uint256 actionsLength = actions.length;

        require(actionsLength == 1, "Arbitrum proposals must have a single action");

        require(actions[0].target != address(0), "Invalid target for proposal");
        /// if there are no args and no eth, the action is not valid
        require(
            (actions[0].arguments.length == 0 && actions[0].value > 0) || actions[0].arguments.length > 0,
            "Invalid arguments for proposal"
        );

        // Value is ignored on L2 proposals
        if (executionChain == ProposalExecutionChain.ARB_ONE) {
            require(actions[0].value == 0, "Value must be 0 for L2 execution");
        }
    }

    /// @notice get the calldata to schedule the timelock on L1
    ///         the L1 schedule calldata must be the calldata for all arbitrum proposals
    function getScheduleTimelockCaldata() public view returns (bytes memory scheduleCalldata) {
        // address only used if is a L2 proposal
        address inbox;

        if (executionChain == ProposalExecutionChain.ARB_ONE) {
            inbox = arbOneInbox;
        } else if (executionChain == ProposalExecutionChain.ARB_NOVA) {
            inbox = arbNovaInbox;
        }

        scheduleCalldata = abi.encodeWithSelector(
            ITimelockController.schedule.selector,
            // if the action is to be executed on l1, the target is the actual
            // target, otherwise it is the magic value that tells that the
            // proposal must be relayed back to l2
            executionChain == ProposalExecutionChain.ETH ? actions[0].target : RETRYABLE_TICKET_MAGIC, // target
            actions[0].value, // value
            executionChain == ProposalExecutionChain.ETH
                ? actions[0].arguments
                : abi.encode( // these are the retryable data params
                    // the inbox we want to use, should be arb one or nova
                    inbox,
                    addresses.getAddress("ARBITRUM_L2_UPGRADE_EXECUTOR"), // the upgrade executor on the l2 network
                    0, // no value in this upgrade
                    0, // max gas - will be filled in when the retryable is actually executed
                    0, // max fee per gas - will be filled in when the retryable is actually executed
                    actions[0].arguments // calldata created on the build function
                ),
            bytes32(0), // no predecessor
            keccak256(abi.encodePacked(description())), // salt is prop description
            minDelay // delay for this proposal
        );
    }

    /// @notice get proposal actions
    /// @dev Arbitrum proposals must have a single action which must be a call
    /// to ArbSys address with the l1 timelock schedule calldata
    function getProposalActions()
        public
        view
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory arguments)
    {
        _validateActions();

        // inner calldata must be a call to schedule on L1Timelock
        bytes memory innerCalldata = getScheduleTimelockCaldata();

        targets = new address[](1);
        values = new uint256[](1);
        arguments = new bytes[](1);

        bytes memory callData = abi.encodeWithSelector(
            MockArbSys.sendTxToL1.selector, addresses.getAddress("ARBITRUM_L1_TIMELOCK", 1), innerCalldata
        );

        // Arbitrum proposals target must be the ArbSys precompiled address
        targets[0] = addresses.getAddress("ARBITRUM_SYS");
        values[0] = 0;
        arguments[0] = callData;
    }

    /// @notice override the OZGovernorProposal simulate function to handle
    ///         the proposal L1 settlement
    function simulate() public override {
        // First part of Arbitrum Governance proposal path follows the OZ
        // Governor with TimelockController extension
        _simulateGovernorProposal();

        // Second part of Arbitrum Governance proposal path is the proposal
        // settlement on the L1 network
        bytes memory scheduleCalldata = getScheduleTimelockCaldata();

        // switch fork to mainnet
        vm.selectFork(ethForkId);

        // prank as the bridge
        vm.startPrank(addresses.getAddress("ARBITRUM_BRIDGE"));

        address l1TimelockAddress = addresses.getAddress("ARBITRUM_L1_TIMELOCK");

        ITimelockController timelock = ITimelockController(l1TimelockAddress);

        address target;
        uint256 value;
        bytes memory data;
        bytes32 predecessor;

        {
            // Start recording logs so we can create the execute calldata using the
            // CallSchedule log data
            vm.recordLogs();

            // Call the schedule function on the L1 timelock
            l1TimelockAddress.functionCall(scheduleCalldata);

            // Stop recording logs
            Vm.Log[] memory entries = vm.getRecordedLogs();

            // Get the execute parameters from schedule call logs
            (target, value, data, predecessor,) =
                abi.decode(entries[0].data, (address, uint256, bytes, bytes32, uint256));

            // warp to the future to execute the proposal
            vm.warp(block.timestamp + minDelay);
        }

        vm.stopPrank();

        {
            // Start recording logs so we can get the TxToL2 log data
            vm.recordLogs();

            // execute the proposal
            timelock.execute(target, value, data, predecessor, keccak256(abi.encodePacked(description())));

            // Stop recording logs
            Vm.Log[] memory entries = vm.getRecordedLogs();

            // If is a retriable ticket, we need to execute on L2
            if (target == RETRYABLE_TICKET_MAGIC) {
                // entries index 2 is TxToL2
                // topic with index 2 is the l2 target address
                address to = address(uint160(uint256(entries[2].topics[2])));

                bytes memory l2Calldata = abi.decode(entries[2].data, (bytes));

                // Switch back to primary fork, must be either Arb One or Arb Nova
                vm.selectFork(primaryForkId);

                // Perform the low-level call
                vm.prank(addresses.getAddress("ARBITRUM_ALIASED_L1_TIMELOCK"));
                bytes memory returndata = to.functionCall(l2Calldata);

                if (DEBUG && returndata.length > 0) {
                    console.log("Target %s called on L2 and returned:", to);
                    console.logBytes(returndata);
                }
            }
        }
    }

    function _simulateGovernorProposal() internal {
        address proposerAddress = address(1);
        IVotes governanceToken = IVotes(IGovernorVotes(address(governor)).token());
        {
            uint256 quorumVotes = governor.quorum(block.number - 1);
            uint256 proposalThreshold = governor.proposalThreshold();
            uint256 votingPower = quorumVotes > proposalThreshold ? quorumVotes : proposalThreshold;
            // Arbitrum's dynamic quorum can move after the synthetic delegation checkpoint.
            votingPower *= 10;
            deal(address(governanceToken), proposerAddress, votingPower);
            vm.roll(block.number - 1);

            vm.prank(proposerAddress);
            governanceToken.delegate(proposerAddress);
            vm.roll(block.number + 2);
        }

        bytes memory proposeCalldata = getCalldata();

        vm.prank(proposerAddress);
        bytes memory proposalData = address(governor).functionCall(proposeCalldata);
        uint256 returnedProposalId = abi.decode(proposalData, (uint256));

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = getProposalActions();

        uint256 proposalId =
            governor.hashProposal(targets, values, calldatas, keccak256(abi.encodePacked(description())));

        require(returnedProposalId == proposalId, "Proposal id mismatch");
        require(governor.state(proposalId) == IGovernor.ProposalState.Pending, "Proposal not pending");

        vm.roll(block.number + governor.votingDelay() + 1);

        require(governor.state(proposalId) == IGovernor.ProposalState.Active, "Proposal not active");

        vm.prank(proposerAddress);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + governor.votingPeriod());

        require(governor.state(proposalId) == IGovernor.ProposalState.Succeeded, "Proposal not succeeded");

        governor.queue(targets, values, calldatas, keccak256(abi.encodePacked(description())));

        require(governor.state(proposalId) == IGovernor.ProposalState.Queued, "Proposal not queued");

        ITimelockController timelock = ITimelockController(IGovernorTimelockControl(address(governor)).timelock());
        vm.warp(block.timestamp + timelock.getMinDelay() + 1);

        governor.execute(targets, values, calldatas, keccak256(abi.encodePacked(description())));

        require(governor.state(proposalId) == IGovernor.ProposalState.Executed, "Proposal not executed");
    }
}
