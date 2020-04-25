var UCGovernance = artifacts.require("./UCGovernance.sol");
var UCGToken = artifacts.require("./UCGToken.sol");
var UCPath = artifacts.require("./UCPath.sol");

contract('UCGovernance', function(accounts) {
    var ucGovInstance;
    var ucgTokenInstance;
    var ucPathInstance;

    it('initializes the contract with the correct values', function() {
        return UCGovernance.deployed().then(function(instance) {
            ucGovInstance = instance;
            return ucGovInstance.maxParticipation();
        }).then(function(maxP) {
            assert.equal(maxP, 7, 'maxParticipation correct');
            return UCGToken.deployed();
        }).then(function(instance) {
            ucgTokenInstance = instance;
            return ucGovInstance.ucgToken();
        }).then(function(ucgRef) {
            assert.equal(ucgRef, ucgTokenInstance.address, 'ucgToken reference set properly');
            return UCPath.deployed();
        }).then(function(instance) {
            ucPathInstance = instance;
            return ucGovInstance.ucPath();
        }).then(function(pathRef) {
            assert.equal(pathRef, ucPathInstance.address, 'ucPath reference set properly');
        });
    });

    var targetHash;
    var proposalHash;
    it('add change request (setPath UCToken to UCGToken Address)', function() {
        return ucGovInstance.createTarget(ucPathInstance.address, "setPath").then(function(target) {
            targetHash = target;
            return ucGovInstance.createProposalSetPath("UCToken", ucgTokenInstance.address);
        }).then(function(proposal) {
            proposalHash = proposal;
            return ucGovInstance.newChangeRequest(targetHash, proposal, 360, 1, "TEST setPath UCToken to UCGToken Address");
        }).then(function(receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'NewChangeRequest', 'should be the "NewChangeRequest" event');
        });
    });

    var changeRequestId;
    it('check CR', function() {
        return ucGovInstance.getChangeRequestsCount().then(function(count) {
            assert.equal(count, 1, "Change request count correct");
            return ucGovInstance.getChangeRequestKeyAtIndex(0);
        }).then(function(key) {
            changeRequestId = key;
            return ucGovInstance.changeRequestExits(changeRequestId);
        }).then(function(result) {
            assert.equal(result, true, 'CR Existis');
            return ucGovInstance.changeRequests(changeRequestId);
        }).then(function(CR) {
            assert.equal(CR[0], targetHash, "Target set correctly");
            assert.equal(CR[1], proposalHash, "Proposal set correctly");
            assert.equal(CR[2], 360, "safeDelay set correctly");
            assert.equal(CR[3], 0, "Status set correctly");
            assert.equal(CR[4], accounts[0], "createBy set correctly");
            assert.equal(CR[6], 1, "UIP set correctly");
            assert.equal(CR[7], "TEST setPath UCToken to UCGToken Address", "createBy set correctly");
            assert.equal(CR[8], 0, "votes set correctly");
            assert.equal(CR[9], 0, "votesAgainstWinner set correctly");
            //console.log("CR Status 0?: " + CR[3]);
        });
    });

    it('approves UCG tokens for delegated transfer', function() {
        return ucgTokenInstance.approve.call(ucGovInstance.address, "500000000000000000000", { from: accounts[0] }).then(function(success) {
          assert.equal(success, true, 'it returns true');
          return ucgTokenInstance.approve(ucGovInstance.address, "500000000000000000000", { from: accounts[0] });
        }).then(function(receipt) {
          assert.equal(receipt.logs.length, 1, 'triggers one event');
          assert.equal(receipt.logs[0].event, 'Approval', 'should be the "Approval" event');
          assert.equal(receipt.logs[0].args.owner, accounts[0], 'logs the account the tokens are authorized by');
          assert.equal(receipt.logs[0].args.spender, ucGovInstance.address, 'logs the account the tokens are authorized to');
          assert.equal(receipt.logs[0].args.value, "500000000000000000000", 'logs the transfer amount');
          return ucgTokenInstance.allowance(accounts[0], ucGovInstance.address);
        }).then(function(allowance) {
          assert.equal(allowance, "500000000000000000000", 'stores the allowance for delegated transfer');
        });
    });

    it('lock 500 tokens', function() {
        return ucGovInstance.lock("500000000000000000000").then(function(receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'Locked', 'should be the "Locked" event');
            return ucGovInstance.lockedUCGBalance(accounts[0]);
        }).then(function(balance) {
            assert.equal(balance, "500000000000000000000", 'Locked amount set correctly');
            return ucgTokenInstance.balanceOf(ucGovInstance.address);
        }).then(function(balance) {
            assert.equal(balance, "500000000000000000000", 'UGovernance contract balance set correctly');
        });
    });

    it('vote on CR', function() {
        return ucGovInstance.voteOnChangeRequest(changeRequestId).then(function(receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'NewVote', 'should be the "NewVote" event');
            return ucGovInstance.changeRequests(changeRequestId);
        }).then(function(CR) {
            assert.equal(CR[8], "500000000000000000000", "votes set correctly");
            assert.equal(CR[9], "500000000000000000000", "votesAgainstWinner set correctly");
        });
    });

    it('is Winner?', function() {
        return ucGovInstance.isWinner.call(changeRequestId).then(function(result) {
            assert.equal(result, false, 'Not winner - not enought votes');
        });
    });

    it('cancel vote on CR', function() {
        return ucGovInstance.cancelVoteOnChangeRequest(changeRequestId).then(function(receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'VoteCancelled', 'should be the "VoteCancelled" event');
            return ucGovInstance.changeRequests(changeRequestId);
        }).then(function(CR) {
            assert.equal(CR[8], "0", "votes set correctly");
            assert.equal(CR[9], "0", "votesAgainstWinner set correctly");
            return ucGovInstance.winnerRequestIdPerTarget(targetHash);
        }).then(function(key) {
            assert.equal(key, "0x0000000000000000000000000000000000000000000000000000000000000000", "No winner set for target yet")
        });
    });

})