// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


contract UpdaterContract {
    // TODO lightClientState;

    struct headerDAGEntry {
        bool exists;
        bytes32 prevBlockHash;
        uint256 blockNumber;
        bytes blockHeader;
    }
    mapping (bytes32 => headerDAGEntry) headerDAGByHash;
    mapping (uint256 => headerDAGEntry) headerDAGByNumber;

    bool headerDAGEmpty = true;

    event LogMe(string message);

    function headerUpdate(
        bytes memory /* proof */,
        bytes memory currBlockHeader,
        bytes memory prevBlockHeader
    ) public returns(bool) {
        // Check if parent exists
        bytes32 prevHash = getBlockHeaderHash(prevBlockHeader);
        headerDAGEntry memory prevEntry = headerDAGByHash[prevHash];
        if (!prevEntry.exists) {
            if (!headerDAGEmpty) {
                return false;
            }
            headerDAGEmpty = false;
        }

        // TODO: verification

        // Add to headerDAG.
        bytes32 currHash = getBlockHeaderHash(currBlockHeader);
        (bytes32 prevBlockHash, uint256 blockNumber) = getBlockHeaderFields(
            currBlockHeader);
        headerDAGByHash[currHash].exists = true;
        headerDAGByHash[currHash].prevBlockHash = prevBlockHash;
        headerDAGByHash[currHash].blockNumber = blockNumber;
        headerDAGByHash[currHash].blockHeader = currBlockHeader;
        headerDAGByNumber[blockNumber].exists = true;
        headerDAGByNumber[blockNumber].blockHeader = currBlockHeader;

        // TODO: update lightClient state

        return true;
    }

    function getBlockHeader(uint256 blockNumber) public view returns(
        bool success,
        bytes memory blockHeader
    ) {
        success = headerDAGByNumber[blockNumber].exists;
        blockHeader = headerDAGByNumber[blockNumber].blockHeader;

        // TODO: also return lightClient state
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
