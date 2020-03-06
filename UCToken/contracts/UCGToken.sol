pragma solidity >=0.4.21 <0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";

contract UCGToken is ERC20Mintable {
    using SafeMath for uint256;

    string constant public name = "UCG";
    string constant public symbol = "UCG";
    string constant public standard = "UCG Token v1.0";
    uint8 constant public decimals = 18;
    uint256 public totalSupply;

}