// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


library SenderChain {
    struct bh {
        uint256 blockNumber;
        bytes asBytes;
    }

    // Feel free to add more return values
    function getBlockHeaderFields(
        bh memory blockHeader
    ) public pure returns(
        uint256 blockNumber
    ) {
        return blockHeader.blockNumber;
    }

    function getBlockHeaderHash(
        bh memory blockHeader
    ) public pure returns(bytes32) {
        return keccak256(blockHeader.asBytes);
    }

    function getBlockHeaderBytes(
        bh memory blockHeader
    ) public pure returns(bytes memory) {
        return blockHeader.asBytes;
    }
}
