// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "solidity-rlp/contracts/RLPReader.sol";

library Merkle {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    function extractTransactionsRoot(bytes memory blockHeader)
        internal
        pure
        returns (bytes32)
    {
        RLPReader.RLPItem[] memory decodedHeader = blockHeader.toRlpItem().toList();
        bytes32 transactionsRoot = bytesToBytes32(decodedHeader[5].toBytes());
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
        uint256 position = index;

        uint256 proofLength = merkleProof.length / 32;
        bytes32[] memory proofElements = new bytes32[](proofLength);

        for (uint256 i = 0; i < proofLength; i++) {
            proofElements[i] = extractProofElement(merkleProof, i);
        }

        for (uint256 i = 0; i < proofLength; i++) {
            bytes32 proofElement = proofElements[i];

            if (position % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }

            position = position / 2;
        }

        return hash == keccak256(abi.encodePacked(transactionsRoot));
    }

    function extractProofElement(bytes memory merkleProof, uint256 i)
        internal
        pure
        returns (bytes32)
    {
        return bytesToBytes32(slice(merkleProof, i * 32, 32));
    }

    function bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        if (source.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes = new bytes(_length);
        for (uint256 i = 0; i < _length; i++) {
            tempBytes[i] = _bytes[_start + i];
        }
        return tempBytes;
    }
}
