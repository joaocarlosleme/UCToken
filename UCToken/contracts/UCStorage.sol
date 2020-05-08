pragma solidity >=0.4.21 <0.6.0;

import "./UCChangeable.sol";

/** @title  Contract address holder of all UC funds with minimum business logic
  *
  * @notice xxx
  *
  * @dev make changes on marketplace to have this contract as balance holder of collaterals. This way
  * we can have other contracts and exchange one collateral for another (according to UCGov approval)
  * in order to keep a desired balance of reserves.
  * If it ends up holding only collateral (and not UC Balances), change name to UCCollateralStorage
  * @author  UCORG
  */
contract UCStorage is UCChangeable {

   uint256 public totalSupply;

   mapping(address => uint256) public balanceOf;
   mapping(address => mapping(address => uint256)) public allowance;



}