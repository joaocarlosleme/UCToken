var UCPath = artifacts.require("./UCPath.sol");

contract('UCPath', function(accounts) {
    var ucPathInstance;

    it('initializes the contract with the correct values', function() {
        return UCPath.deployed().then(function(instance) {
            ucPathInstance = instance;
          return ucPathInstance.owner();
        }).then(function(_owner) {
            assert.equal(_owner, accounts[0], 'owner properly set');
        });
    });

    it('check UCChangeable properly set', function() {
        return UCPath.deployed().then(function(instance) {
            ucPathInstance = instance;
            return ucPathInstance.owner();
        }).then(function(_owner) {
            assert.equal(_owner, accounts[0], 'owner properly set');
            return ucPathInstance.ucPath();
        }).then(function(_ucPathaddress) {
            assert.equal(_ucPathaddress, ucPathInstance.address, 'ucPath set correctly');
        //     return tokenInstance.isContract(tokenInstance.address); // must make method public to test
        // }).then(function(isContract) {
        //     assert(isContract, 'isContract method working');
            return ucPathInstance.hasPath("UCPath");
        }).then(function(hasPath) {
            assert(hasPath, 'UCPath path initialized');
            return ucPathInstance.getPath("UCPath");
        }).then(function(pathAddress) {
            assert.equal(pathAddress, ucPathInstance.address, 'UCPath path address properly set');
            return ucPathInstance.isValid(ucPathInstance.address);
        }).then(function(isValid) {
            assert(isValid, 'Contract address is valid');
        });
      });

});