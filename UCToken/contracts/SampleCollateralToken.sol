pragma solidity >=0.4.21 <0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract SampleCollateralToken is ERC20 {

    constructor () public {
        _mint(msg.sender, 100000000000000000000); // 100 unidades * 1E18
    }
}