const UpdaterContract = artifacts.require("UpdaterContract");
const SenderChain = artifacts.require("SenderChain");

/*
 * accounts = test accounts made available by the Ethereum client (Ganache)
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("UpdaterContract", function (accounts) {
    it("getBlockHeaderFields and getBlockHeaderHash", async function () {
        const senderChain = await SenderChain.deployed();

        // Create fake block header 1
        const blockHeaderByteArray1 = new Uint8Array(600);
        blockHeaderByteArray1[499] = 1;

        const {0: prevBlockHash1, 1: blockNumber1} = await
            senderChain.getBlockHeaderFields.call(blockHeaderByteArray1);
        assert.equal(blockNumber1, 1);

        // Compute hash
        var blockHeaderHash1 = web3.utils.soliditySha3(
            web3.utils.bytesToHex(blockHeaderByteArray1));
        var blockHeaderHashBytes1 = web3.utils.hexToBytes(blockHeaderHash1);

        // Create fake block header 2
        const blockHeaderByteArray2 = new Uint8Array(600);
        for (let i = 0; i < 32; i++) {
            blockHeaderByteArray2[i] = blockHeaderHashBytes1[i];
        }
        blockHeaderByteArray2[499] = 2;

        const {0: prevBlockHash2, 1: blockNumber2} = await
            senderChain.getBlockHeaderFields.call(blockHeaderByteArray2);
        assert.equal(blockNumber2, 2);
        assert.equal(prevBlockHash2, blockHeaderHash1);

        const solComputedHash = await
            senderChain.getBlockHeaderHash.call(blockHeaderByteArray1);
        assert.equal(solComputedHash, blockHeaderHash1);
    });
    it("headerUpdate and getBlockHeader sanity", async function () {
        const updaterContract = await UpdaterContract.deployed(false);

        // Dummy block
        const blockHeaderByteArray0 = new Uint8Array(600);

        // Create fake block header 1
        const blockHeaderByteArray1 = new Uint8Array(600);
        blockHeaderByteArray1[499] = 1;

        var success1 = await updaterContract.headerUpdate.call(
            new Uint8Array(0), blockHeaderByteArray1, blockHeaderByteArray0);
        assert.isTrue(success1);
        await updaterContract.headerUpdate(new Uint8Array(0),
            blockHeaderByteArray1, blockHeaderByteArray0);

        var {0: success1, 1: getBlockHeader1, 2: lcs1} =
            await updaterContract.getBlockHeader.call(1);
        assert.isTrue(success1);
        assert.equal(getBlockHeader1, web3.utils.bytesToHex(blockHeaderByteArray1));

        // Compute block header 1 hash
        var blockHeaderHash1 = web3.utils.soliditySha3(
            web3.utils.bytesToHex(blockHeaderByteArray1));
        var blockHeaderHashBytes1 = web3.utils.hexToBytes(blockHeaderHash1);

        // Create fake block header 2
        const blockHeaderByteArray2 = new Uint8Array(600);
        for (let i = 0; i < 32; i++) {
            blockHeaderByteArray2[i] = blockHeaderHashBytes1[i];
        }
        blockHeaderByteArray2[499] = 2;

        var success2 = await updaterContract.headerUpdate.call(
            new Uint8Array(0), blockHeaderByteArray2, blockHeaderByteArray1);
        assert.isTrue(success2);
        await updaterContract.headerUpdate(new Uint8Array(0),
            blockHeaderByteArray2, blockHeaderByteArray1);

        var {0: success2, 1: getBlockHeader2, 2: lcs2} =
            await updaterContract.getBlockHeader.call(2);
        assert.isTrue(success2);
        assert.equal(getBlockHeader2, web3.utils.bytesToHex(blockHeaderByteArray2));

        // Try to add bad parent block
        var bad = await updaterContract.headerUpdate.call(
            new Uint8Array(0), blockHeaderByteArray1, blockHeaderByteArray0);
        assert.isFalse(bad);
        await updaterContract.headerUpdate(new Uint8Array(0),
            blockHeaderByteArray1, blockHeaderByteArray0);

        var {0: bad, 1: getBlockHeader0, 2: lcs0} =
            await updaterContract.getBlockHeader.call(0);
        assert.isFalse(bad);
    });
});
