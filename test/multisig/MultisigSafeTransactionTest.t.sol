pragma solidity ^0.8.0;

import {Test} from "@forge-std/Test.sol";

import {Constants} from "@forge-proposal-simulator/utils/Constants.sol";
import {MockCallOnlyMultisigProposal} from "./mocks/MockCallOnlyMultisigProposal.sol";
import {MockMixedOperationMultisigProposal} from "./mocks/MockMixedOperationMultisigProposal.sol";
import {MockMultiSend} from "./mocks/MockMultiSend.sol";
import {MockSafeTarget} from "./mocks/MockSafeTarget.sol";

contract MultisigSafeTransactionTest is Test {
    uint256 private constant SAFE_THRESHOLD_SLOT = 4;

    function test_regularCallProposalUsesCallOnlyMultiSend() public {
        MockSafeTarget target = new MockSafeTarget();
        MockCallOnlyMultisigProposal proposal = new MockCallOnlyMultisigProposal(makeAddr("multisig"), target);

        proposal.build();

        (address to, uint256 value, bytes memory data, uint8 operation) = proposal.getSafeTransaction();

        assertEq(to, Constants.SAFE_MULTISEND_CALL_ONLY_CONTRACT);
        assertEq(value, 0);
        assertEq(data, proposal.getCalldata());
        assertEq(operation, Constants.DELEGATE_CALL);
    }

    function test_mixedCallDelegateProposalUsesMultiSend() public {
        MockSafeTarget target = new MockSafeTarget();
        MockMixedOperationMultisigProposal proposal = new MockMixedOperationMultisigProposal(
            makeAddr("multisig"), target, _delegateSlot(), bytes32(uint256(0x1234))
        );

        proposal.build();

        (address to, uint256 value, bytes memory data, uint8 operation) = proposal.getSafeTransaction();

        assertEq(to, Constants.SAFE_MULTISEND_CONTRACT);
        assertEq(value, 0);
        assertEq(data, proposal.getCalldata());
        assertEq(operation, Constants.DELEGATE_CALL);
    }

    function test_encodedMultiSendOperationBytesMatchDelegateOverride() public {
        MockSafeTarget target = new MockSafeTarget();
        MockMixedOperationMultisigProposal proposal = new MockMixedOperationMultisigProposal(
            makeAddr("multisig"), target, _delegateSlot(), bytes32(uint256(0x1234))
        );

        proposal.build();

        bytes memory transactions = _decodeMultiSendTransactions(proposal.getCalldata());

        assertEq(_operationAt(transactions, 0), Constants.CALL);
        assertEq(_operationAt(transactions, 1), Constants.DELEGATE_CALL);
        assertEq(_operationAt(transactions, 2), Constants.CALL);
    }

    function test_simulationRestoresOriginalSafeBytecode() public {
        MockSafeTarget target = new MockSafeTarget();
        address multisig = makeAddr("multisig");
        bytes32 delegateSlot = _delegateSlot();
        bytes32 delegateValue = bytes32(uint256(0x1234));
        MockMixedOperationMultisigProposal proposal =
            new MockMixedOperationMultisigProposal(multisig, target, delegateSlot, delegateValue);

        proposal.build();

        _initializeSafeThreshold(multisig);
        vm.etch(Constants.SAFE_MULTISEND_CONTRACT, type(MockMultiSend).runtimeCode);

        bytes memory originalBytecode = multisig.code;

        proposal.simulate();

        assertEq(target.callSender(), multisig);
        assertEq(target.callNumber(), 22);
        assertEq(vm.load(multisig, delegateSlot), delegateValue);
        assertEq(keccak256(multisig.code), keccak256(originalBytecode));
    }

    function _decodeMultiSendTransactions(bytes memory data) internal pure returns (bytes memory) {
        bytes4 selector = _readBytes4(data, 0);
        require(selector == bytes4(keccak256("multiSend(bytes)")), "Wrong selector");

        bytes memory encodedParams = new bytes(data.length - 4);
        for (uint256 i = 0; i < encodedParams.length; i++) {
            encodedParams[i] = data[i + 4];
        }

        return abi.decode(encodedParams, (bytes));
    }

    function _operationAt(bytes memory transactions, uint256 actionIndex) internal pure returns (uint8 operation) {
        uint256 offset;

        for (uint256 i = 0; i <= actionIndex; i++) {
            operation = uint8(transactions[offset]);

            if (i == actionIndex) {
                return operation;
            }

            uint256 dataLength = _readUint256(transactions, offset + 53);
            offset += 85 + dataLength;
        }
    }

    function _readUint256(bytes memory data, uint256 offset) internal pure returns (uint256 value) {
        require(data.length >= offset + 32, "Read out of bounds");

        assembly {
            value := mload(add(add(data, 0x20), offset))
        }
    }

    function _readBytes4(bytes memory data, uint256 offset) internal pure returns (bytes4 value) {
        require(data.length >= offset + 4, "Read out of bounds");

        assembly {
            value := mload(add(add(data, 0x20), offset))
        }
    }

    function _initializeSafeThreshold(address safe) internal {
        vm.store(safe, bytes32(SAFE_THRESHOLD_SLOT), bytes32(uint256(1)));
    }

    function _delegateSlot() internal pure returns (bytes32) {
        return bytes32(uint256(0x828ef5eca6cf52a2ad4383abe23d27fbd33270d45147bceaaeaef0e8d12791a4));
    }
}
