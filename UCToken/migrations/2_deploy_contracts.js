var UCChangeable = artifacts.require("./UCChangeable.sol");
var UCPath = artifacts.require("./UCPath.sol");
var UCToken = artifacts.require("./UCToken.sol");
var UCGToken = artifacts.require("./UCGToken.sol");
var UCCrawlingBand = artifacts.require("./UCCrawlingBand.sol");
var UCMarketplace = artifacts.require("./UCMarketplace.sol");
var UCGovernance = artifacts.require("./UCGovernance.sol");
var UCMarketplace = artifacts.require("./UCMarketplace.sol");
var SampleCollateralToken = artifacts.require("./SampleCollateralToken.sol");
//var UCCollateralTokenInterface = artifacts.require("./UCCollateralTokenInterface.sol");

//var DappTokenSale = artifacts.require("./DappTokenSale.sol");

// module.exports = function(deployer) {
//   deployer.deploy(DappToken, 1000000).then(function() {
//     // Token price is 0.001 Ether
//     var tokenPrice = 1000000000000000;
//     return deployer.deploy(DappTokenSale, DappToken.address, tokenPrice);
//   }).then(function() {
//   	var tokensAvailable = 750000;
//   	DappToken.deployed().then(function(instance) { instance.transfer(DappTokenSale.address, tokensAvailable, { from: "0xE96362E717EAF828B7Ee752a12bAa03C967D410c" }); }) // done on test transfering from admin
//   });
// };

// module.exports = function(deployer) {
//   deployer.deploy(UCToken, 1000000);
//   // deployer.deploy(UCToken, 1000000).then(function() {
//   //   // Token price is 1 Ether (18 decimals)?
//   //   var tokenPrice = 1000000000000000000;
//   //   return deployer.deploy(DappTokenSale, DappToken.address, tokenPrice);
//   // });
// };

module.exports = function(deployer) {
  deployer.deploy(UCPath).then(function() {
    return deployer.deploy(UCToken, UCPath.address, 0);
  }).then(function() {
    //deployer.deploy(UCCollateralTokenInterface);
  	return deployer.deploy(UCGToken, UCPath.address);
  }).then(function() {
  	return deployer.deploy(UCCrawlingBand, 10, 11, UCPath.address);
  }).then(function() {
  	return deployer.deploy(UCMarketplace, UCPath.address);
  }).then(function() {
  	return deployer.deploy(UCGovernance, UCPath.address);
  });
};