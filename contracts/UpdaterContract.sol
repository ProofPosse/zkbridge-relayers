// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./LightClient.sol";


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

    bool skippingBlockPolicy;
    bytes currSyncCommittee;

    event LogMe(string message);

    constructor (bool _skippingBlockPolicy) {
        skippingBlockPolicy = _skippingBlockPolicy;
    }

    function headerUpdate(
        bytes memory proof,
        bytes memory currBlockHeader,
        bytes memory prevBlockHeader
    ) public returns(bool) {
        // Check if parent exists
        bytes32 prevHash = getBlockHeaderHash(prevBlockHeader);
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
        ) = getBlockHeaderFields(currBlockHeader);

        if (!skippingBlockPolicy ||
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
        bytes32 currHash = getBlockHeaderHash(currBlockHeader);
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
        if (skippingBlockPolicy) {
            return false;
        }

        // Check if first block exists
        bytes32 prevHash = getBlockHeaderHash(headers[0]);
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
            bytes32 currHash = getBlockHeaderHash(headers[i]);
            (
                bytes32 prevBlockHash,
                uint256 blockNumber,
            ) = getBlockHeaderFields(headers[i]);
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

        if (skippingBlockPolicy && success) {
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

    function getBlockHeaderFields(
        bytes memory blockHeader
    ) public pure returns(
        bytes32 prevBlockHash,
        uint256 blockNumber,
        bytes memory syncCommittee
    ) {
        bytes32 blockNumberBytes;
        // prevBlockHash is located at bytes 32 + [0:32] and blockNumber
        // is located at 32 + [468:500] because we need to skip the first
        // 32 bytes (reserved for the length of the byte string).
        /* solium-disable-next-line */
        assembly {
            prevBlockHash := mload(add(blockHeader, 32))
            blockNumberBytes := mload(add(blockHeader, 500))
        }
        blockNumber = uint256(blockNumberBytes);
        // TODO Get syncCommittee
        syncCommittee = bytes("TODO");
    }

    function getBlockHeaderHash(
        bytes memory blockHeader
    ) public pure returns(bytes32) {
        return keccak256(blockHeader);
    }
}
