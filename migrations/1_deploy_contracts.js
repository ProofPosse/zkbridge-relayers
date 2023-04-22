const LightClient = artifacts.require("LightClient");
const SenderChain = artifacts.require("SenderChain");
const UpdaterContract = artifacts.require("UpdaterContract");

module.exports = function(deployer) {
    deployer.deploy(LightClient);
    deployer.deploy(SenderChain);
    deployer.link(LightClient, UpdaterContract);
    deployer.link(SenderChain, UpdaterContract);
    deployer.deploy(UpdaterContract);
};
