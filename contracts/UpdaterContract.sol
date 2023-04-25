// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./LightClient.sol";
import "./SenderChain.sol";
import "./Merkle.sol";


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
            uint256 blockNumber
        ) = SenderChain.getBlockHeaderFields(currBlockHeader);

        if (!LightClient.verify(
            proof,
            LCS,
            currBlockHeader,
            prevBlockHeader
        )) {
            return false;
        }
        LightClient.update(LCS, currBlockHeader, prevBlockHeader);

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
                uint256 blockNumber
            ) = SenderChain.getBlockHeaderFields(headers[i]);
            headerDAG[currHash].exists = true;
            headerDAG[currHash].prevBlockHash = prevBlockHash;
            numberToHeader[blockNumber].exists = true;
            numberToHeader[blockNumber].blockHeader = headers[i];
            LightClient.update(LCS, headers[i], headers[i - 1]);
        }

        return true;
    }

    function getBlockHeader(uint256 blockNumber) public view returns(
        bool success,
        bytes memory blockHeader,
        LightClient.lightClientState memory _LCS
    ) {
        success = numberToHeader[blockNumber].exists;
        blockHeader = numberToHeader[blockNumber].blockHeader;
        _LCS = LCS;
    }
}
