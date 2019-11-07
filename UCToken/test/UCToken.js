var UCToken = artifacts.require("./UCToken.sol");

contract('UCToken', function(accounts) {
    var tokenInstance;

    it('sets the total supply upon deployment', function() {
        return UCToken.deployed().then(function(instance) {
          tokenInstance = instance;
          return tokenInstance.totalSupply();
        }).then(function(totalSupply) {
          assert.equal(totalSupply.toNumber(), 1000000, 'total supply is 1,000,000');
        });
    });
})