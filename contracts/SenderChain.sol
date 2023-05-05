// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


library SenderChain {
    // Feel free to add more return values
    function getBlockHeaderFields(
        bytes memory blockHeader
    ) public pure returns(
        uint256 blockNumber
    ) {
        bytes32 blockNumberBytes;
        // blockNumber is located at 32 + [468:500] because we
        // need to skip the first 32 bytes (reserved for the
        // length of the byte string).
        /* solium-disable-next-line */
        assembly {
            blockNumberBytes := mload(add(blockHeader, 500))
        }
        blockNumber = uint256(blockNumberBytes);
    }
}
