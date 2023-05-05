const Web3 = require('web3');
require('dotenv').config();
const LightClient = require('./build/contracts/LightClient.json');
const UpdaterContract = require('./build/contracts/UpdaterContract.json');

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
var web3 = new Web3(Web3.givenProvider || `wss://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`);

const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

const updaterContractAddress = process.env.UPDATER_CONTRACT_ADDRESS;

const updater = new web3.eth.Contract(UpdaterContract.abi, updaterContractAddress);

/** 
 * Get Header
 * Summary: testing whether the blockheader is correct
*/

async function headerGet(blockNumber) {
    try {
      console.log('calling getBlockHeader');
      const result = await updater.methods.getBlockHeader(blockNumber).send({
        from: account.address,
        gas: 5000000,
      });
      console.log('getBlockHeader result:', result);
    } catch (error) {
      console.error('Error during header update:', error);
    }
  }

headerGet(8943335)