const LightClient = artifacts.require("LightClient");
const LightClientWithSkip = artifacts.require("LightClientWithSkip");
const SenderChain = artifacts.require("SenderChain");
const Merkle = artifacts.require("Merkle");
const UpdaterContract = artifacts.require("UpdaterContract");
const UpdaterContractWithSkip = artifacts.require("UpdaterContractWithSkip");

module.exports = function(deployer) {
    deployer.deploy(SenderChain);
    deployer.deploy(Merkle);

    deployer.deploy(LightClient);
    deployer.link(LightClient, UpdaterContract);
    deployer.link(SenderChain, UpdaterContract);
    deployer.link(Merkle, UpdaterContract);
    deployer.deploy(UpdaterContract);

    deployer.deploy(LightClientWithSkip);
    deployer.link(LightClientWithSkip, UpdaterContractWithSkip);
    deployer.link(SenderChain, UpdaterContractWithSkip);
    deployer.link(Merkle, UpdaterContractWithSkip);
    deployer.deploy(UpdaterContractWithSkip);
};
