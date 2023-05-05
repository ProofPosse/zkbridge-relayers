const LightClient = artifacts.require("LightClient");
const LightClientWithSkip = artifacts.require("LightClientWithSkip");
const SenderChain = artifacts.require("SenderChain");
const Merkle = artifacts.require("Merkle");
const UpdaterContract = artifacts.require("UpdaterContract");
const UpdaterContractWithSkip = artifacts.require("UpdaterContractWithSkip");

module.exports = function(deployer) {
    deployer.deploy(SenderChain);

    deployer.link(SenderChain, Merkle);
    deployer.deploy(Merkle);

    deployer.link(SenderChain, LightClient);
    deployer.deploy(LightClient);

    deployer.link(LightClient, UpdaterContract);
    deployer.link(SenderChain, UpdaterContract);
    deployer.link(Merkle, UpdaterContract);
    deployer.deploy(UpdaterContract);

    deployer.link(SenderChain, LightClientWithSkip);
    deployer.deploy(LightClientWithSkip);

    deployer.link(LightClientWithSkip, UpdaterContractWithSkip);
    deployer.link(SenderChain, UpdaterContractWithSkip);
    deployer.link(Merkle, UpdaterContractWithSkip);
    deployer.deploy(UpdaterContractWithSkip);
};
