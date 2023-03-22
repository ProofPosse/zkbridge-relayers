const UpdaterContract = artifacts.require("UpdaterContract");

module.exports = function(deployer) {
  deployer.deploy(UpdaterContract);
};
