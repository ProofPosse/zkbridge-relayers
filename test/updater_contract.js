const UpdaterContract = artifacts.require("UpdaterContract");
const UpdaterContractWithSkip = artifacts.require("UpdaterContractWithSkip");
const SenderChain = artifacts.require("SenderChain");

/*
 * accounts = test accounts made available by the Ethereum client (Ganache)
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("UpdaterContract", function (accounts) {
    it("headerUpdate and getBlockHeader sanity", async function () {
        const updaterContract = await UpdaterContract.deployed();

        // Dummy block
        const blockHeaderByteArray0 = new Uint8Array(600);

        // Create fake block header 1
        const blockHeaderByteArray1 = new Uint8Array(600);
        blockHeaderByteArray1[499] = 1;

        var success1 = await updaterContract.headerUpdate.call(
            new Uint8Array(0), 1, blockHeaderByteArray1, 0, blockHeaderByteArray0);
        assert.isTrue(success1);
        await updaterContract.headerUpdate(new Uint8Array(0),
            1, blockHeaderByteArray1, 0, blockHeaderByteArray0);

        var {0: success1, 1: getBlockHeader1, 2: lcs1} =
            await updaterContract.getBlockHeader.call(1);
        assert.isTrue(success1);
        assert.equal(getBlockHeader1, web3.utils.bytesToHex(blockHeaderByteArray1));

        // Create fake block header 2
        const blockHeaderByteArray2 = new Uint8Array(600);
        blockHeaderByteArray2[499] = 2;

        var success2 = await updaterContract.headerUpdate.call(
            new Uint8Array(0), 2, blockHeaderByteArray2, 1, blockHeaderByteArray1);
        assert.isTrue(success2);
        await updaterContract.headerUpdate(new Uint8Array(0),
            2, blockHeaderByteArray2, 1, blockHeaderByteArray1);

        var {0: success2, 1: getBlockHeader2, 2: lcs2} =
            await updaterContract.getBlockHeader.call(2);
        assert.isTrue(success2);
        assert.equal(getBlockHeader2, web3.utils.bytesToHex(blockHeaderByteArray2));

        // Try to add bad parent block
        var bad = await updaterContract.headerUpdate.call(
            new Uint8Array(0), 1, blockHeaderByteArray1, 0, blockHeaderByteArray0);
        assert.isFalse(bad);
        await updaterContract.headerUpdate(new Uint8Array(0),
            1, blockHeaderByteArray1, 0, blockHeaderByteArray0);

        var {0: bad, 1: getBlockHeader0, 2: lcs0} =
            await updaterContract.getBlockHeader.call(0);
        assert.isFalse(bad);
    });
    it("headerUpdate and getBlockHeader sanity (with skip)", async function () {
        // TODO: Update this test when Merkle proof verification is implemented.
        const updaterContractWithSkip = await UpdaterContractWithSkip.deployed();

        // Dummy block
        const blockHeaderByteArray0 = new Uint8Array(600);

        // Create fake block header 1
        const blockHeaderByteArray1 = new Uint8Array(600);
        blockHeaderByteArray1[499] = 1;

        var success1 = await updaterContractWithSkip.headerUpdate.call(
            new Uint8Array(0),
            1,
            blockHeaderByteArray1,
            0,
            blockHeaderByteArray0,
            new Uint8Array(0),
            new Uint8Array(0)
        );
        assert.isTrue(success1);
        await updaterContractWithSkip.headerUpdate(
            new Uint8Array(0),
            1,
            blockHeaderByteArray1,
            0,
            blockHeaderByteArray0,
            new Uint8Array(0),
            new Uint8Array(0)
        );

        var {0: success1, 1: getBlockHeader1, 2: lcs1} =
            await updaterContractWithSkip.getBlockHeader.call(1);
        assert.isTrue(success1);
        assert.equal(getBlockHeader1, web3.utils.bytesToHex(blockHeaderByteArray1));

        // Create fake block header 2
        const blockHeaderByteArray2 = new Uint8Array(600);
        blockHeaderByteArray2[499] = 2;

        var success2 = await updaterContractWithSkip.headerUpdate.call(
            new Uint8Array(0),
            2,
            blockHeaderByteArray2,
            1,
            blockHeaderByteArray1,
            new Uint8Array(0),
            new Uint8Array(0)
        );
        assert.isTrue(success2);
        await updaterContractWithSkip.headerUpdate(
            new Uint8Array(0),
            2,
            blockHeaderByteArray2,
            1,
            blockHeaderByteArray1,
            new Uint8Array(0),
            new Uint8Array(0)
        );

        var {0: success2, 1: getBlockHeader2, 2: lcs2} =
            await updaterContractWithSkip.getBlockHeader.call(2);
        assert.isTrue(success2);
        assert.equal(getBlockHeader2, web3.utils.bytesToHex(blockHeaderByteArray2));

        // Try to add bad parent block
        var bad = await updaterContractWithSkip.headerUpdate.call(
            new Uint8Array(0),
            1,
            blockHeaderByteArray1,
            0,
            blockHeaderByteArray0,
            new Uint8Array(0),
            new Uint8Array(0)
        );
        assert.isFalse(bad);
        await updaterContractWithSkip.headerUpdate(
            new Uint8Array(0),
            1,
            blockHeaderByteArray1,
            0,
            blockHeaderByteArray0,
            new Uint8Array(0),
            new Uint8Array(0)
        );

        var {0: bad, 1: getBlockHeader0, 2: lcs0} =
            await updaterContractWithSkip.getBlockHeader.call(0);
        assert.isFalse(bad);
    });
});
