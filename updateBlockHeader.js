const Web3 = require('web3');
const ethers = require('ethers');
require('dotenv').config();
const RLP = require('rlp');
const UpdaterContract = require('./build/contracts/UpdaterContract.json');

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;

var sender_web3 = null;
var reciever_web3 = null;

if (process.env.SENDER_NETWORK == 'development') {
  const WebsocketProvider = Web3.providers.WebsocketProvider;
  const websocketURL = "ws://127.0.0.1:7545"; // Replace with the appropriate WebSocket URL
  const websocketProvider = new WebsocketProvider(websocketURL);
  sender_web3 = new Web3(websocketProvider);
} else if (process.env.SENDER_NETWORK == 'goerli') {
  sender_web3 = new Web3(Web3.givenProvider || `wss://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`);
}

if (process.env.RECEIVER_NETWORK == 'development') {
  const WebsocketProvider = Web3.providers.WebsocketProvider;
  const websocketURL = "ws://127.0.0.1:7545"; // Replace with the appropriate WebSocket URL
  const websocketProvider = new WebsocketProvider(websocketURL);
  reciever_web3 = new Web3(websocketProvider);
} else if (process.env.RECEIVER_NETWORK == 'goerli') {
  reciever_web3 = new Web3(Web3.givenProvider || `wss://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`);
}

// var web3 = new Web3(Web3.givenProvider || "http://127.0.0.1:8545");

const account = reciever_web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
reciever_web3.eth.accounts.wallet.add(account);
reciever_web3.eth.defaultAccount = account.address;

const updaterContractAddress = process.env.UPDATER_CONTRACT_ADDRESS;

const updater = new reciever_web3.eth.Contract(UpdaterContract.abi, updaterContractAddress);

/** 
 * Update Header
 * Summary: updating the blockheader
*/

reciever_web3.eth.getAccounts().then((accounts) => {
  console.log("accounts: ", accounts);
});

function concatenateUint8Arrays(array1, array2) {
  const result = new Uint8Array(array1.length + array2.length);
  result.set(array1, 0);
  result.set(array2, array1.length);
  return result;
}

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

      const dummy = new Uint8Array(600).fill(0);
      
      const targetLength = 600;

      const currPadding = new Uint8Array(targetLength - currBlockHeaderBytes.length, 0);
      const fixedLengthCurrBlockHeaderBytes = concatenateUint8Arrays(currBlockHeaderBytes, currPadding);

      const prevPadding = new Uint8Array(targetLength - prevBlockHeaderBytes.length, 0);
      const fixedLengthPrevBlockHeaderBytes = concatenateUint8Arrays(prevBlockHeaderBytes, prevPadding);

      console.log(dummy);
      console.log(fixedLengthCurrBlockHeaderBytes);

      const result = await updater.methods.headerUpdate(proof, currBlockNumber, fixedLengthCurrBlockHeaderBytes, prevBlockNumber, fixedLengthPrevBlockHeaderBytes).send({
        from: account.address,
        gas: 2000000
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

var prevBlockHeader = {}

var subscription = sender_web3.eth.subscribe('newBlockHeaders', function(error, currBlockHeader){
    if (!error) {
        console.log("currBlockHeader: ", currBlockHeader)

        // TODO: currently a dummy proof, but can be replaced with proof API
        // const proof = await fetchProofData(prevBlockHeader, currBlockHeader);

        var proof = new Uint8Array(0);

        if (Object.keys(prevBlockHeader).length != 0) {
            // call headerUpdate

            console.log("currBlockHeader: ", currBlockHeader)

            headerUpdate(proof, currBlockHeader.number, currBlockHeader, prevBlockHeader.number, prevBlockHeader);
        }

        prevBlockHeader = currBlockHeader;
        return;
    }

    console.error(error);
})
