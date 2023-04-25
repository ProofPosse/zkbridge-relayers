// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


// Common functions used by both UpdaterContract and UpdaterContractWithSkip
library Merkle {
    function verifyMessage(
        bytes memory /* blockHeader */,
        bytes memory /* message */,
        bytes memory /* merkleProof */
    ) public pure returns(bool) {
        // TODO(Boyuan, Tony)
        // See https://solidity-by-example.org/app/merkle-tree/ for a good
        // starting point
        return true;
    }
}
