pragma solidity >=0.4.21 <0.6.0;

contract UCStorage {
   
   uint256 public totalSupply;

   mapping(address => uint256) public balanceOf;
   mapping(address => mapping(address => uint256)) public allowance;

    

}