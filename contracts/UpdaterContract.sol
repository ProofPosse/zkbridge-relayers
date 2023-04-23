// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./LightClient.sol";
import "./SenderChain.sol";


contract UpdaterContract {
    LightClient.lightClientState LCS;

    struct headerInfo {
        bool exists;
        bytes32 prevBlockHash;
        bytes blockHeader;
        bytes proof;
    }
    mapping (bytes32 => headerInfo) headerDAG;
    mapping (uint256 => headerInfo) numberToHeader;

    bool headerDAGEmpty = true;

    bytes currSyncCommittee;

    event LogMe(string message);

    function headerUpdate(
        bytes memory proof,
        bytes memory currBlockHeader,
        bytes memory prevBlockHeader
    ) public returns(bool) {
        // Check if parent exists
        bytes32 prevHash = SenderChain.getBlockHeaderHash(prevBlockHeader);
        headerInfo memory prevEntry = headerDAG[prevHash];
        if (!prevEntry.exists) {
            if (!headerDAGEmpty) {
                return false;
            }
            headerDAGEmpty = false;
        }

        (
            bytes32 prevBlockHash,
            uint256 blockNumber,
            bytes memory syncCommittee
        ) = SenderChain.getBlockHeaderFields(currBlockHeader);

        if (!LightClient.skippingBlockPolicy ||
            keccak256(currSyncCommittee) != keccak256(syncCommittee)) {
            if (!LightClient.verify(
                proof,
                LCS,
                currBlockHeader,
                prevBlockHeader
            )) {
                return false;
            }
            currSyncCommittee = syncCommittee;
            LightClient.update(LCS, currBlockHeader, prevBlockHeader);
        }

        // Update state
        bytes32 currHash = SenderChain.getBlockHeaderHash(currBlockHeader);
        // TODO Handle block number conflicts
        headerDAG[currHash].exists = true;
        headerDAG[currHash].prevBlockHash = prevBlockHash;
        numberToHeader[blockNumber].exists = true;
        numberToHeader[blockNumber].blockHeader = currBlockHeader;
        numberToHeader[blockNumber].proof = proof;

        return true;
    }

    function batchedHeaderUpdate(
        bytes memory proof,
        bytes[] memory headers
    ) public returns(bool) {
        // TODO Implement skipping block policy for batchedHeaderUpdate
        if (LightClient.skippingBlockPolicy) {
            return false;
        }

        // Check if first block exists
        bytes32 prevHash = SenderChain.getBlockHeaderHash(headers[0]);
        headerInfo memory prevEntry = headerDAG[prevHash];
        if (!prevEntry.exists) {
            if (!headerDAGEmpty) {
                return false;
            }
            headerDAGEmpty = false;
        }

        if (!LightClient.verifyBatch(proof, LCS, headers)) {
            return false;
        }

        // Update state
        for (uint256 i = 1; i < headers.length; i++) {
            bytes32 currHash = SenderChain.getBlockHeaderHash(headers[i]);
            (
                bytes32 prevBlockHash,
                uint256 blockNumber,
            ) = SenderChain.getBlockHeaderFields(headers[i]);
            headerDAG[currHash].exists = true;
            headerDAG[currHash].prevBlockHash = prevBlockHash;
            numberToHeader[blockNumber].exists = true;
            numberToHeader[blockNumber].blockHeader = headers[i];
            LightClient.update(LCS, headers[i], headers[i - 1]);
        }

        return true;
    }

    function getBlockHeader(uint256 blockNumber) public returns(
        bool success,
        bytes memory blockHeader,
        LightClient.lightClientState memory _LCS
    ) {
        success = numberToHeader[blockNumber].exists;

        if (LightClient.skippingBlockPolicy && success) {
            bytes memory blockProof = numberToHeader[blockNumber].proof;
            bytes memory currBlockHeader = numberToHeader[
                blockNumber].blockHeader;
            bytes memory prevBlockHeader = numberToHeader[
                blockNumber - 1].blockHeader;

            if (!LightClient.verify(
                blockProof,
                LCS,
                currBlockHeader,
                prevBlockHeader
            )) {
                success = false;
            } else {
                LightClient.update(
                    LCS,
                    currBlockHeader,
                    prevBlockHeader
                );
            }
        }
        blockHeader = numberToHeader[blockNumber].blockHeader;
        _LCS = LCS;
    }

    function verifyMessage(
        bytes memory /* blockHeader */,
        bytes memory /* message */,
        bytes memory /* merkleProof */
    ) public pure returns(bool) {
        // TODO(Boyuan, Tony)
        // See https://solidity-by-example.org/app/merkle-tree/ for a good
        // starting point
        return true;
    }
}
