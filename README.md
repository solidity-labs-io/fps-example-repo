# Forge Proposal Simulator Example Repository

## Overview
This repository serves as a practical example for utilizing the [Forge Proposal Simulator](https://github.com/solidity-labs-io/forge-proposal-simulator). It is designed to guide users through the process of creating and executing proposals using FPS.

## Getting Started
Before diving into the repository, it is crucial to familiarize yourself with the FPS framework. Comprehensive details and instructions are available in our [documentation](https://docs.soliditylabs.io/forge-proposal-simulator/).

## Repository Structure
The repository is structured into distinct folders, each with a designated function:

### `proposals`
Contains a range of proposal contracts. Each contract is an implementation of one of the proposal types outlined in the [FPS guides](https://docs.soliditylabs.io/forge-proposal-simulator/guides/). Proposals may include deploying new contracts, interacting with these contracts (e.g., transferring ownership), generating calldata for target contracts, and validating the protocol state post-execution.

### `scripts`
Contains a script for deploying each proposal. 

#### `test/multisig`
- `MultisigPostProposalCheck.sol`: Base contract for multisig integration tests. Responsible for deploying, executing proposal contracts and updating addresses object.
- `MultisigProposalIntegrationTest.t.sol`: Integration test for [MULTISIG_01.sol](proposals/MULTISIG_01.sol), inheriting from `MultisigPostProposalCheck.sol`.

#### `test/timelock`
- `TimelockPostProposalCheck.sol`: Base contract for timelock integration tests. Responsible for deploying, executing proposal contracts and updating addresses object.
- `TimelockProposalIntegrationTest.t.sol`: Integration test for [TIMELOCK_01.sol](proposals/TIMELOCK_01.sol), derived from `TimelockPostProposalCheck.sol`.

## Executing Proposals with FPS
FPS offers two methods for proposal execution, as detailed in our [documentation](https://docs.soliditylabs.io/forge-proposal-simulator/getting-set-up):

### 1. Using Forge Scripts
- Run `forge script script/MultisigScript.s.sol` to execute [MULTISIG_01.sol](proposals/MULTISIG_01.sol) 
- Run `forge script script/TimelockScript.s.sol` to execute [TIMELOCK_01.sol](proposals/TIMELOCK_01.sol)

### 2. Using Forge Test

- Run `forge test -vv` to execute all integration tests.

*For further assistance, please open an issue at [FPS Issues](https://github.com/solidity-labs-io/forge-proposal-simulator/issues/new)*
