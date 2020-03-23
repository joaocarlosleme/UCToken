pragma solidity >=0.4.21 <0.6.2;

contract UCChangeable {

    /// Enums
    enum CRStatus {
        PendingApproval,                    // Default value
        Approved,                           //
        Applied,                            // already used/completed
        Closed,                             //
        Expired,                            // CR has already expired
        Cancelled                           // CR has been cancelled
    }
    /// Objects (Structs)

    struct ChangeRequest {
        // address contractAddress;
        // string functionName;
        // string parameters;
        // string notes;
        bytes32 proposal; // hash of the proposal (contractAddress, method name, parameter values)
        CRStatus status;
        address createBy;
        uint256 UIPNumber;
        string notes; // in case of no UIP info
        uint256 votes; // total votes
        mapping (address => uint256) userVotes; // votes per user
    }
    // Change Request Requirements
    struct ChangeRequestReq {
        uint X;                     // number 1 to 100
        uint quorum;                     // number 1 to 100
        address contractAddress;
        string methodName;
    }
}