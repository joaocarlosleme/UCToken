pragma solidity >=0.4.21 <0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libraries/UnorderedKeySet.sol";
import "./UCGToken.sol";
import "./UCChangeable.sol";

contract UCGovernance is UCChangeable {
    using SafeMath for uint256;
    using UnorderedKeySetLib for UnorderedKeySetLib.Set;

    /// Public Properties
    //address public ucgTokenAddress;
    uint256 public maxParticipation; // max number of active requests a user can vote at the same time

    /// Contract Navigation Properties
    UCGToken public ucgToken;

    /// Enums
    enum CRStatus {
        PendingApproval,                    // Default value
        Approved,                           // Winner pending use
        Applied,                            // already used/completed
        Replaced,                           // was an winner but has been replaced
        Expired,                            // CR has already expired
        Closed,                             //
        Cancelled                           // CR has been cancelled
    }

    /// Objects (Structs)
    struct ChangeRequest {
        // address contractAddress;
        // string functionName;
        // string parameters;
        // string notes;
        bytes32 target; // hash of the contractAddress and method name
        bytes32 proposal; // hash of the proposal (parameter values)
        uint256 safeDelay; // time the request need to wait after its approved before its applied
        CRStatus status;
        address createBy; // address of msg.sender that created the cr
        uint256 createdOn; // time the cr was created
        uint256 UIPNumber;
        string notes; // in case of no UIP info
        uint256 votes; // total votes
        uint256 votesAgainstWinner; // total votes plus votes that user has on winner target
        mapping (address => uint256) userVotes; // votes per user
        mapping (address => uint256) userVotesAgainstWinner; // votes per userplus votes that user has on winner target
    }
    // // Change Request Requirements
    // struct ChangeRequestReq {
    //     uint X;                     // number 1 to 100
    //     uint quorum;                     // number 1 to 100
    //     address contractAddress;
    //     string methodName;
    // }

    /// Public Mappings
    mapping(bytes32 => ChangeRequest) public changeRequests; // where bytes32 is a unique ID for the changeRequest (hash of target+proposal+now)
    mapping(address=>uint256) public lockedUCGBalance;
    mapping(bytes32 => bytes32) public winnerRequestIdPerTarget; // maps target to winner ChangeRequest key

    /// Internal Mappings
    mapping(address => UnorderedKeySetLib.Set) internal userParticipations;  // list of user participation on change requests

    /// Private lists
    UnorderedKeySetLib.Set changeRequestsSet; // list of change requests

    constructor(address pathAddress) UCChangeable(pathAddress, "UCGovernance") public {
        ucgToken = UCGToken(ucPath.getPath("UCGToken"));
        maxParticipation = 7; // initial value
    }

    /// Public TEST ONLY Functions
    function createTarget(address targetContract, string memory methodName) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(targetContract, methodName));
    }
    function createProposalSetPath(string memory pathName, address newAddress) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(pathName, newAddress));
    }

    /// Public View Functions

    function getChangeRequestsCount() public view returns(uint) {
        return changeRequestsSet.count();
    }
    function getChangeRequestKeyAtIndex(uint _index) public view returns(bytes32) {
        return changeRequestsSet.keyAtIndex(_index);
    }
    function changeRequestExits(bytes32 _key) public view returns(bool) {
        return changeRequestsSet.exists(_key);
    }

    /// Public Functions
    function lock(uint256 _amount) public {
        // transfer to collateral reserves
        require(ucgToken.transferFrom(msg.sender, address(this), _amount), "Transfer of UCGTokens failed.");
        // credit collateral balance to user
        lockedUCGBalance[msg.sender] = lockedUCGBalance[msg.sender].add(_amount);

        emit Locked(msg.sender, _amount);
    }
    function unlock(uint256 _amount) public {
        // debit amount from user lockedUCGBalance (it will fail if not enough balance)
        lockedUCGBalance[msg.sender] = lockedUCGBalance[msg.sender].sub(_amount, "Not enough balance");
        // transfer UCG to user
        require(ucgToken.transfer(msg.sender, _amount), "Transfer of UCGTokens failed.");
        // to go over the loop and delete votes
        // check how many requests user is participating already
        UnorderedKeySetLib.Set storage p = userParticipations[msg.sender];
        for( uint i = 0; i < p.count(); i++) {
            reduceVoteOnChangeRequest(p.keyAtIndex(i), _amount);
        }

        emit Unlocked(msg.sender, _amount);
    }

    function newChangeRequest(bytes32 _target, bytes32 _proposal, uint256 _safeDelay, uint256 _UIPNumber, string memory _notes) public {
        bytes32 crID = keccak256(abi.encodePacked(_target, _proposal, now));
        changeRequestsSet.insert(crID); // Note that this will fail automatically if the key already exists.

        changeRequests[crID] = ChangeRequest({
            target: _target,
            proposal: _proposal,
            safeDelay: _safeDelay,
            status: CRStatus.PendingApproval,
            createBy: msg.sender,
            createdOn: now,
            UIPNumber: _UIPNumber,
            notes: _notes,
            votes: 0,
            votesAgainstWinner: 0
        });

        emit NewChangeRequest(_target, _proposal, msg.sender, _UIPNumber, _notes);
    }

    function voteOnChangeRequest(bytes32 _key) public {
        voteOnChangeRequest(_key, lockedUCGBalance[msg.sender]);
    }
    function voteOnChangeRequest(bytes32 _key, uint256 _amount) public {
        // require vote > 0
        require(_amount > 0, "Invalid amount"); // see link and test https://ethereum.stackexchange.com/q/33832/20639
        // check if change request exist
        require(changeRequestsSet.exists(_key), "ChangeRequest doesn't exist");
        // check if amount is not higher than locked UCGs
        require(_amount <= lockedUCGBalance[msg.sender], "Not enough balance to vote");
        // check how many requests user is participating already
        UnorderedKeySetLib.Set storage p = userParticipations[msg.sender];
        // check if is updating vote
        if(!p.exists(_key)) {
            // if doesn't exist need to check if there is room to add
            require(p.count() <= maxParticipation, "Max participation reached");
            p.insert(_key);
        }
        // add votes to request
        ChangeRequest storage cr = changeRequests[_key];
        // check if there is already a vote from this user
        uint256 currentVotes = cr.userVotes[msg.sender];
        uint256 currentVotesAgainstWinner = cr.userVotesAgainstWinner[msg.sender];
        if(currentVotes > 0)
        {
            cr.votes = cr.votes.sub(currentVotes);
            cr.votesAgainstWinner = cr.votesAgainstWinner.sub(currentVotesAgainstWinner);
        }
        cr.userVotes[msg.sender] = _amount;
        cr.userVotesAgainstWinner[msg.sender] = _amount;
        cr.votes = cr.votes.add(_amount);
        cr.votesAgainstWinner = cr.votesAgainstWinner.add(_amount);

        //// add votes against winner
        uint256 wv = 0;
        // make sure current request is not winner request
        if(_key != winnerRequestIdPerTarget[cr.target]) {
            // ChangeRequest storage wr = ChangeRequests[winnerRequestIdPerTarget[c.target]]; // locate winner
            // if(wr.target == cr.target) { // check if wr exist (initialized)
            //     uint256 wv = wr.userVotes[msg.sender]; // check if user has voted on winner request
            //     if(wv != 0) {
            //         cr.userVotesAgainstWinner[msg.sender] = cr.userVotesAgainstWinner[msg.sender].add(wv);
            //         cr.votesAgainstWinner = cr.votesAgainstWinner.add(wv);
            //     }
            // }

            wv = getUserVotesOnWinnerRequest(cr.target);
            if(wv != 0) {
                // if(wv > _amount) { // use this code in case wants to limit winner up to twice that of vote
                //     cr.userVotesAgainstWinner[msg.sender] = cr.userVotesAgainstWinner[msg.sender].add(_amount);
                //     cr.votesAgainstWinner = cr.votesAgainstWinner.add(_amount);
                // } else {
                //     cr.userVotesAgainstWinner[msg.sender] = cr.userVotesAgainstWinner[msg.sender].add(wv);
                //     cr.votesAgainstWinner = cr.votesAgainstWinner.add(wv);
                // }
                cr.userVotesAgainstWinner[msg.sender] = cr.userVotesAgainstWinner[msg.sender].add(wv);
                cr.votesAgainstWinner = cr.votesAgainstWinner.add(wv);
            }
        }

        emit NewVote(_key, cr.target, _amount, _amount.add(wv), msg.sender);
    }
    function cancelVoteOnChangeRequest(bytes32 _key) public {
        reduceVoteOnChangeRequest(_key, lockedUCGBalance[msg.sender]);
        emit VoteCancelled(_key, msg.sender);
    }

    /**
     * @dev Verifies if a ChangeRequest is the Winner Request for its target
     * and if not it will verify if it beats current winner and replace it
     * @param _key bytes32 key of the ChangeRequest
     * @return true if it's winner and false if not
     */
    function isWinner(bytes32 _key) public returns (bool) {
        // check if change request exist
        require(changeRequestsSet.exists(_key), "ChangeRequest doesn't exist");

        ChangeRequest storage cr = changeRequests[_key];
        bytes32 wrKey = winnerRequestIdPerTarget[cr.target];
        if(_key == wrKey) {
            return true;
        }
        // if differente, check if it cr can replace winner request
        if(cr.status != CRStatus.PendingApproval) { // check if it's pending aproval
            return false; // only PendingApproval CRs can become winners
        }
        ChangeRequest storage wr = changeRequests[wrKey]; // locate winner
        if(wr.createdOn > cr.createdOn) { // check if changeRequest came after winnerRequest, otherwise it is expired
            cr.status = CRStatus.Expired;
            return false;
        }
        if(cr.votesAgainstWinner > wr.votes)
        {
            // replace winner
            wr.status = CRStatus.Replaced;
            cr.status = CRStatus.Approved;
            cr.safeDelay = cr.safeDelay.add(now); // update safeDelay to reflet a time from approval
            winnerRequestIdPerTarget[cr.target] = _key;
            emit NewWinner(_key, cr.safeDelay);
            return true;
        }
        return false;
    }

    /// Public Auth Methods
    function updateToAppliedStatus(bytes32 _key) public auth {
        // check if change request exist
        require(changeRequestsSet.exists(_key), "ChangeRequest doesn't exist");
        ChangeRequest storage cr = changeRequests[_key];
        cr.status = CRStatus.Applied;

    }
    // method called by UCPath and to be overriden by implemantation contract
    function updatePath(string memory pathName, address pathAddress) public auth {
        bool updated;
        if(keccak256(bytes(pathName)) == keccak256("UCGToken")) {
            ucgToken = UCGToken(pathAddress);
            updated = true;
        }

        if(updated) {
            emit PathUpdated(pathName, pathAddress);
        }
    }

    // function isApproved(bytes32 _changeRequestKey) public returns(bool) {
    //     require(changeRequestsSet.exists(_key), "Change Request not found.");
    //     ChangeRequest cr = changeRequests[_changeRequestKey];
    //     if(cr.status == 1) {
    //         return true;
    //     }
    //     // check if it's pending aproval
    //     require(cr.status != 0, string(abi.encodePacked("Change Request can't be approved because currrent Status: ", cr.status)); // canceled, aplied, expired, closed
    // }

    /// Private Methods

    function reduceVoteOnChangeRequest(bytes32 _key, uint256 _amount) private {
        // check if change request exist
        require(changeRequestsSet.exists(_key), "ChangeRequest doesn't exist");
        // check if is participating on request
        UnorderedKeySetLib.Set storage p = userParticipations[msg.sender];
        require(p.exists(_key), "User does not participate on ChangeRequest");
        // check votes on request
        ChangeRequest storage c = changeRequests[_key];
        uint256 currentVotes = c.userVotes[msg.sender];
        uint256 currentVotesAgainstWinner = c.userVotesAgainstWinner[msg.sender];
        //uint256 computedVotesOnWinner = currentVotesAgainstWinner.sub(currentVotes);
        // check if there will be remaining votes
        if(currentVotes > _amount)
        {
            c.votes = c.votes.sub(_amount);
            c.votesAgainstWinner = c.votesAgainstWinner.sub(_amount);
            c.userVotes[msg.sender] = currentVotes.sub(_amount);
            c.userVotesAgainstWinner[msg.sender] = currentVotesAgainstWinner.sub(_amount);
            // if(computedVotesOnWinner > 0) { // use this code in case wants to limit winner up to twice that of vote
            //     if(_amount > computedVotesOnWinner)
            //     {
            //         c.votesAgainstWinner = c.votesAgainstWinner.sub(computedVotesOnWinner);
            //         c.userVotesAgainstWinner[msg.sender] = c.userVotesAgainstWinner[msg.sender].sub(computedVotesOnWinner);
            //     } else {
            //         uint256 votesToReduce = (computedVotesOnWinner.mul(_amount)).div(currentVotes);
            //         c.votesAgainstWinner = c.votesAgainstWinner.sub(votesToReduce);
            //         c.userVotesAgainstWinner[msg.sender] = c.userVotesAgainstWinner[msg.sender].sub(votesToReduce);
            //     }
            // }
        } else {
            c.votes = c.votes.sub(currentVotes);
            c.votesAgainstWinner = c.votesAgainstWinner.sub(currentVotesAgainstWinner);
            // if 0 votes left, remove participation
            p.remove(_key);
            delete c.userVotes[msg.sender];
            delete c.userVotesAgainstWinner[msg.sender];
        }

    }
    /**
     * @dev Returns the user votes on the winner request for a specifit target
     *
     * @param _target bytes32 key that represents the target of the change request (hash of contract address + method name)
     * @return number of votes on winner request. returns 0 if no vote is found (0 is default uint256 value)
     */
    function getUserVotesOnWinnerRequest(bytes32 _target) private view returns (uint256) {
        uint256 wv;
        ChangeRequest storage wr = changeRequests[winnerRequestIdPerTarget[_target]]; // locate winner
        if(wr.target == _target) { // check if wr exist (initialized)
            wv = wr.userVotes[msg.sender]; // check if user has voted on winner request
        }
        return wv;
    }

    // function newChangeRequest(address _contractAddress, string  _functionName, string  _parameters, string _notes, uint256 _UIPNumber) public {
    //     bytes32 key = keccak256(msg.sender, _contractAddress, _functionName, _parameters, _notes, _UIPNumber, block.number);
    //     changeRequestsSet.insert(key); // Note that this will fail automatically if the key already exists.

    //     changeRequests[key] = ChangeRequest({
    //         contractAddress: _contractAddress,
    //         functionName: _functionName,
    //         parameters: _parameters,
    //         status: "PendingApproval",
    //         createBy: msg.sender,
    //         notes: _notes,
    //         UIPNumber: _UIPNumber
    //     });

    //     emit NewChangeRequest(key, msg.sender, "addSaleOrder", _price, _collateral, _expiration);
    // }



    /// Events
    event Locked(address from, uint256 amount);
    event Unlocked(address from, uint256 amount);
    event NewChangeRequest(
        bytes32 target,
        bytes32 proposal,
        address createdBy,
        uint256 UIPNumber,
        string notes
    );
    event VoteCancelled(bytes32 changeRequest, address user);
    event NewVote(bytes32 changeRequest, bytes32 target, uint256 amount, uint256 amountAgaintWinner, address user);
    event NewWinner(bytes32 changeRequest, uint256 safeDelay);

}