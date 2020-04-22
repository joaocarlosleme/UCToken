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
    var seller = accounts[0];
    var buyer = accounts[1];

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
            console.log("Marketplace Collateral balance (0): " + balance0.toNumber());
            return marketplaceInstance.getCollateralPrice(sampleTokenInstance.address);
        }).then(function(price) {
            assert.equal(price, 500000, 'price set correctly (call method)');
            console.log("Collateral price 0,5UC (0,5 cents 6 decimals): " + price.toNumber());
            return marketplaceInstance.collaterals(sampleTokenInstance.address);
        }).then(function(collateral) {
            assert.equal(collateral[1], 500000, 'price set correctly (call struct)');
            return marketplaceInstance.getCollateralRate(sampleTokenInstance.address);
        }).then(function(rate) {
            assert.equal(rate[0], 2, 'rate value correctly');
            assert(!rate[1], 'rate type set correctly');
            console.log("Rate Collateral per UC (2): " + rate[0].toNumber());
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

    it('check Balances before mint', function() {
        return UCToken.deployed().then(function(instance) {
            ucTokenInstance = instance;
            return ucTokenInstance.totalSupply();
        }).then(function(_totalSupply) {
            assert.equal(_totalSupply, "0", 'UC Total Supply correct');
            console.log("UCToken total supply (0): " + _totalSupply.toNumber());
            return ucTokenInstance.balanceOf(accounts[0]);
        }).then(function(adminBalance) {
          assert.equal(adminBalance, "0", 'Correct balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Admin UC balace (0): " + adminBalance.toNumber());
          return sampleTokenInstance.totalSupply();
        }).then(function(_totalSupply) {
            assert.equal(_totalSupply, "100000000000000000000", 'Collateral Total Supply correct');
            console.log("Collateral total supply (100*10*18): " + _totalSupply);
            return sampleTokenInstance.balanceOf(accounts[0]);
        }).then(function(adminBalance) {
          assert.equal(adminBalance, "100000000000000000000", 'Correct Admin balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Admin Collateral balance (100*10**18): " + adminBalance);
          return sampleTokenInstance.balanceOf(marketplaceInstance.address);
        }).then(function(marketplaceBalance) {
          assert.equal(marketplaceBalance, "0", 'Correct Marketplace balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Marketplace Collateral balance (0): " + marketplaceBalance.toNumber());
        });
    });

    it('check CrawlingBand before mint', function() {
        return UCCrawlingBand.deployed().then(function(instance) {
            crawlingBandInstance = instance;
            return crawlingBandInstance.latestCeilingPrice();
        }).then(function(latestCeliningPrice) {
            console.log("latestCeliningPrice: " + latestCeliningPrice.toNumber());
            return crawlingBandInstance.latestFloorPrice();
        }).then(function(latestFloorPrice) {
            console.log("latestFloorPrice: " + latestFloorPrice.toNumber());
            return crawlingBandInstance.latestCeilingTime();
        }).then(function(latestCeilinigTIme) {
            console.log("latestCeilinigTime: " + latestCeilinigTIme.toNumber());
            return crawlingBandInstance.getTimeStamp();
        }).then(function(timeStamp) {
            console.log("Current TimeStamp: " + timeStamp.toNumber());
            return crawlingBandInstance.getEstimatedCeilingPrice();
        }).then(function(estimatedCeilingPrice) {
            console.log("estimatedCeilingPrice: " + estimatedCeilingPrice.toNumber());
            return crawlingBandInstance.getEstimatedFloorPrice();
        }).then(function(estimatedFloorPrice) {
            console.log("estimatedFloorPrice: " + estimatedFloorPrice.toNumber());
            return crawlingBandInstance.getUCMarketplaceAddress();
        }).then(function(marketPlacceAddress2) {
            assert.equal(marketPlacceAddress2, marketplaceInstance.address, "Init has been called and marketplace address set")

        });
    });

    it('mint 10 UCs in Exchange for 20 Collaterals', function() {
        return marketplaceInstance.mint(sampleTokenInstance.address, "20000000000000000000", "9000000000000000000").then(function(result) {
            assert(result, 'mint successfull');
            return marketplaceInstance.mint(sampleTokenInstance.address, "20000000000000000000", "11000000000000000000");
        }).then(assert.fail).catch(function(error) {
            assert(error.message.indexOf('revert') >= 0, 'Calculated UC amount below minimum');
        });
    });

    it('check Balances after mint', function() {
        return ucTokenInstance.totalSupply().then(function(_totalSupply) {
            assert.equal(_totalSupply, "10000000000000000000", 'UC Total Supply correct');
            console.log("UCToken total supply (10*10**18): " + _totalSupply);
            return ucTokenInstance.balanceOf(accounts[0]);
        }).then(function(adminBalance) {
          assert.equal(adminBalance, "10000000000000000000", 'Correct Admin UC balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Admin UC balance (10*10**18): " + adminBalance);
          return sampleTokenInstance.totalSupply();
        }).then(function(_totalSupply) {
            assert.equal(_totalSupply, "100000000000000000000", 'Collateral Total Supply correct');
            console.log("Collateral total supply (100*10*18): " + _totalSupply);
            return sampleTokenInstance.balanceOf(accounts[0]);
        }).then(function(adminBalance) {
          assert.equal(adminBalance, "80000000000000000000", 'Correct Admin collateral balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Admin Collateral balance (80*10**18): " + adminBalance);
          return sampleTokenInstance.balanceOf(marketplaceInstance.address);
        }).then(function(marketplaceBalance) {
          assert.equal(marketplaceBalance, "20000000000000000000", 'Correct Marketplace balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Marketplace Collateral balance (20*10**18): " + marketplaceBalance);
          return marketplaceInstance.getCollateralBalance(sampleTokenInstance.address, false);
        }).then(function(marketplaceBalance) {
          assert.equal(marketplaceBalance, "20000000000000000000", 'Correct Marketplace balance from getCollateralBalance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Marketplace Collateral balance from getCollateralBalance (20*10**18): " + marketplaceBalance);
          return marketplaceInstance.getReservesBalance();
        }).then(function(totalBalance) {
          assert.equal(totalBalance, "10000000", 'Correct Marketplace total balance in USD'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Marketplace total balance in USD (10*10**6): " + totalBalance);
        });
    });

    it('check CrawlingBand after mint', function() {
        return crawlingBandInstance.latestCeilingPrice().then(function(latestCeliningPrice) {
            console.log("latestCeliningPrice: " + latestCeliningPrice.toNumber());
            return crawlingBandInstance.latestFloorPrice();
        }).then(function(latestFloorPrice) {
            console.log("latestFloorPrice: " + latestFloorPrice.toNumber());
            return crawlingBandInstance.latestCeilingTime();
        }).then(function(latestCeilinigTIme) {
            console.log("latestCeilinigTime: " + latestCeilinigTIme.toNumber());
            return crawlingBandInstance.getTimeStamp();
        }).then(function(timeStamp) {
            console.log("Current TimeStamp: " + timeStamp.toNumber());
            return crawlingBandInstance.getEstimatedCeilingPrice();
        }).then(function(estimatedCeilingPrice) {
            console.log("estimatedCeilingPrice: " + estimatedCeilingPrice.toNumber());
            return crawlingBandInstance.getEstimatedFloorPrice();
        }).then(function(estimatedFloorPrice) {
            console.log("estimatedFloorPrice: " + estimatedFloorPrice.toNumber());
            return crawlingBandInstance.getUCMarketplaceAddress();
        }).then(function(marketPlacceAddress2) {
            assert.equal(marketPlacceAddress2, marketplaceInstance.address, "Init has been called and marketplace address set")
        });
    });

    it('approves UCTokens for delegated transfer', function() {
        return ucTokenInstance.approve(marketplaceInstance.address, "100000000000000000000", { from: accounts[0] }).then(function(receipt) {
          assert.equal(receipt.logs.length, 1, 'triggers one event');
          assert.equal(receipt.logs[0].event, 'Approval', 'should be the "Approval" event');
          assert.equal(receipt.logs[0].args.owner, accounts[0], 'logs the account the tokens are authorized by');
          assert.equal(receipt.logs[0].args.spender, marketplaceInstance.address, 'logs the account the tokens are authorized to');
          assert.equal(receipt.logs[0].args.value, "100000000000000000000", 'logs the transfer amount');
          return ucTokenInstance.allowance(accounts[0], marketplaceInstance.address);
        }).then(function(allowance) {
          assert.equal(allowance, "100000000000000000000", 'stores the allowance for delegated transfer');
        });
      });

    it('add sale order', function() {
        return marketplaceInstance.addSaleOrder("5000000000000000000", 900000, sampleTokenInstance.address, 3600).then(function(receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'OrderBookChange', 'should be the "OrderBookChange" event');
        });
    });

    it('add balance for account 2 (2nd buyer) and allowance for marketplace', function() {
        return sampleTokenInstance.transfer(buyer, "50000000000000000000", { from: seller }).then(function(receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'Transfer', 'should be the "Transfer" event');
            return sampleTokenInstance.approve(marketplaceInstance.address, "50000000000000000000", { from: buyer });
        }).then(function(receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'Approval', 'should be the "Approval" event');
        });
    });

    it('check Balances before Sale Order Match', function() {
        return sampleTokenInstance.balanceOf(accounts[0]).then(function(adminBalance) {
          assert.equal(adminBalance, "30000000000000000000", 'Correct Admin collateral balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Seller (account[0]) Collateral balance (30*10**18): " + adminBalance);
          return sampleTokenInstance.balanceOf(accounts[1]);
        }).then(function(buyerBalance) {
          assert.equal(buyerBalance, "50000000000000000000", 'Correct Buyer collateral balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Buyer (accounts[1]) Collateral balance (50*10**18): " + buyerBalance);
          return ucTokenInstance.balanceOf(accounts[0]);
        }).then(function(adminBalance) {
          assert.equal(adminBalance, "5000000000000000000", 'Correct Admin UC balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Admin UC balance (5*10**18): " + adminBalance);
          return ucTokenInstance.balanceOf(accounts[1]);
        }).then(function(buyerBalance) {
          assert.equal(buyerBalance, "0", 'Correct Admin UC balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Byuer UC balance (0): " + buyerBalance);
          return ucTokenInstance.balanceOf(marketplaceInstance.address);
        }).then(function(marketplaceBalance) {
          assert.equal(marketplaceBalance, "5000000000000000000", 'Correct Marketplace UC balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Marketplace UC balance (5*10**18): " + marketplaceBalance);
        });
    });

    it('match sale order', function() {
        return marketplaceInstance.getSaleOrdersCount().then(function(result) {
            assert.equal(result, 1, '1 sale order');
            return marketplaceInstance.addCollateral(sampleTokenInstance.address, "9000000000000000000", { from: buyer });
        }).then(function(receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'Deposit', 'should be the "Deposit" event');
            return marketplaceInstance.getCollateralBalance(sampleTokenInstance.address, false);
        }).then(function(marketplaceBalance) {
            assert.equal(marketplaceBalance, "20000000000000000000", 'Correct Marketplace balance from getCollateralBalance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
            console.log("Marketplace Collateral balance from getCollateralBalance (-Orderbook) (20*10**18): " + marketplaceBalance);
            return marketplaceInstance.getCollateralBalance(sampleTokenInstance.address, true);
        }).then(function(marketplaceBalance) {
            assert.equal(marketplaceBalance, "29000000000000000000", 'Correct Marketplace balance from getCollateralBalance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
            console.log("Marketplace Collateral balance from getCollateralBalance (+Orderbook) (29*10**18): " + marketplaceBalance);
            return marketplaceInstance.getSaleOrderKeyAtIndex(0);
        }).then(function(saleOrderKey) {
            return marketplaceInstance.matchSaleOrder(saleOrderKey, sampleTokenInstance.address, "9000000000000000000", { from: buyer });
        }).then(function(receipt) {
            assert.equal(receipt.logs.length, 2, 'triggers two events');
            assert.equal(receipt.logs[1].event, 'OrderBookChange', 'should be the "OrderBookChange" event');
            return marketplaceInstance.getCollateralBalance(sampleTokenInstance.address, true);
        }).then(function(marketplaceBalance) {
            assert.equal(marketplaceBalance, "20000000000000000000", 'Correct Marketplace balance from getCollateralBalance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
            console.log("Marketplace Collateral balance from getCollateralBalance (+Orderbook) (20*10**18): " + marketplaceBalance);
        });
    });

    it('check Balances after Sale Order Match', function() {
        return sampleTokenInstance.balanceOf(accounts[0]).then(function(adminBalance) {
          assert.equal(adminBalance, "39000000000000000000", 'Correct Admin collateral balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Seller (account[0]) Collateral balance (39*10**18): " + adminBalance);
          return sampleTokenInstance.balanceOf(accounts[1]);
        }).then(function(buyerBalance) {
          assert.equal(buyerBalance, "41000000000000000000", 'Correct Buyer collateral balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Buyer (accounts[1]) Collateral balance (41*10**18): " + buyerBalance);
          return sampleTokenInstance.balanceOf(marketplaceInstance.address);
        }).then(function(marketplaceBalance) {
          assert.equal(marketplaceBalance, "20000000000000000000", 'Correct Marketplace balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Marketplace Collateral balance (20*10**18): " + marketplaceBalance);
          return ucTokenInstance.balanceOf(accounts[0]);
        }).then(function(adminBalance) {
          assert.equal(adminBalance, "5000000000000000000", 'Correct Admin UC balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Admin UC balance (5*10**18): " + adminBalance);
          return ucTokenInstance.balanceOf(accounts[1]);
        }).then(function(buyerBalance) {
          assert.equal(buyerBalance, "5000000000000000000", 'Correct Admin UC balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Byuer UC balance (5*10**18): " + buyerBalance);
          return ucTokenInstance.balanceOf(marketplaceInstance.address);
        }).then(function(marketplaceBalance) {
          assert.equal(marketplaceBalance, "0", 'Correct Marketplace UC balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Marketplace UC balance (0): " + marketplaceBalance);
          return ucTokenInstance.totalSupply();
        }).then(function(_totalSupply) {
            assert.equal(_totalSupply, "10000000000000000000", 'UC Total Supply correct');
            console.log("UCToken total supply (10*10**18): " + _totalSupply);
        });
    });

    it('check CrawlingBand before burn', function() {
        return crawlingBandInstance.latestCeilingPrice().then(function(latestCeliningPrice) {
            console.log("latestCeliningPrice: " + latestCeliningPrice.toNumber());
            return crawlingBandInstance.latestFloorPrice();
        }).then(function(latestFloorPrice) {
            console.log("latestFloorPrice: " + latestFloorPrice.toNumber());
            return crawlingBandInstance.latestCeilingTime();
        }).then(function(latestCeilinigTIme) {
            console.log("latestCeilinigTime: " + latestCeilinigTIme.toNumber());
            return crawlingBandInstance.getTimeStamp();
        }).then(function(timeStamp) {
            console.log("Current TimeStamp: " + timeStamp.toNumber());
            return crawlingBandInstance.getEstimatedCeilingPrice();
        }).then(function(estimatedCeilingPrice) {
            console.log("estimatedCeilingPrice: " + estimatedCeilingPrice.toNumber());
            return crawlingBandInstance.getEstimatedFloorPrice();
        }).then(function(estimatedFloorPrice) {
            console.log("estimatedFloorPrice: " + estimatedFloorPrice.toNumber());
            return crawlingBandInstance.getUCMarketplaceAddress();
        }).then(function(marketPlacceAddress2) {
            assert.equal(marketPlacceAddress2, marketplaceInstance.address, "Init has been called and marketplace address set")
        });
    });

    it('burn 2 UCs in Exchange for at least 3,6 Collaterals', function() {
        return marketplaceInstance.burn("2000000000000000000", sampleTokenInstance.address).then(function(result) {
            assert(result, 'burn successfull');
        });
    });

    it('check Balances after Burn', function() {
        return sampleTokenInstance.balanceOf(accounts[0]).then(function(adminBalance) {
          assert(adminBalance >= "42600000000000000000", 'Correct Admin collateral balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Seller (account[0]) Collateral balance >= (42,6*10**18): " + adminBalance);
          return sampleTokenInstance.balanceOf(accounts[1]);
        }).then(function(buyerBalance) {
          assert.equal(buyerBalance, "41000000000000000000", 'Correct Buyer collateral balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Buyer (accounts[1]) Collateral balance (41*10**18): " + buyerBalance);
          return sampleTokenInstance.balanceOf(marketplaceInstance.address);
        }).then(function(marketplaceBalance) {
          assert(marketplaceBalance <= "16400000000000000000", 'Correct Marketplace balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Marketplace Collateral balance <= (16,4*10**18): " + marketplaceBalance);
          return ucTokenInstance.balanceOf(accounts[0]);
        }).then(function(adminBalance) {
          assert.equal(adminBalance, "3000000000000000000", 'Correct Admin UC balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Admin UC balance (3*10**18): " + adminBalance);
          return ucTokenInstance.balanceOf(accounts[1]);
        }).then(function(buyerBalance) {
          assert.equal(buyerBalance, "5000000000000000000", 'Correct Admin UC balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Byuer UC balance (5*10**18): " + buyerBalance);
          return ucTokenInstance.balanceOf(marketplaceInstance.address);
        }).then(function(marketplaceBalance) {
          assert.equal(marketplaceBalance, "0", 'Correct Marketplace UC balance'); // jon note - fixed here because it must alocate to contract address. On migration we changed and alocated 750000 to contract adress leaving only 250k to admin
          console.log("Marketplace UC balance (0): " + marketplaceBalance);
          return ucTokenInstance.totalSupply();
        }).then(function(_totalSupply) {
          assert.equal(_totalSupply, "8000000000000000000", 'UC Total Supply correct');
          console.log("UCToken total supply (8*10**18): " + _totalSupply);
          return marketplaceInstance.getReservesBalance();
        }).then(function(totalBalance) {
          console.log("Marketplace total balance in USD (> 8,19*10**6): " + totalBalance);
        });
    });

    it('check CrawlingBand after burn', function() {
        return crawlingBandInstance.latestCeilingPrice().then(function(latestCeliningPrice) {
            console.log("latestCeliningPrice: " + latestCeliningPrice.toNumber());
            return crawlingBandInstance.latestFloorPrice();
        }).then(function(latestFloorPrice) {
            console.log("latestFloorPrice: " + latestFloorPrice.toNumber());
            return crawlingBandInstance.latestCeilingTime();
        }).then(function(latestCeilinigTIme) {
            console.log("latestCeilinigTime: " + latestCeilinigTIme.toNumber());
            return crawlingBandInstance.getTimeStamp();
        }).then(function(timeStamp) {
            console.log("Current TimeStamp: " + timeStamp.toNumber());
            return crawlingBandInstance.getEstimatedCeilingPrice();
        }).then(function(estimatedCeilingPrice) {
            console.log("estimatedCeilingPrice: " + estimatedCeilingPrice.toNumber());
            return crawlingBandInstance.getEstimatedFloorPrice();
        }).then(function(estimatedFloorPrice) {
            console.log("estimatedFloorPrice: " + estimatedFloorPrice.toNumber());
            return crawlingBandInstance.getUCMarketplaceAddress();
        }).then(function(marketPlacceAddress2) {
            assert.equal(marketPlacceAddress2, marketplaceInstance.address, "Init has been called and marketplace address set")
        });
    });

});