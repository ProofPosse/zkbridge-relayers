require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
 
//to fetch these keys from .env file
const privateKey = process.env.PRIVATE_KEY;
const infura_api_key = process.env.INFURA_API_KEY;
const etherscan_api_key = process.env.ETHERSCAN_API_KEY;
 
module.exports = {
  plugins: [
   'truffle-plugin-verify'
 ],
 api_keys: {
    etherscan: etherscan_api_key
  },
 
  networks: {
    goerli: {
      provider: () => new HDWalletProvider(privateKey, `https://goerli.infura.io/v3/${infura_api_key}`),
      network_id: 5, //Goerli's id
      gas: 5000000, //gas limit
      confirmations: 1,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
     },
  },
 
  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },
 
  // Configure your compilers
  compilers: {
    solc: {
      version: "^0.8.12",    // Fetch exact version from solc-bin (default: truffle's version)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        },
        evmVersion: "istanbul"
      }
    }
  },
  db: {
    enabled: false
  }
};
