pragma solidity >=0.4.21 <0.6.2;

import "./UCGovernance.sol";
import "./UCChangeable.sol";

contract UCSPath is UCChangeable {

   /// Public Properties
   address public ucGovernanceAddress;
   uint256[2] public changeUCCrawlingBandAddressReq; // requirement

   /// Contract Navigation Properties
   UCGovernance ucGovernance;

   constructor(address _ucGovernanceAddress) public {
      ucGovernanceAddress = _ucGovernanceAddress;
      ucGovernance = UCGovernance(ucGovernanceAddress);
   }

   /// Public Methods

   function changeUCCrawlingBandAddress(bytes32 changeRequestID, address newAddress) public {
      require(ucGovernance.changeRequestExits(changeRequestID), "ChangeRequest not found");
      // get request proposal
      (bytes32 proposal, uint status,,,,,) = ucGovernance.changeRequests(changeRequestID);
      // check status
      require(status == 0 || status == 1, "Change Request can't be approved"); // canceled, aplied, expired, closed
      // check if request match proposal
      require(proposal == keccak256(this.address, "changeUCCrawlingBandAddress", newAddress), "ChangeRequest does not match");
      // check if CR is approved
   }



}