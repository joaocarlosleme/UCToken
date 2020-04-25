var UCToken = artifacts.require("./UCToken.sol");
var UCPath = artifacts.require("./UCPath.sol");
//var UCTrade = artifacts.require("./UCTrade.sol");

contract('UCToken', function(accounts) {
    var tokenInstance;
    var pathInstance;
    var ucPathAddress;
    // /var ucTradeInstance;

    // it('sets the total supply upon deployment', function() {
    //     return UCToken.deployed().then(function(instance) {
    //       tokenInstance = instance;
    //       return tokenInstance.totalSupply();
    //     }).then(function(totalSupply) {
    //       assert.equal(totalSupply.toNumber(), 1000000, 'total supply is 1,000,000');
    //     });
    // });

    // it('allocates the initial supply upon deployment', function() {
    //     return UCToken.deployed().then(function(instance) {
    //       tokenInstance = instance;
    //       return tokenInstance.totalSupply();
    //     }).then(function(totalSupply) {
    //       assert.equal(totalSupply.toNumber(), 1000000, 'sets the total supply to 1,000,000');
    //       return tokenInstance.balanceOf(accounts[0]);
    //     }).then(function(adminBalance) {
    //       assert.equal(adminBalance.toNumber(), 1000000, 'it allocates the initial supply to the admin account'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
    //     });
    // });

    it('initializes the contract with the correct values', function() {
        return UCToken.deployed().then(function(instance) {
          tokenInstance = instance;
          return tokenInstance.name();
        }).then(function(name) {
          assert.equal(name, 'UC', 'has the correct name');
          return tokenInstance.symbol();
        }).then(function(symbol) {
          assert.equal(symbol, 'UC', 'has the correct symbol');
          return tokenInstance.standard();
        }).then(function(standard) {
          assert.equal(standard, 'UC Token v1.0', 'has the correct standard');
          return tokenInstance.decimals();
        }).then(function(decimals) {
          assert.equal(decimals.toNumber(), 18, 'has the correct decimals');
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
        });
      });

      it('allocates the initial supply upon deployment', function() {
        // return UCToken.deployed().then(function(instance) { // since tokenInstance has already been set there is no need to instanciate again
        //   tokenInstance = instance;
          return tokenInstance.totalSupply().then(function(totalSupply) {
          assert.equal(totalSupply.toNumber(), 0, 'total supply is ZERO (no token minted)');
          return tokenInstance.balanceOf(accounts[0]);
        }).then(function(adminBalance) {
          assert.equal(adminBalance.toNumber(), 0, 'Correct balance (it does not allocates the initial supply to the admin account)'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
        });
      });

      // it('add minter', function() {
      //   return UCTrade.deployed().then(function(instance) {
      //     ucTradeInstance = instance;
      //     tokenInstance.addMinter(ucTradeInstance.address);
      //     return tokenInstance.isMinter(ucTradeInstance.address);
      //   }).then(function(result) {
      //     assert.equal(result, true, 'minter added');
      //   });
      // });

      // it('transfers token ownership', function() {
      //   return UCToken.deployed().then(function(instance) {
      //     tokenInstance = instance;
      //     // Test `require` statement first by transferring something larger than the sender's balance
      //     return tokenInstance.transfer.call(accounts[1], 50000, { from: accounts[0] });
      //   }).then(function(success) {
      //     assert.equal(success, true, 'it returns true');
      //     return tokenInstance.transfer(accounts[1], 50000, { from: accounts[0] });
      //   }).then(function(receipt) {
      //     assert.equal(receipt.logs.length, 1, 'triggers one event');
      //     assert.equal(receipt.logs[0].event, 'Transfer', 'should be the "Transfer" event');
      //     assert.equal(receipt.logs[0].args._from, accounts[0], 'logs the account the tokens are transferred from');
      //     assert.equal(receipt.logs[0].args._to, accounts[1], 'logs the account the tokens are transferred to');
      //     assert.equal(receipt.logs[0].args._value, 50000, 'logs the transfer amount');
      //     return tokenInstance.balanceOf(accounts[1]);
      //   }).then(function(balance) {
      //     assert.equal(balance.toNumber(), 50000, 'adds the amount to the receiving account');
      //     return tokenInstance.balanceOf(accounts[0]);
      //   }).then(function(balance) {
      //     assert.equal(balance.toNumber(), 950000, 'deducts the amount from the sending account');
      //   });
      // });

      it('approves tokens for delegated transfer', function() {
        return UCToken.deployed().then(function(instance) {
          tokenInstance = instance;
          return tokenInstance.approve.call(accounts[1], 100);
        }).then(function(success) {
          assert.equal(success, true, 'it returns true');
          return tokenInstance.approve(accounts[1], 100, { from: accounts[0] });
        }).then(function(receipt) {
          assert.equal(receipt.logs.length, 1, 'triggers one event');
          assert.equal(receipt.logs[0].event, 'Approval', 'should be the "Approval" event');
          assert.equal(receipt.logs[0].args.owner, accounts[0], 'logs the account the tokens are authorized by');
          assert.equal(receipt.logs[0].args.spender, accounts[1], 'logs the account the tokens are authorized to');
          assert.equal(receipt.logs[0].args.value, 100, 'logs the transfer amount');
          return tokenInstance.allowance(accounts[0], accounts[1]);
        }).then(function(allowance) {
          assert.equal(allowance.toNumber(), 100, 'stores the allowance for delegated transfer');
        });
      });

      // it('handles delegated token transfers', function() {
      //   return UCToken.deployed().then(function(instance) {
      //     tokenInstance = instance;
      //     fromAccount = accounts[2];
      //     toAccount = accounts[3];
      //     spendingAccount = accounts[4];
      //     // Transfer some tokens to fromAccount
      //     return tokenInstance.transfer(fromAccount, 100, { from: accounts[0] });
      //   }).then(function(receipt) {
      //     // Approve spendingAccount to spend 10 tokens form fromAccount
      //     return tokenInstance.approve(spendingAccount, 10, { from: fromAccount });
      //   }).then(function(receipt) {
      //     // Try transferring something larger than the sender's balance
      //     return tokenInstance.transferFrom(fromAccount, toAccount, 9999, { from: spendingAccount });
      //   }).then(assert.fail).catch(function(error) {
      //     assert(error.message.indexOf('revert') >= 0, 'cannot transfer value larger than balance');
      //     // Try transferring something larger than the approved amount
      //     return tokenInstance.transferFrom(fromAccount, toAccount, 20, { from: spendingAccount });
      //   }).then(assert.fail).catch(function(error) {
      //     assert(error.message.indexOf('revert') >= 0, 'cannot transfer value larger than approved amount');
      //     return tokenInstance.transferFrom.call(fromAccount, toAccount, 10, { from: spendingAccount });
      //   }).then(function(success) {
      //     assert.equal(success, true);
      //     return tokenInstance.transferFrom(fromAccount, toAccount, 10, { from: spendingAccount });
      //   }).then(function(receipt) {
      //     assert.equal(receipt.logs.length, 1, 'triggers one event');
      //     assert.equal(receipt.logs[0].event, 'Transfer', 'should be the "Transfer" event');
      //     assert.equal(receipt.logs[0].args._from, fromAccount, 'logs the account the tokens are transferred from');
      //     assert.equal(receipt.logs[0].args._to, toAccount, 'logs the account the tokens are transferred to');
      //     assert.equal(receipt.logs[0].args._value, 10, 'logs the transfer amount');
      //     return tokenInstance.balanceOf(fromAccount);
      //   }).then(function(balance) {
      //     assert.equal(balance.toNumber(), 90, 'deducts the amount from the sending account');
      //     return tokenInstance.balanceOf(toAccount);
      //   }).then(function(balance) {
      //     assert.equal(balance.toNumber(), 10, 'adds the amount from the receiving account');
      //     return tokenInstance.allowance(fromAccount, spendingAccount);
      //   }).then(function(allowance) {
      //     assert.equal(allowance.toNumber(), 0, 'deducts the amount from the allowance');
      //   });
      // });

      it('check UCChangeable properly set', function() {
        return UCToken.deployed().then(function(instance) {
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
          assert.equal(hasPath, true, 'UCToken path initialized');
            return pathInstance.getPath("UCToken");
        }).then(function(pathAddress) {
            assert.equal(pathAddress, tokenInstance.address, 'UCToken path address properly set');
            return pathInstance.isValid(tokenInstance.address);
        }).then(function(isValid) {
          assert.equal(isValid, true, 'Contract address is valid');
        });
      });
})