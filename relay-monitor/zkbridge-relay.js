var Web3 = require('web3');
var web3 = new Web3(Web3.givenProvider || "wss://eth-mainnet.g.alchemy.com/v2/Vef8FziF6ZX9cKubyNM9PILPsgBmXFSE");

//TODO
// const address = 
// const abi = 

myContract = new web3.eth.Contract(abi, address);
var prevBlockHeader = {};

var subscription = web3.eth.subscribe('newBlockHeaders', function(error, currBlockHeader){
    if (!error) {
        console.log(currBlockHeader);
        if (Object.keys(prevBlockHeader).length != 0) {
            // call headerUpdate
            myContract.methods.headerUpdate(null, currBlockHeader, prevBlockHeader).send();
        }
        
        // update prevblockheader
        prevBlockHeader = currBlockHeader;

        return;
    }

    console.error(error);
})
// .on("connected", function(subscriptionId){
//     console.log(subscriptionId);
// })
// .on("data", function(blockHeader){
//     // console.log(blockHeader);
//     // console.log(typeof(blockHeader));
//     // console.log("hi");
// })
// .on("error", console.error);

// unsubscribes the subscription
// subscription.unsubscribe(function(error, success){
//     if (success) {
//         console.log('Successfully unsubscribed!');
//     }
// });