pragma solidity >=0.4.21 <0.6.2;

import "./UCGovernance.sol";

contract UCSPath {

   /// Public Properties
   address public ucGovernanceAddress;

   /// Contract Navigation Properties
   UCGovernance ucGovernance;

   constructor(address _ucGovernanceAddress) public {
      ucGovernanceAddress = _ucGovernanceAddress;
      ucGovernance = UCGovernance(ucGovernanceAddress);
   }

   /// Public Methods
   function changeUCCrawlingBandAddress(bytes32 changeRequest, address newAddress) public {

   }



}