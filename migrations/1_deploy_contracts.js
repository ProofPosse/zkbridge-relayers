const LightClient = artifacts.require("LightClient");
const UpdaterContract = artifacts.require("UpdaterContract");

module.exports = function(deployer, skippingBlocksPolicy) {
    deployer.deploy(LightClient);
    deployer.link(LightClient, UpdaterContract);
    deployer.deploy(UpdaterContract, skippingBlocksPolicy);
};
