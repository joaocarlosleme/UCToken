var UCToken = artifacts.require("./UCToken.sol");
var UCCrawlingBand = artifacts.require("./UCCrawlingBand.sol");
var UCTrade = artifacts.require("./UCTrade.sol");

contract('UCTrade', function(accounts) {
    var ucTokenInstance;
    var ucCrawlingBandInstance;
    var ucTradeInstace;
    var admin = accounts[0];
    var buyer = accounts[1];
    //var tokenPrice = 1000000000000000; // in wei
    //var tokensAvailable = 750000;
    //var numberOfTokens;
  
    it('initializes UCTrade the contract with the correct values', function() {
      return UCTrade.deployed().then(function(instance) {
        ucTradeInstace = instance;
        return ucTradeInstace.address
      }).then(function(address) {
        assert.notEqual(address, 0x0, 'has contract address');
        return ucTradeInstace.ucToken();
      }).then(function(address) {
        assert.notEqual(address, 0x0, 'has ucToken address');
        return ucTradeInstace.ucCrawlingBand();
      }).then(function(address) {
        assert.notEqual(address, 0x0, 'has ucCrawlingBand contract address');
        return ucTradeInstace.admin();
      }).then(function(address) {
        assert.equal(address, admin, 'admin set correctly');
      });
    });

    it('add collateral', function() {
      return UCTrade.deployed().then(function(instance) {
        ucTradeInstace = instance;
        return ucTradeInstace.address
      }).then(function(address) {
        assert.notEqual(address, 0x0, 'has contract address');
        return ucTradeInstace.ucToken();
      }).then(function(address) {
        assert.notEqual(address, 0x0, 'has ucToken address');
        return ucTradeInstace.ucCrawlingBand();
      }).then(function(address) {
        assert.notEqual(address, 0x0, 'has ucCrawlingBand contract address');
        return ucTradeInstace.admin();
      }).then(function(address) {
        assert.equal(address, admin, 'admin set correctly');
      });
    });
  
    
  });