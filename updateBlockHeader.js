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

const lightClientAddress = '0x4a482E66849E01B91fe4E6dc8728B0285A89FD4F';
const updaterContractAddress = '0x92F77372b5338257fFd9A37754FD491ac4B9C5d7';

const lightClient = new web3.eth.Contract(LightClient.abi, lightClientAddress);
const updater = new web3.eth.Contract(UpdaterContract.abi, updaterContractAddress);

/** 
 * Update Header
 * Summary: updating the blockheader
*/

async function headerUpdate(proof, currBlockHeader, prevBlockHeader) {
    try {
      const result = await updater.methods.headerUpdate(proof, currBlockHeader, prevBlockHeader).send({
        from: account.address,
        gas: 5000000,
      });
      console.log('Header update result:', result);
    } catch (error) {
      console.error('Error during header update:', error);
    }
  }

var prevBlockHeader = {};

var proof = 0

var subscription = web3.eth.subscribe('newBlockHeaders', function(error, currBlockHeader){
    if (!error) {
        console.log(currBlockHeader);
        if (Object.keys(prevBlockHeader).length != 0) {
            // call headerUpdate
            // myContract.methods.headerUpdate(null, currBlockHeader, prevBlockHeader).send();

            const proofAsHexString = web3.utils.toHex(JSON.stringify(proof));
            const currBlockHeaderAsHexString = web3.utils.toHex(JSON.stringify(currBlockHeader));
            const prevBlockHeaderAsHexString = web3.utils.toHex(JSON.stringify(prevBlockHeader));

            headerUpdate(proofAsHexString, currBlockHeaderAsHexString, prevBlockHeaderAsHexString);
        }

        prevBlockHeader = currBlockHeader;
        return;
    }

    console.error(error);
})
