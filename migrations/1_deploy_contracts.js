const LightClient = artifacts.require("LightClient");
const UpdaterContract = artifacts.require("UpdaterContract");

module.exports = function(deployer) {
    deployer.deploy(LightClient);
    deployer.link(LightClient, UpdaterContract);
    deployer.deploy(UpdaterContract);
};
