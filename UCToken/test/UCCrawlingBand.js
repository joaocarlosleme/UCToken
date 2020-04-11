var UCCrawlingBand = artifacts.require("./UCCrawlingBand.sol");

contract('UCCrawlingBand', function(accounts) {
    var ucCBInstance;

    it('initializes the contract with the correct values', function() {
        return UCCrawlingBand.deployed().then(function(instance) {
          ucCBInstance = instance;
          return ucCBInstance.latestCeilingPrice();
        }).then(function(cPrice0) {
          assert.equal(cPrice0, 0, 'starting latestCeiling price correct');
          return ucCBInstance.getEstimatedCeilingPrice();
        }).then(function(cPrice1) {
          assert(cPrice1 == 1*10**6, 'starting estimated ceiling price correct');
          return ucCBInstance.latestFloorPrice();
        }).then(function(fPrice0) {
          assert.equal(fPrice0, 0, 'starting latestFloor price correct');
          return ucCBInstance.getEstimatedFloorPrice();
        }).then(function(fPrice1) {
          assert(fPrice1 == 9*10**5, 'starting estimated floor price correct');
          return ucCBInstance.getCurrentFloorPrice();
        });
      })

})