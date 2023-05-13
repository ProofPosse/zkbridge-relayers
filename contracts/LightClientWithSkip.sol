// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "solidity-rlp/contracts/RLPReader.sol";
import "./SenderChain.sol";

library LightClientWithSkip {
    struct lightClientState {
        bool notImplemented;
    }

    function update(
        lightClientState storage LCS,
        SenderChain.bh memory /* currBlockHeader */,
        SenderChain.bh memory /* prevBlockHeader */,
        bytes memory /* syncCommittee */,
        RLPReader.RLPItem[] memory /* syncCommitteeProof */
    ) public {
        LCS.notImplemented = true;
    }

    function verify(
        bytes memory /* proof */,
        lightClientState storage LCS,
        SenderChain.bh memory /* currBlockHeader */,
        SenderChain.bh memory /* prevBlockHeader */,
        bytes memory /* syncCommittee */,
        RLPReader.RLPItem[] memory /* syncCommitteeProof */
    ) public view returns(bool) {
        // Read LCS to prevent compiler telling us to change view -> pure
        // Dummy implementation always returns true
        return LCS.notImplemented || !LCS.notImplemented;
    }
}
