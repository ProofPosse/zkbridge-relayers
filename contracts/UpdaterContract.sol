// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./LightClient.sol";


contract UpdaterContract {
    LightClient.lightClientState LCS;

    struct headerInfo {
        bool exists;
        bytes32 prevBlockHash;
        bytes blockHeader;
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
        bytes32 prevHash = getBlockHeaderHash(prevBlockHeader);
        headerInfo memory prevEntry = headerDAG[prevHash];
        if (!prevEntry.exists) {
            if (!headerDAGEmpty) {
                return false;
            }
            headerDAGEmpty = false;
        }

        if (!LightClient.verify(proof, LCS, currBlockHeader,
                                prevBlockHeader)) {
            return false;
        }

        // Update state
        bytes32 currHash = getBlockHeaderHash(currBlockHeader);
        (bytes32 prevBlockHash, uint256 blockNumber) = getBlockHeaderFields(
            currBlockHeader);
        headerDAG[currHash].exists = true;
        headerDAG[currHash].prevBlockHash = prevBlockHash;
        numberToHeader[blockNumber].exists = true;
        numberToHeader[blockNumber].blockHeader = currBlockHeader;
        LightClient.update(LCS, currBlockHeader, prevBlockHeader);

        return true;
    }

    function batchedHeaderUpdate(
        bytes memory proof,
        bytes[] memory headers
    ) public returns(bool) {
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
            (bytes32 prevBlockHash, uint256 blockNumber) = getBlockHeaderFields(
                headers[i]);
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

    function getBlockHeaderFields(
        bytes memory blockHeader
    ) public pure returns(
        bytes32 prevBlockHash,
        uint256 blockNumber
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
    }

    function getBlockHeaderHash(
        bytes memory blockHeader
    ) public pure returns(bytes32) {
        return keccak256(blockHeader);
    }
}
