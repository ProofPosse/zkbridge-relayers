const LightClient = artifacts.require("LightClient");
const SenderChain = artifacts.require("SenderChain");
const UpdaterContract = artifacts.require("UpdaterContract");

module.exports = function(deployer, skippingBlocksPolicy) {
    deployer.deploy(LightClient);
    deployer.deploy(SenderChain);
    deployer.link(LightClient, UpdaterContract);
    deployer.link(SenderChain, UpdaterContract);
    deployer.deploy(UpdaterContract, skippingBlocksPolicy);
};
