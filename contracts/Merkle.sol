// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/RLPReader.sol";
// Common functions used by both UpdaterContract and UpdaterContractWithSkip
library Merkle {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    function extractTransactionsRoot(bytes memory blockHeader) internal pure returns (bytes32) {
        RLPReader.RLPItem[] memory decodedHeader = blockHeader.toRlpItem().toList();
        bytes32 transactionsRoot = decodedHeader[5].toBytes32();
        return transactionsRoot;
    }

    function verifyMessage(
        bytes memory blockHeader,
        bytes memory message,
        bytes memory merkleProof,
        uint256 index
    ) public pure returns(bool) {
        bytes32 transactionsRoot = extractTransactionsRoot(blockHeader);

        bytes32 hash = keccak256(message);

        // assuming merkle proof this format 0x<hash1><hash2>...<hashN>
        uint256 proofLength = merkleProof.length / 32;
        bytes32[] memory proofElements = new bytes32[](proofLength);

        for (uint256 i = 0; i < proofLength; i++) {
            assembly {
                proofElements[i] := mload(add(merkleProof, add(32, mul(i, 32))))
            }
        }

        for (uint256 i = 0; i < proofLength; i++) {
            bytes32 proofElement = proofElements[i];

            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }

            index = index / 2;
        }

        return hash == transactionsRoot;
    }
}