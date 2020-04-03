pragma solidity >=0.4.21 <0.6.5;

import "./libraries/UnorderedKeySet.sol";
import "./UCPath.sol";
import "./UCChangeable.sol";

contract UCAuth is UCChangeable {

    /// Public Mappings
    //mapping(address=>bool) public admins;

    /// Private lists
    UnorderedAddressSetLib.Set admins; // list of admins
    UnorderedAddressSetLib.Set ucContracts; // list of active contracts (both current and replaced)

    /// Public Methods


}