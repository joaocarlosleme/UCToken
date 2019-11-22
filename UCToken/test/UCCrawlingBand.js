var UCCrawlingBand = artifacts.require("./UCCrawlingBand.sol");

contract('UCCrawlingBand', function(accounts) {
    var tokenInstance;
    var ceilingPrice = 10000000; 
    var floorPrice = 9000000; 

    it('initializes the contract with the correct values', function() {
        return UCCrawlingBand.deployed().then(function(instance) {
          tokenInstance = instance;
          return tokenInstance.latestCeilingPrice();
        }).then(function(cPrice) {
          assert.equal(cPrice, ceilingPrice, 'starting ceiling price correct');
          return tokenInstance.latestFloorPrice();
        }).then(function(fPrice) {
          assert.equal(fPrice, floorPrice, 'starting floor price correct');
          return tokenInstance.getCurrentCeilingPrice();
        }).then(function(gcPrice) {
          assert.equal(gcPrice, ceilingPrice, 'getCeilingPrice working');
          return tokenInstance.getCurrentFloorPrice();
        }).then(function(gfPrice) {
          assert.equal(gfPrice, floorPrice, 'getFloorPrice working');
        });
      })

})