pragma solidity 0.5.7;

import "./libraries/UnorderedKeySet.sol";
import "./UCGovernance.sol";
import "./UCChangeable.sol";

contract UCPath is UCChangeable {
   using UnorderedAddressSetLib for UnorderedAddressSetLib.Set;

   /// Public Properties
   //address public ucCrawlingBandAddress;
   //uint256[2] public changeUCCrawlingBandAddressReq; // requirement

   /// Contract Navigation Properties
   UCGovernance ucGovernance;

   /// Private lists
   UnorderedAddressSetLib.Set ucContracts; // list of active contracts (both current and replaced)

   /// Public Mappings
   mapping(string => address) private currentPath; // mapping of current paths p/contract name. May return address(0). Use getPath instead.

   // /// Enums
   //  enum Status {
   //      Current,                    // Default value
   //      Replaced,                   // Has been replaced
   //      Locked                      // No longer accessible
   //  }
   // /// Objects (Structs)
   // struct Path {
   //    address contractAddress;
   //    string name;
   //    Status status;
   // }

   constructor() public UCChangeable(address(0), "UCPath") {
      initializePath(address(this), "UCPath");
   }

   /// Public Methods
   function init() public {
        require(address(ucGovernance) == address(0), "Already initialized");
        ucGovernance = UCGovernance(ucPath.getPath("UCGovernance"));
    }
   function getPath(string memory _contractName) public view returns (address) {
      address path = currentPath[_contractName];
      require(path != address(0), string(abi.encodePacked("Path not initialized: ", _contractName)));
      return path;
   }
   function hasPath(string memory _contractName) public view returns (bool) {
      address path = currentPath[_contractName];
      if(path != address(0)) {
         return true;
      } else {
         return false;
      }
   }

   // in this case, target includes pathName property, so it can allow different voting weights on different paths
   function setPath(bytes32 changeRequestID, string memory pathName, address newAddress) public {
      require(ucGovernance.isWinner(changeRequestID), "ChangeRequest not winner");
      // get request target, proposal, safe Delay and status
      (bytes32 target, bytes32 proposal, uint safeDelay, UCGovernance.CRStatus status,,,,,,) = ucGovernance.changeRequests(changeRequestID);
      // check if it hasn't been applyed yet
      require(uint(status) == 1, "ChangeRequest is not on Approved status");
      // check if request match target
      require(target == keccak256(abi.encodePacked(address(this), "setPath", pathName)), "ChangeRequest does not match Target");
      // check if request match proposal
      require(proposal == keccak256(abi.encodePacked(pathName, newAddress)), "ChangeRequest does not match proposal");
      // check if safeDelay has passed
      require(now >= safeDelay, "Can't apply request within safe delay");
      // check if path exist and is different that proposed path
      address currPath = currentPath[pathName];
      if(currPath != address(0)) {
         require(currPath != newAddress, "Proposed address is the same as current address");
      }
      // apply change
      currentPath[pathName] = newAddress;
      insertContractToList(newAddress);
      // change CR status to Applied
      ucGovernance.updateToAppliedStatus(changeRequestID);
      if(currPath != address(0)) {
         emit PathChanged(pathName, newAddress);
      } else {
         emit PathInicialized(pathName, newAddress);
      }
   }

   /// Public Auth Methods
   function initializePath(address _path, string memory _contractName) public auth {
      require(currentPath[_contractName] == address(0), "Can't initialize a Path that has been set already");
      currentPath[_contractName] = _path;
      insertContractToList(_path);
      emit PathInicialized(_contractName, _path);
   }

   // function initialize(address _ucGovernance, address _ucCrawlingBand) public auth {
   //    require(ucGovernanceAddress == ucCrawlingBandAddress == address(0), "Already initilized");

   //    ucGovernanceAddress = _ucGovernance;
   //    ucCrawlingBandAddress = _ucCrawlingBand;
   //    insertContractToList(_ucGovernance);
   //    insertContractToList(_ucCrawlingBand);

   //    emit Inicialized();

   // }

   /// External methods
   function isValid(address _address) external view returns (bool) {
      return ucContracts.exists(_address);
   }

   /// Private Functions
   function insertContractToList(address _contract) private {
      if(!ucContracts.exists(_contract)) {
         ucContracts.insert(_contract);
      }
   }

   /// Events
   event PathInicialized(string contractName, address contractAddress);
   event PathChanged(string contractName, address contractAddress);


}