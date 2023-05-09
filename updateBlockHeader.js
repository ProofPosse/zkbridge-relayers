const Web3 = require('web3');
require('dotenv').config();
const RLP = require('rlp');
const UpdaterContract = require('./build/contracts/UpdaterContract.json');

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
// var web3 = new Web3(Web3.givenProvider || `wss://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`);

var web3 = null;

if (process.env.NETWORK == 'development') {
  const WebsocketProvider = Web3.providers.WebsocketProvider;
  const websocketURL = "ws://127.0.0.1:8545"; // Replace with the appropriate WebSocket URL
  const websocketProvider = new WebsocketProvider(websocketURL);
  web3 = new Web3(websocketProvider);
} else if (process.env.NETWORK == 'goerli') {
  web3 = new Web3(Web3.givenProvider || `wss://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`);
}

// var web3 = new Web3(Web3.givenProvider || "http://127.0.0.1:8545");

const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

const updaterContractAddress = process.env.UPDATER_CONTRACT_ADDRESS;

const updater = new web3.eth.Contract(UpdaterContract.abi, updaterContractAddress);

/** 
 * Update Header
 * Summary: updating the blockheader
*/

web3.eth.getAccounts().then((accounts) => {
  console.log("accounts: ", accounts);
});

async function headerUpdate(proof, currBlockNumber, currBlockHeader, prevBlockNumber, prevBlockHeader) {
    try {
      // Convert the block headers to RLP-encoded bytes
      const currBlockHeaderBytes = RLP.encode([
        currBlockHeader.parentHash,
        currBlockHeader.sha3Uncles,
        currBlockHeader.miner,
        currBlockHeader.stateRoot,
        currBlockHeader.transactionsRoot,
        currBlockHeader.receiptsRoot,
        currBlockHeader.logsBloom,
        currBlockHeader.difficulty,
        currBlockHeader.number,
        currBlockHeader.gasLimit,
        currBlockHeader.gasUsed,
        currBlockHeader.timestamp,
        currBlockHeader.extraData,
        currBlockHeader.mixHash,
        currBlockHeader.nonce
      ]);

      const prevBlockHeaderBytes = RLP.encode([
        prevBlockHeader.parentHash,
        prevBlockHeader.sha3Uncles,
        prevBlockHeader.miner,
        prevBlockHeader.stateRoot,
        prevBlockHeader.transactionsRoot,
        prevBlockHeader.receiptsRoot,
        prevBlockHeader.logsBloom,
        prevBlockHeader.difficulty,
        prevBlockHeader.number,
        prevBlockHeader.gasLimit,
        prevBlockHeader.gasUsed,
        prevBlockHeader.timestamp,
        prevBlockHeader.extraData,
        prevBlockHeader.mixHash,
        prevBlockHeader.nonce
      ])

      const blockHeaderByteArray1 = new Uint8Array(600);
      blockHeaderByteArray1[499] = 1;

      const result = await updater.methods.headerUpdate(proof, currBlockNumber, blockHeaderByteArray1, prevBlockNumber, blockHeaderByteArray1).call({
        from: account.address,
      });
      
      console.log('Header update result:', result);

      console.log('calling getBlockHeader');
      const result2 = await updater.methods.getBlockHeaderCore(currBlockNumber).call({
        from: account.address,
      });
      console.log('getBlockHeader number:', currBlockNumber);
      console.log('getBlockHeader result:', result2);

    } catch (error) {
      console.error('Error during header update:', error);
    }
  }

var prevBlockHeader = {};

var proof = new Uint8Array(0);

var subscription = web3.eth.subscribe('newBlockHeaders', function(error, currBlockHeader){
    if (!error) {
        console.log("currBlockHeader: ", currBlockHeader)

        if (Object.keys(prevBlockHeader).length != 0) {
            // call headerUpdate
            // myContract.methods.headerUpdate(null, currBlockHeader, prevBlockHeader).send();

            console.log("currBlockHeader: ", currBlockHeader)
            // const proofAsHexString = web3.utils.toHex(JSON.stringify(proof));
            // const currBlockHeaderAsHexString = web3.utils.toHex(JSON.stringify(currBlockHeader));
            // const prevBlockHeaderAsHexString = web3.utils.toHex(JSON.stringify(prevBlockHeader));

            headerUpdate(proof, currBlockHeader.number, currBlockHeader, prevBlockHeader.number, prevBlockHeader);
        }

        prevBlockHeader = currBlockHeader;
        return;
    }

    console.error(error);
})
