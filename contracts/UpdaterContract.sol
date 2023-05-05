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
        SenderChain.bh blockHeader;
        bytes proof;
    }
    mapping (bytes32 => headerInfo) headerDAG;
    mapping (uint256 => headerInfo) numberToHeader;

    bool headerDAGEmpty = true;

    event LogMe(string message);

    // Convenient preprocessing function that sits on top of headerUpdateCore
    function headerUpdate(
        bytes memory proof,
        uint256 currBlockNumber,
        bytes memory currBlockHeader,
        uint256 prevBlockNumber,
        bytes memory prevBlockHeader
    ) public returns(bool) {
        SenderChain.bh memory curr;
        SenderChain.bh memory prev;
        curr.asBytes = currBlockHeader;
        curr.blockNumber = currBlockNumber;
        prev.asBytes = prevBlockHeader;
        prev.blockNumber = prevBlockNumber;
        return headerUpdateCore(proof, curr, prev);
    }

    function headerUpdateCore(
        bytes memory proof,
        SenderChain.bh memory currBlockHeader,
        SenderChain.bh memory prevBlockHeader
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
        headerDAG[currHash].prevBlockHash = prevHash;
        numberToHeader[blockNumber].exists = true;
        numberToHeader[blockNumber].blockHeader = currBlockHeader;
        numberToHeader[blockNumber].proof = proof;

        return true;
    }

    function batchedHeaderUpdateCore(
        bytes memory proof,
        SenderChain.bh[] memory headers
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
                uint256 blockNumber
            ) = SenderChain.getBlockHeaderFields(headers[i]);
            headerDAG[currHash].exists = true;
            headerDAG[currHash].prevBlockHash = prevHash;
            numberToHeader[blockNumber].exists = true;
            numberToHeader[blockNumber].blockHeader = headers[i];
            LightClient.update(LCS, headers[i], headers[i - 1]);
            prevHash = currHash;
        }

        return true;
    }

    function getBlockHeader(uint256 blockNumber) public view returns(
        bool success,
        bytes memory blockHeader,
        LightClient.lightClientState memory _LCS
    ) {
        success = numberToHeader[blockNumber].exists;
        blockHeader = SenderChain.getBlockHeaderBytes(
            numberToHeader[blockNumber].blockHeader);
        _LCS = LCS;
    }
}
