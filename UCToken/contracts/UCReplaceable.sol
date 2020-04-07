pragma solidity >=0.4.21 <0.6.5;

import "./UCPath.sol";

/**
 * @title UCReplaceable
 * @dev To be used on functions that can no longer be called after a contract is replaced.
 */
contract UCReplaceable is UCChangeable {

    bool public replaced;
    address public newContractAddress;

    /// Modifiers
    modifier replaceable {
        require(!replaced, "Contract replaced by newContractAddress.");
        _;
    }

    // called by other contract when a replaceable contract is replaced or has been and
    // ...now its functions marked must be shutdown
    // ... must use try catch to check if contract is really replaceable if calling from another contract
    function replace(address newAddress) public auth {
        require(!replaced, "Has already been replaced");
        newContractAddress = newAddress;
        replaced = false;
        emit ContractReplaced(newAddress);
   }

   event ContractReplaced(address newAddress);
}