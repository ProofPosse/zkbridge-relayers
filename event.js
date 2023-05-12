const Web3 = require('web3');
const ethers = require('ethers');
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
const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

const updaterContractAddress = process.env.UPDATER_CONTRACT_ADDRESS;

const updater = new web3.eth.Contract(UpdaterContract.abi, updaterContractAddress);

updater.events.HeaderUpdateEvent({}, (error, event) => {
    if (error) {
        console.error(error);
    } else {
        console.log("HeaderUpdateEvent:", event.returnValues);
    }
});

updater.events.HeaderUpdateCoreEvent({}, (error, event) => {
    if (error) {
        console.error(error);
    } else {
        console.log("headerUpdateCoreEvent:", event.returnValues);
    }
});


updater.events.HeaderGetEvent({}, (error, event) => {
    if (error) {
        console.error(error);
    } else {
        console.log("HeaderGetEvent:", event.returnValues);
    }
});
