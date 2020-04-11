// var UCToken = artifacts.require("./UCToken.sol");
// var UCCrawlingBand = artifacts.require("./UCCrawlingBand.sol");
// var UCTrade = artifacts.require("./UCTrade.sol");
// var SampleCollateralToken = artifacts.require("./SampleCollateralToken.sol");

// contract('UCTrade', function(accounts) {
//     var ucTokenInstance;
//     var ucCrawlingBandInstance;
//     var sampleCollateralTokenInstance;
//     var ucTradeInstance;
//     var admin = accounts[0];
//     var buyer = accounts[1];
//     //var tokenPrice = 1000000000000000; // in wei
//     //var tokensAvailable = 750000;
//     //var numberOfTokens;

//     it('initializes UCTrade the contract with the correct values', function() {
//       return UCTrade.deployed().then(function(instance) {
//         ucTradeInstance = instance;
//         return ucTradeInstance.address
//       }).then(function(address) {
//         assert.notEqual(address, 0x0, 'has contract address');
//         return ucTradeInstance.ucToken();
//       }).then(function(address) {
//         assert.notEqual(address, 0x0, 'has ucToken address');
//         return ucTradeInstance.ucCrawlingBand();
//       }).then(function(address) {
//         assert.notEqual(address, 0x0, 'has ucCrawlingBand contract address');
//         return ucTradeInstance.admin();
//       }).then(function(address) {
//         assert.equal(address, admin, 'admin set correctly');
//       });
//     });

//     it('add collateral token', function() {
//       return SampleCollateralToken.deployed().then(function(instance) {
//         sampleCollateralTokenInstance = instance;
//         return ucTradeInstance.acceptNewCollateralToken(sampleCollateralTokenInstance.address, 10000); // price set to 0,1 dollar
//       }).then(function() {
//         return ucTradeInstance.collateralTokens(sampleCollateralTokenInstance.address);
//       }).then(function(colTokenStruct) {
//         assert.equal(colTokenStruct.price.toNumber(), 10000, 'collateral price properly set at 1 cent of dollar');
//         assert.equal(colTokenStruct.balance.toNumber(), 0, 'collateral balance correct');
//         assert.equal(colTokenStruct.tokenAddr, sampleCollateralTokenInstance.address, 'collateral address correct');
//       });
//     });

//     it('allow/approve Trade Contract to transfer collateral token', function() {
//       return sampleCollateralTokenInstance.approve.call(ucTradeInstance.address, '100000000000000000000').then(function(success) {
//         assert.equal(success, true, 'it returns true');
//         return sampleCollateralTokenInstance.approve(ucTradeInstance.address, '100000000000000000000');
//       }).then(function(receipt) {
//         assert.equal(receipt.logs.length, 1, 'triggers one event');
//       });
//     });

//     it('add minter', function() {
//       return UCToken.deployed().then(function(instance) {
//         ucTokenInstance = instance;
//         ucTokenInstance.addMinter(ucTradeInstance.address);
//       }).then(function() {
//         return ucTokenInstance.isMinter(ucTradeInstance.address);
//       }).then(function(result) {
//         assert.equal(result, true, 'minter added');
//       });
//     });

//     it('mint UC', function() {
//       return ucTradeInstance.mint.call(sampleCollateralTokenInstance.address, '100000000000000000000', '10').then(function(ucMintedAmount) {
//         //assert.equal(ucMintedAmount, 10000000000000000000, 'UC amount correct'); // must change return to uint256
//         assert.equal(ucMintedAmount, true, 'UC minted');
//         //console.log(ucMintedAmount);
//         return ucTradeInstance.mint(sampleCollateralTokenInstance.address, '100000000000000000000', '10');
//       }).then(function(receipt) {
//         assert.equal(receipt.logs.length, 1, 'triggers 1 events');
//       });
//     });

//     it('burn UC', function() {
//       return ucTradeInstance.burn.call('10000000000000000000', sampleCollateralTokenInstance.address).then(function(ucBurnedAmount) {
//         // let burnedAmount = parseFloat(ucBurnedAmount); // big wei number // must change return to uint256
//         // let expectedValue = parseFloat(90000000000000000000);
//         // assert.equal(burnedAmount, expectedValue, 'UC amount correct'); // must change return to uint256
//         assert.equal(ucBurnedAmount, true, 'UC burned');

//         return ucTradeInstance.burn('10000000000000000000', sampleCollateralTokenInstance.address);
//       }).then(function(receipt) {
//         console.log(receipt);
//       });
//     });


//   });