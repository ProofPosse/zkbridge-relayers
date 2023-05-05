// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./LightClientWithSkip.sol";
import "./SenderChain.sol";
import "./EthMerkle.sol";
import "solidity-rlp/contracts/RLPReader.sol";

contract UpdaterContractWithSkip {
    LightClientWithSkip.lightClientState LCS;

    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    struct headerInfo {
        bool exists;
        bytes32 prevBlockHash;
        bytes blockHeader;
        bytes proof;
        bytes syncCommittee;
        RLPReader.RLPItem syncCommitteeProof;
    }
    mapping (bytes32 => headerInfo) headerDAG;
    mapping (uint256 => headerInfo) numberToHeader;

    bool headerDAGEmpty = true;

    bytes currSyncCommittee;

    event LogMe(string message);

    function headerUpdate(
        bytes memory proof,
        bytes memory currBlockHeader,
        bytes memory prevBlockHeader,
        bytes memory syncCommittee,
        bytes memory syncCommitteeProof
    ) public returns(bool) {
        // Check if parent exists
        bytes32 prevHash = keccak256(prevBlockHeader);
        headerInfo memory prevEntry = headerDAG[prevHash];
        if (!prevEntry.exists) {
            if (!headerDAGEmpty) {
                return false;
            }
            headerDAGEmpty = false;
        }

        (
            uint256 blockNumber
        ) = SenderChain.getBlockHeaderFields(currBlockHeader);

        bytes memory returnValue = EthMerkle.extractProofValue(
            currBlockHeader,
            syncCommittee,
            syncCommitteeProof.toList()
        );

        if (returnValue.length == 0) {
            return false;
        }

        if (keccak256(currSyncCommittee) != keccak256(syncCommittee)) {
            if (!LightClientWithSkip.verify(
                proof,
                LCS,
                currBlockHeader,
                prevBlockHeader,
                syncCommittee,
                syncCommitteeProof.toList()
            )) {
                return false;
            }
            currSyncCommittee = syncCommittee;
            LightClientWithSkip.update(
                LCS,
                currBlockHeader,
                prevBlockHeader,
                syncCommittee,
                syncCommitteeProof.toList()
            );
        }

        // Update state
        bytes32 currHash = keccak256(currBlockHeader);
        // TODO Handle block number conflicts
        headerDAG[currHash].exists = true;
        headerDAG[currHash].prevBlockHash = prevHash;
        numberToHeader[blockNumber].exists = true;
        numberToHeader[blockNumber].blockHeader = currBlockHeader;
        numberToHeader[blockNumber].proof = proof;
        numberToHeader[blockNumber].syncCommittee = syncCommittee;
        numberToHeader[blockNumber].syncCommitteeProof = syncCommitteeProof;

        return true;
    }

    function getBlockHeader(uint256 blockNumber) public returns(
        bool success,
        bytes memory blockHeader,
        LightClientWithSkip.lightClientState memory _LCS
    ) {
        success = numberToHeader[blockNumber].exists;

        if (success) {
            bytes memory blockProof = numberToHeader[blockNumber].proof;
            bytes memory currBlockHeader = numberToHeader[
                blockNumber].blockHeader;
            bytes memory prevBlockHeader = numberToHeader[
                blockNumber - 1].blockHeader;
            bytes memory syncCommittee = numberToHeader[
                blockNumber - 1].syncCommittee;
            RLPReader.RLPItem memory syncCommitteeProof = numberToHeader[
                blockNumber - 1].syncCommitteeProof;

            if (!LightClientWithSkip.verify(
                blockProof,
                LCS,
                currBlockHeader,
                prevBlockHeader,
                syncCommittee,
                syncCommitteeProof.toList()
            )) {
                success = false;
            } else {
                LightClientWithSkip.update(
                    LCS,
                    currBlockHeader,
                    prevBlockHeader,
                    syncCommittee,
                    syncCommitteeProof.toList()
                );
            }
        }
        blockHeader = numberToHeader[blockNumber].blockHeader;
        _LCS = LCS;
    }
}
