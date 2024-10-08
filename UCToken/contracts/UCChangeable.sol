pragma solidity 0.5.7;

import "./UCPath.sol";

contract UCChangeable {

    /// Public Properties
    address public owner;

    /// Contract Navigation Properties
    UCPath public ucPath;

    /// Modifiers
    modifier auth {
        //// for debugging
        // require(
        //     isAuthorized(msg.sender),
        //     string(abi.encodePacked("MSG SENDER: ", toString(msg.sender), " OWNER: ", toString(owner), " ADDRESS THIS: ", toString(address(this))))); // "Not authorized"
        require(isAuthorized(msg.sender, ""),"Not authorized");
        _;
    }
    modifier authPath(string memory contractName) {
        require(isAuthorized(msg.sender, contractName),"Not authorized");
        _;
    }

    constructor(address pathAddress, string memory pathName) internal {
        owner = msg.sender;
        emit NewOwner(msg.sender);

        if(keccak256(bytes(pathName)) == keccak256("UCPath")) {
            ucPath = UCPath(address(this));
        } else {
            ucPath = UCPath(pathAddress);
            // if(!ucPath.hasPath(pathName)) {
            //     ucPath.initializePath(address(this), pathName); // doesn't work because doesn't pass AUTH (msg.sender is new contract not yet registered)
            // }
        }
        // if(!ucPath.hasPath(pathName)) {
        //     ucPath.initializePath(address(this), pathName); // doesn't work for UCPath contract (probably because the methods are not available yet)
        // }
    }

    /// Public Methods
    function setOwner(address _owner) public auth {
        owner = _owner;
        emit NewOwner(_owner);
    }
    function setUCPath(address _path) public auth {
        ucPath = UCPath(_path);
        emit NewPath(_path);
    }

    /// Public Auth Mehods

    // method called by UCPath and to be overriden by implemantation contract
    function updatePath(string memory pathName, address pathAddress) public auth {
        emit PathUpdated(pathName, pathAddress);
    }

    /// Internal Functions

    // function isAuthorized(address src) internal view returns (bool) {
    //     if (src == address(this)) {
    //         return true;
    //     } else if (src == owner) { // can't use tx.origin == ower https://solidity.readthedocs.io/en/develop/security-considerations.html#tx-origin
    //         return true;
    //     } else if(isContract(src)) {
    //         // check list of ucContracts
    //         if (ucPath == UCPath(0)) {
    //             return false;
    //         } else {
    //             return ucPath.isValid(src);
    //         }
    //     } else {
    //         // TODO Check list of users
    //     }
    // }
    function isAuthorized(address src, string memory contractName) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) { // can't use tx.origin == ower https://solidity.readthedocs.io/en/develop/security-considerations.html#tx-origin
            return true;
        } else if (bytes(contractName).length != 0) {
            if (ucPath == UCPath(0)) {
                return false;
            } else {
                return ucPath.getPath(contractName) == src;
            }
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
    function isContract(address addr) internal view returns (bool) { // make public from internal fo testing
        // https://ethereum.stackexchange.com/a/77888/20639
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        bytes32 codehash;
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
    // function toString(address _addr) internal pure returns (string memory) {
    //     bytes32 value = bytes32(uint256(_addr));
    //     bytes memory alphabet = "0123456789abcdef";

    //     bytes memory str = new bytes(42);
    //     str[0] = '0';
    //     str[1] = 'x';
    //     for (uint i = 0; i < 20; i++) {
    //         str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
    //         str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
    //     }
    //     return string(str);
    // }

    /// Events
    event NewOwner(address owner);
    event NewPath(address pathAddress);
    event PathUpdated(string pathName, address pathAddress);
}
