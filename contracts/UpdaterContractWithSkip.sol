// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./LightClientWithSkip.sol";
import "./SenderChain.sol";
import "./Merkle.sol";


contract UpdaterContractWithSkip {
    LightClientWithSkip.lightClientState LCS;

    struct headerInfo {
        bool exists;
        bytes32 prevBlockHash;
        SenderChain.bh blockHeader;
        bytes proof;
        bytes syncCommittee;
        bytes syncCommitteeProof;
    }
    mapping (bytes32 => headerInfo) headerDAG;
    mapping (uint256 => headerInfo) numberToHeader;

    bool headerDAGEmpty = true;

    bytes currSyncCommittee;

    event LogMe(string message);

    function headerUpdate(
        bytes memory proof,
        uint256 currBlockNumber,
        bytes memory currBlockHeader,
        uint256 prevBlockNumber,
        bytes memory prevBlockHeader,
        bytes memory syncCommittee,
        bytes memory syncCommitteeProof
    ) public returns(bool) {
        SenderChain.bh memory curr;
        SenderChain.bh memory prev;
        curr.asBytes = currBlockHeader;
        curr.blockNumber = currBlockNumber;
        prev.asBytes = prevBlockHeader;
        prev.blockNumber = prevBlockNumber;
        return headerUpdateCore(
            proof, curr, prev, syncCommittee, syncCommitteeProof
        );
    }

    function headerUpdateCore(
        bytes memory proof,
        SenderChain.bh memory currBlockHeader,
        SenderChain.bh memory prevBlockHeader,
        bytes memory syncCommittee,
        bytes memory syncCommitteeProof
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
            uint256 blockNumber
        ) = SenderChain.getBlockHeaderFields(currBlockHeader);

        if (!Merkle.verifyMessage(
            currBlockHeader,
            syncCommittee,
            syncCommitteeProof
        )) {
            return false;
        }

        if (keccak256(currSyncCommittee) != keccak256(syncCommittee)) {
            if (!LightClientWithSkip.verify(
                proof,
                LCS,
                currBlockHeader,
                prevBlockHeader,
                syncCommittee,
                syncCommitteeProof
            )) {
                return false;
            }
            currSyncCommittee = syncCommittee;
            LightClientWithSkip.update(
                LCS,
                currBlockHeader,
                prevBlockHeader,
                syncCommittee,
                syncCommitteeProof
            );
        }

        // Update state
        bytes32 currHash = SenderChain.getBlockHeaderHash(currBlockHeader);
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
            SenderChain.bh memory currBlockHeader = numberToHeader[
                blockNumber].blockHeader;
            SenderChain.bh memory prevBlockHeader = numberToHeader[
                blockNumber - 1].blockHeader;
            bytes memory syncCommittee = numberToHeader[
                blockNumber - 1].syncCommittee;
            bytes memory syncCommitteeProof = numberToHeader[
                blockNumber - 1].syncCommitteeProof;

            if (!LightClientWithSkip.verify(
                blockProof,
                LCS,
                currBlockHeader,
                prevBlockHeader,
                syncCommittee,
                syncCommitteeProof
            )) {
                success = false;
            } else {
                LightClientWithSkip.update(
                    LCS,
                    currBlockHeader,
                    prevBlockHeader,
                    syncCommittee,
                    syncCommitteeProof
                );
            }
        }
        blockHeader = SenderChain.getBlockHeaderBytes(
            numberToHeader[blockNumber].blockHeader);
        _LCS = LCS;
    }
}
