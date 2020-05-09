pragma solidity >=0.4.21 <0.6.5;

import "./libraries/UnorderedKeySet.sol";
import "./UCPath.sol";
import "./UCChangeable.sol";

// NOT YET IN USE
contract UCAuth is UCChangeable {

    /// Public Mappings
    //mapping(address=>bool) public admins;

    /// Private lists
    UnorderedAddressSetLib.Set admins; // list of admins
    //UnorderedAddressSetLib.Set ucContracts; // list of active contracts (both current and replaced)

    constructor(address pathAddress) UCChangeable(pathAddress, "UCAuth") public {

    }

    /// Public Methods
    function isAuthorized(address src, address dst, address cOwner, string memory contractName) public view returns (bool) {
        // can't use tx.origin == ower https://solidity.readthedocs.io/en/develop/security-considerations.html#tx-origin
        if (src == dst || src == cOwner) {
            return true;
        } else if (bytes(contractName).length != 0) {
            return ucPath == UCPath(0) ? false : ucPath.getPath(contractName) == src;
        } else if(isContract(src)) {
            // check list of ucContracts
            return ucPath == UCPath(0) ? false : ucPath.isValid(src);
        } else {
            // TODO Check list of users
        }
    }

}