var TokenCity = artifacts.require('TokenCity');

module.exports = async function (deployer) {
  await deployer.deploy(TokenCity)
};
