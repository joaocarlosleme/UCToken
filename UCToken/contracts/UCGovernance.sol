pragma solidity >=0.4.21 <0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libraries/UnorderedKeySet.sol";
import "./UCGToken.sol";
import "./UCChangeable.sol";

contract UCGovernance is UCChangeable {
    using SafeMath for uint256;
    using UnorderedKeySetLib for UnorderedKeySetLib.Set;

    /// Public Properties
    address public ucgTokenAddress;
    uint256 public maxParticipation; // max number of active requests a user can vote at the same time

    /// Contract Navigation Properties
    UCGToken ucgToken;

    /// Objects (Structs)
    // struct ChangeRequest {
    //     // address contractAddress;
    //     // string functionName;
    //     // string parameters;
    //     // string notes;
    //     bytes32 proposal; // hash of the proposal (contractAddress, method name, parameter values)
    //     string status;
    //     address createBy;
    //     uint256 UIPNumber;
    //     string notes; // in case of no UIP number
    //     uint256 votes; // total votes
    //     mapping (address => uint256) userVotes; // votes per user
    // }

    /// Public Mappings
    mapping(bytes32 => ChangeRequest) public changeRequests; // where bytes32 is a unique ID for the changeRequest (hash of the proposal + now)
    mapping(address=>uint256) public lockedUCGBalance;
    mapping(address=>UnorderedKeySetLib.Set) public userParticipations;  // list of user participation on change requests

    /// Private lists
    UnorderedKeySetLib.Set changeRequestsSet; // list of change requests

    constructor(address _ucgTokenAddress) public {
        ucgTokenAddress = _ucgTokenAddress;
        ucgToken = UCGToken(ucgTokenAddress);
        maxParticipation = 7; // initial value
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
        for( uint i = 0; i < p.count; i++) {
            reduceVoteOnChangeRequest(p.keyAtIndex(i), _amount);
        }

        emit Unlocked(msg.sender, _amount);
    }

    function newChangeRequest(bytes32 _proposal, uint256 _UIPNumber, string _notes) public {
        bytes32 crID = keccak256(_proposal, now);
        changeRequestsSet.insert(crID); // Note that this will fail automatically if the key already exists.

        changeRequests[crID] = ChangeRequest({
            proposal: _proposal,
            status: CRStatus.PendingApproval,
            createBy: msg.sender,
            UIPNumber: _UIPNumber,
            notes: _notes
        });

        emit NewChangeRequest(_proposal, msg.sender, _UIPNumber, _notes);
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
            require(p.count <= maxParticipation, "Max participation reached");
            p.insert(_key);
        }
        // add votes to request
        ChangeRequest storage c = ChangeRequest[_key];
        // check if there is already a vote from this user
        uint256 currentVotes = c.userVotes[msg.sender];
        if(currentVotes > 0)
        {
            c.votes = c.votes.sub(currentVotes);
        }
        c.userVotes[msg.sender] = _amount;
        c.votes = c.votes.add(_amount);

        emit NewVote(_key, _amount, msg.sender);
    }
    function cancelVoteOnChangeRequest(bytes32 _key) public {
        reduceVoteOnChangeRequest(_key, lockedUCGBalance[msg.sender]);
        emit VoteCancelled(_key, msg.sender);
    }
    function changeRequestExits(bytes32 _key) public view returns(bool) {
        return changeRequestsSet.exists(_key);
    }
    function isApproved(bytes32 _changeRequestKey) public returns(bool) {
        require(changeRequestsSet.exists(_key), "Change Request not found.");
        ChangeRequest cr = changeRequests[_changeRequestKey];
        if(cr.status == 1) {
            return true;
        }
        // check if it's pending aproval
        require(cr.status != 0, string(abi.encodePacked("Change Request can't be approved because currrent Status: ", cr.status)); // canceled, aplied, expired, closed


    }

    /// Private Methods
    function reduceVoteOnChangeRequest(bytes32 _key, uint256 _amount) private {
        // check if change request exist
        require(changeRequestsSet.exists(_key), "ChangeRequest doesn't exist");
        // check if is participating on request
        UnorderedKeySetLib.Set storage p = userParticipations[msg.sender];
        require(p.exists(_key), "User does not participate on ChangeRequest");
        // check votes on request
        ChangeRequest storage c = ChangeRequest[_key];
        uint256 currentVotes = c.userVotes[msg.sender];
        // check if there will be remaining votes
        if(currentVotes > _amount)
        {
            c.votes = c.votes.sub(_amount);
            c.userVotes[msg.sender] = currentVotes.sub(_amount);
        } else {
            c.votes = c.votes.sub(currentVotes);
            // if 0 votes left, remove participation
            p.remove(_key);
            delete c.userVotes[msg.sender];
        }
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
        bytes32 proposal,
        address createdBy,
        uint256 UIPNumber,
        string notes
    );
    event VoteCancelled(bytes32 proposal, address user);
    event NewVote(bytes32 proposal, uint256 amount, address user);

}