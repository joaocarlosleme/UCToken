var UCGToken = artifacts.require("./UCGToken.sol");
var UCPath = artifacts.require("./UCPath.sol");

contract('UCGToken', function(accounts) {
    var tokenInstance;
    var pathInstance;
    var ucPathAddress;

    it('initializes the contract with the correct values', function() {
        return UCGToken.deployed().then(function(instance) {
          tokenInstance = instance;
          return tokenInstance.name();
        }).then(function(name) {
          assert.equal(name, 'UCG', 'has the correct name');
          return tokenInstance.symbol();
        }).then(function(symbol) {
          assert.equal(symbol, 'UCG', 'has the correct symbol');
          return tokenInstance.standard();
        }).then(function(standard) {
          assert.equal(standard, 'UCG Token v1.0', 'has the correct standard');
          return tokenInstance.decimals();
        }).then(function(decimals) {
          assert.equal(decimals.toNumber(), 18, 'has the correct decimals');
        });
    });

    it('allocates the initial supply upon deployment', function() {
        return UCGToken.deployed().then(function(instance) {
            tokenInstance = instance;
            return tokenInstance.totalSupply();
        }).then(function(totalSupply) {
            assert.equal(totalSupply, 500000000*10**18, 'sets the total supply to 500M');
            return tokenInstance.balanceOf(accounts[0]);
        }).then(function(adminBalance) {
            assert.equal(adminBalance, 500000000*10**18, 'Correct balance (it does not allocates the initial supply to the admin account)'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
        });
    });

    it('check UCChangeable properly set', function() {
      return UCGToken.deployed().then(function(instance) {
        tokenInstance = instance;
        return tokenInstance.owner();
      }).then(function(_owner) {
        assert.equal(_owner, accounts[0], 'owner properly set');
        return UCPath.deployed();
      }).then(function(_pathInstance) {
          pathInstance = _pathInstance;
          return pathInstance.address;
      }).then(function(address) {
          ucPathAddress = address;
          return tokenInstance.ucPath();
      }).then(function(_ucPathaddress) {
          assert.equal(_ucPathaddress, ucPathAddress, 'ucPath set correctly');
      //     return tokenInstance.isContract(tokenInstance.address); // must make method public to test
      // }).then(function(isContract) {
      //     assert(isContract, 'isContract method working');
          return pathInstance.hasPath("UCToken");
      }).then(function(hasPath) {
          assert(hasPath, 'UCToken path initialized');
          return pathInstance.getPath("UCGToken");
      }).then(function(pathAddress) {
          assert.equal(pathAddress, tokenInstance.address, 'UCToken path address properly set');
          return pathInstance.isValid(tokenInstance.address);
      }).then(function(isValid) {
          assert(isValid, 'Contract address is valid');
      });
    });


});