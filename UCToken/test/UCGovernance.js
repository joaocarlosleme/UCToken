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
            assert(result, 'CR Existis');
            return ucGovInstance.changeRequests(changeRequestId);
        }).then(function(CR) {
            assert.equal(CR[0], targetHash, "Target set correctly");
            assert.equal(CR[1], proposalHash, "Proposal set correctly");
            assert.equal(CR[2], 360, "safeDelay set correctly");
            //assert.equal(CR[3], 0, "Status set correctly");
            console.log("CR Status 0?: " + CR[3]);
        });
    });

})