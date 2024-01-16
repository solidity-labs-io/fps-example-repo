# Forge Proposal Simulator Example Repository

## Overview
This repository serves as a practical example for utilizing the [Forge Proposal Simulator](https://github.com/solidity-labs-io/forge-proposal-simulator). It is designed to guide users through the process of creating and executing proposals using FPS.

## Getting Started
Before diving into the repository, it is crucial to familiarize yourself with the FPS framework. Comprehensive details and instructions are available in our [documentation](https://docs.soliditylabs.io/forge-proposal-simulator/).

## Repository Structure
The repository is structured into distinct folders, each with a designated function:

- `src`: This directory contains contracts intended for use in proposals. It is important to note that these contracts serve exclusively as examples and are not recommended for production deployment due to the absence of validation and audit process. The primary purpose of these contracts is to demonstrate deployment and protocol paramaters configuration through proposals.
- `proposals`: Constains a variety of proposal contracts. Each contract in this folder is an extension of one of the [proposal types](https://docs.soliditylabs.io/forge-proposal-simulator/guides/) offered by FPS.
- `scripts`: Contains a script for each proposal.


## Executing Proposals with FPS
FPS offers two methodologies for proposal execution, as detailed in our [documentation](https://docs.soliditylabs.io/forge-proposal-simulator/):

### 1. Using Forge Scripts
-  Run `forge script script/MultisigScript.s.sol:MultisigScript` to execute
   [MULTISIG_01.sol](proposals/MULTISIG_01.sol) 

### 2. Using Forge Test
- Detailed instructions for using `forge test` can be found in the [Foundry Book](https://book.getfoundry.sh/reference/forge/forge-test).

*For further assistance, please open an issue at [FPS Issues](https://github.com/solidity-labs-io/forge-proposal-simulator/issues/new)*
