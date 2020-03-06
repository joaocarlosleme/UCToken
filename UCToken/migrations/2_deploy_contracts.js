var UCToken = artifacts.require("./UCToken.sol");
var UCCrawlingBand = artifacts.require("./UCCrawlingBand.sol");
var UCTrade = artifacts.require("./UCTrade.sol");
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
  deployer.deploy(UCToken, 0).then(function() {
    return deployer.deploy(UCCrawlingBand);
  }).then(function() {
    //deployer.deploy(UCCollateralTokenInterface);
  	return deployer.deploy(SampleCollateralToken);
  }).then(function() {
  	return deployer.deploy(UCTrade, UCToken.address, UCCrawlingBand.address);
  });
};