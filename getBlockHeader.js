const Web3 = require('web3');
require('dotenv').config();
const UpdaterContract = require('./build/contracts/UpdaterContract.json');

const PRIVATE_KEY = process.env.PRIVATE_KEY;

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;

var reciever_web3 = null;

if (process.env.RECEIVER_NETWORK == 'development') {
  const WebsocketProvider = Web3.providers.WebsocketProvider;
  const websocketURL = "ws://127.0.0.1:7545"; // Replace with the appropriate WebSocket URL
  const websocketProvider = new WebsocketProvider(websocketURL);
  reciever_web3 = new Web3(websocketProvider);
} else if (process.env.RECEIVER_NETWORK == 'goerli') {
  reciever_web3 = new Web3(Web3.givenProvider || `wss://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`);
}

const account = reciever_web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
reciever_web3.eth.accounts.wallet.add(account);
reciever_web3.eth.defaultAccount = account.address;

const updaterContractAddress = process.env.UPDATER_CONTRACT_ADDRESS;

const updater = new reciever_web3.eth.Contract(UpdaterContract.abi, updaterContractAddress);

/** 
 * Get Header
 * Summary: testing whether the blockheader is correct
*/

async function headerGet(blockNumber) {
    try {
      console.log('Calling getBlockHeader');
      console.log("Block Number:", blockNumber)

      const result = await updater.methods.getBlockHeaderCore(blockNumber).call({
        from: account.address,
      });
      console.log('getBlockHeader result:', result);
    } catch (error) {
      console.error('Error during header update:', error);
    }
  }

const defaultBlockNumber = 1;

const blockNumber = process.argv[2] ? parseInt(process.argv[2]) : defaultBlockNumber;

headerGet(blockNumber);