const Web3 = require('web3');
const LightClient = require('./build/contracts/LightClient.json');
const UpdaterContract = require('./build/contracts/UpdaterContract.json');

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const INFURA_API_KEY = process.env.INFURA_API_KEY;
// const etherscan_api_key = process.env.ETHERSCAN_API_KEY;
const web3 = new Web3(new Web3.providers.HttpProvider(`https://goerli.infura.io/v3/${INFURA_API_KEY}`));

const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

const lightClientAddress = '0x4a482E66849E01B91fe4E6dc8728B0285A89FD4F';
const updaterContractAddress = '0x92F77372b5338257fFd9A37754FD491ac4B9C5d7';

const lightClient = new web3.eth.Contract(LightClient.abi, lightClientAddress);
const updater = new web3.eth.Contract(UpdaterContract.abi, updaterContractAddress);

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
  
  headerUpdate(0, 1, 0);