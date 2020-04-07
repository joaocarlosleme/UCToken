pragma solidity >=0.4.21 <0.6.5;

import "./UCPath.sol";

contract UCChangeable {

    /// Public Properties
    address public owner;

    /// Contract Navigation Properties
    UCPath public ucPath;

    /// Modifiers
    modifier auth {
        require(isAuthorized(msg.sender), "Not Authorized");
        _;
    }

    constructor(address pathAddress, string memory pathName) internal {
        owner = msg.sender;
        emit NewOwner(msg.sender);

        if(keccak256(bytes(pathName)) == keccak256("UCPath")) {
            ucPath = UCPath(address(this));
        } else {
            ucPath = UCPath(pathAddress);
        }
        if(ucPath.getPath(pathName) == address(0)) {
            ucPath.initializePath(address(this), pathName);
        }
    }

    /// Public Methods
    function setOwner(address _owner) public auth {
        owner = _owner;
        emit NewOwner(_owner);
    }
    function setPath(address _path) public auth {
        ucPath = UCPath(_path);
        emit NewPath(_path);
    }

    /// Public Auth Mehods

    // method called by UCPath and to be overriden by implemantation contract
    function updatePath(string memory pathName, address pathAddress) public auth {
        emit PathUpdated(pathName, pathAddress);
    }

    /// Internal Functions
    function isAuthorized(address src) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if(isContract(src)) {
            // check list of ucContracts
            if (ucPath == UCPath(0)) {
                return false;
            } else {
                return ucPath.isValid(src);
            }
        } else {
            // TODO Check list of users
        }
    }



    /// Private Functions

   /**
   * Returns whether the target address is a contract
   * @dev Check if this function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
    function isContract(address addr) internal view returns (bool) {
        // https://ethereum.stackexchange.com/a/77888/20639
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        bytes32 codehash;
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /// Events
    event NewOwner(address owner);
    event NewPath(address pathAddress);
    event PathUpdated(string pathName, address pathAddress);
}
