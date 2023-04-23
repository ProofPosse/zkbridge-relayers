// File: contracts/ILightClient.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ILightClient {
    function update(
        bytes calldata currBlockHeader,
        bytes calldata prevBlockHeader
    ) external;

    function verify(
        bytes calldata proof,
        bytes calldata currBlockHeader,
        bytes calldata prevBlockHeader
    ) external view returns (bool);

    function verifyBatch(
        bytes calldata proof,
        bytes[] calldata headers
    ) external view returns (bool);
}

// File: contracts/LightClient.sol

pragma solidity >=0.4.22 <0.9.0;

contract LightClient is ILightClient {
    struct lightClientState {
        bool notImplemented;
    }

    lightClientState private LCS;

    function update(
        bytes memory /* currBlockHeader */,
        bytes memory /* prevBlockHeader */
    ) public override {
        LCS.notImplemented = true;
    }

    function verify(
        bytes memory /* proof */,
        bytes memory /* currBlockHeader */,
        bytes memory /* prevBlockHeader */
    ) public view override returns(bool) {
        // Read LCS to prevent compiler telling us to change view -> pure
        // Dummy implementation always returns true
        return LCS.notImplemented || !LCS.notImplemented;
    }

    function verifyBatch(
        bytes memory /* proof */,
        bytes[] memory /* headers */
    ) public view override returns(bool) {
        // Read LCS to prevent compiler telling us to change view -> pure
        // Dummy implementation always returns true
        return LCS.notImplemented || !LCS.notImplemented;
    }
}

// File: contracts/UpdaterContract.sol

pragma solidity >=0.4.22 <0.9.0;

contract UpdaterContract {
    LightClient private lightClient;
    LightClient.lightClientState LCS;

    constructor(address _lightClientAddress) {
        lightClient = LightClient(_lightClientAddress);
    }

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

        if (!lightClient.verify(proof, currBlockHeader,
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

        lightClient.update(currBlockHeader, prevBlockHeader);

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

        if (!lightClient.verifyBatch(proof, headers)) {
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
            lightClient.update(headers[i], headers[i - 1]);
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
