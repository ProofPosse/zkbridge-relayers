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
