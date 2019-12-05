const ConvertLib = artifacts.require("ConvertLib");
const Scam = artifacts.require("Scam");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, Scam);
  deployer.deploy(Scam);
};
