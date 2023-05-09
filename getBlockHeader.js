const Web3 = require('web3');
require('dotenv').config();
const UpdaterContract = require('./build/contracts/UpdaterContract.json');

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;

var web3 = null;

if (process.env.NETWORK == 'development') {
  const WebsocketProvider = Web3.providers.WebsocketProvider;
  const websocketURL = "ws://127.0.0.1:8545";
  const websocketProvider = new WebsocketProvider(websocketURL);
  web3 = new Web3(websocketProvider);
} else if (process.env.NETWORK == 'goerli') {
  web3 = new Web3(Web3.givenProvider || `wss://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`);
}

const updaterContractAddress = process.env.UPDATER_CONTRACT_ADDRESS;

const updater = new web3.eth.Contract(UpdaterContract.abi, updaterContractAddress);

const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

/** 
 * Get Header
 * Summary: testing whether the blockheader is correct
*/

async function headerGet(blockNumber) {
    try {
      console.log('calling getBlockHeader');
      console.log("blockNumber", blockNumber)

      const result = await updater.methods.getBlockHeaderCore(blockNumber).call({
        from: account.address,
      });
      console.log('getBlockHeader result:', result);
    } catch (error) {
      console.error('Error during header update:', error);
    }
  }

// console.log("headerGet(117)")

headerGet(81)