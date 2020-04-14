var UCMarketplace = artifacts.require("./UCMarketplace.sol");
var UCPath = artifacts.require("./UCPath.sol");
var SampleCollateralToken = artifacts.require("./SampleCollateralToken.sol");
var UCToken = artifacts.require("./UCToken.sol");
var UCCrawlingBand = artifacts.require("./UCCrawlingBand.sol");

contract('UCMarketplace', function(accounts) {
    var marketplaceInstance;
    var pathInstance;
    var sampleTokenInstance;
    var ucTokenInstance;
    var crawlingBandInstance;

    var ucPathAddress;

    it('check UCChangeable properly set', function() {
        return UCMarketplace.deployed().then(function(instance) {
          marketplaceInstance = instance;
          return marketplaceInstance.owner();
        }).then(function(_owner) {
          assert.equal(_owner, accounts[0], 'owner properly set');
          return UCPath.deployed();
        }).then(function(_pathInstance) {
            pathInstance = _pathInstance;
            return pathInstance.address;
        }).then(function(address) {
            ucPathAddress = address;
            return marketplaceInstance.ucPath();
        }).then(function(_ucPathaddress) {
            assert.equal(_ucPathaddress, ucPathAddress, 'ucPath set correctly');
        //     return tokenInstance.isContract(tokenInstance.address); // must make method public to test
        // }).then(function(isContract) {
        //     assert(isContract, 'isContract method working');
            return pathInstance.hasPath("UCMarketplace");
        }).then(function(hasPath) {
            assert(hasPath, 'UCMarketplace path initialized');
            return pathInstance.getPath("UCMarketplace");
        }).then(function(pathAddress) {
            assert.equal(pathAddress, marketplaceInstance.address, 'UCMarketplace path address properly set');
            return pathInstance.isValid(marketplaceInstance.address);
        }).then(function(isValid) {
            assert(isValid, 'Contract address is valid');
        });
    });

    it('add and test new collateral', function() {
        return SampleCollateralToken.deployed().then(function(instance) {
          sampleTokenInstance = instance;
          return marketplaceInstance.acceptNewCollateral(sampleTokenInstance.address, 500000, false);
        }).then(function(receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'NewCollateral', 'should be the "NewCollateral" event');
            assert.equal(receipt.logs[0].args.tokenAddr, sampleTokenInstance.address, 'logs the new collateral address');
            assert.equal(receipt.logs[0].args.price, 500000, 'logs the price');
            assert.equal(receipt.logs[0].args.paused, false, 'logs the if collateral is paused');
            return marketplaceInstance.getCollateralsCount();
        }).then(function(count) {
            assert.equal(count, 1, '1 collateral registered');
            return marketplaceInstance.getCollateralAddressAtIndex(0);
        }).then(function(cAddress) {
            assert.equal(cAddress, sampleTokenInstance.address, 'Collateral at address 0 correct');
            return marketplaceInstance.getCollateralBalance(sampleTokenInstance.address, true);
        }).then(function(balance0) {
            assert.equal(balance0, 0, 'initial Collateral balance 0');
            return marketplaceInstance.getCollateralPrice(sampleTokenInstance.address);
        }).then(function(price) {
            assert.equal(price, 500000, 'price set correctly (call method)');
            return marketplaceInstance.collaterals(sampleTokenInstance.address);
        }).then(function(collateral) {
            assert.equal(collateral[1], 500000, 'price set correctly (call struct)');
            return marketplaceInstance.getCollateralRate(sampleTokenInstance.address);
        }).then(function(rate) {
            assert.equal(rate[0], 2, 'rate value correctly');
            assert(!rate[1], 'rate type set correctly');
            //return marketplaceInstance.getCollateralRate(sampleTokenInstance.address);
        });
    });

    it('approves collateral tokens for delegated transfer', function() {
        return sampleTokenInstance.approve(marketplaceInstance.address, "100000000000000000000", { from: accounts[0] }).then(function(receipt) {
          assert.equal(receipt.logs.length, 1, 'triggers one event');
          assert.equal(receipt.logs[0].event, 'Approval', 'should be the "Approval" event');
          assert.equal(receipt.logs[0].args.owner, accounts[0], 'logs the account the tokens are authorized by');
          assert.equal(receipt.logs[0].args.spender, marketplaceInstance.address, 'logs the account the tokens are authorized to');
          assert.equal(receipt.logs[0].args.value, "100000000000000000000", 'logs the transfer amount');
          return sampleTokenInstance.allowance(accounts[0], marketplaceInstance.address);
        }).then(function(allowance) {
          assert.equal(allowance, "100000000000000000000", 'stores the allowance for delegated transfer');
        });
      });

    it('mint', function() {
        return marketplaceInstance.mint(sampleTokenInstance.address, "20000000000000000000", "9000000000000000000").then(function(result) {
            assert(result, 'mint successfull');
            return marketplaceInstance.mint(sampleTokenInstance.address, "20000000000000000000", "11000000000000000000");
        }).then(assert.fail).catch(function(error) {
            assert(error.message.indexOf('revert') >= 0, 'Calculated UC amount below minimum');
        });
    });

    it('check UC Token', function() {
        return UCToken.deployed().then(function(instance) {
            ucTokenInstance = instance;
            return ucTokenInstance.totalSupply();
        }).then(function(_totalSupply) {
            assert.equal(_totalSupply, "10000000000000000000", 'UC Total Supply correct');
            return ucTokenInstance.balanceOf(accounts[0]);
        }).then(function(adminBalance) {
          assert.equal(adminBalance, "10000000000000000000", 'Correct balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
        });
    });

    it('check CrawlingBand', function() {
        return UCCrawlingBand.deployed().then(function(instance) {
            crawlingBandInstance = instance;
            return crawlingBandInstance.latestCeilingPrice();
        }).then(function(latestCeliningPrice) {
            console.log(latestCeliningPrice.toNumber());
            return crawlingBandInstance.getTimeStamp();
        }).then(function(timeStamp) {
            console.log(timeStamp.toNumber());
            return crawlingBandInstance.latestCeilingTime();
        }).then(function(latestCeilinigTIme) {
            console.log(latestCeilinigTIme.toNumber());
        //     return crawlingBandInstance.ucMarketplace.address;
        // }).then(function(marketPlacceAddress) {
        //     console.log(marketPlacceAddress);
        //     return crawlingBandInstance.init();
        // }).then(function() {
            return crawlingBandInstance.getUCMarketplaceAddress();
        }).then(function(marketPlacceAddress2) {
            console.log(marketPlacceAddress2);
        });
    });

    // it('add sale order', function() {
    //     return marketplaceInstance.addSaleOrder("5000000000000000000", 1000001, sampleTokenInstance.address, 3600).then(function(result) {
    //         assert(result, 'mint successfull');
    //         return marketplaceInstance.mint(sampleTokenInstance.address, "20000000000000000000", "11000000000000000000");
    //     }).then(function(_totalSupply) {
    //         assert.equal(_totalSupply, "10000000000000000000", 'UC Total Supply correct');
    //         return ucTokenInstance.balanceOf(accounts[0]);
    //     }).then(function(adminBalance) {
    //       assert.equal(adminBalance, "10000000000000000000", 'Correct balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
    //     });
    // });

});