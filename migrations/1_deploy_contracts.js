const LightClient = artifacts.require("LightClient");
const SourceChain = artifacts.require("SourceChain");
const UpdaterContract = artifacts.require("UpdaterContract");

module.exports = function(deployer, skippingBlocksPolicy) {
    deployer.deploy(LightClient);
    deployer.deploy(SourceChain);
    deployer.link(LightClient, UpdaterContract);
    deployer.link(SourceChain, UpdaterContract);
    deployer.deploy(UpdaterContract, skippingBlocksPolicy);
};
