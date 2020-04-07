pragma solidity >=0.4.21 <0.6.0;

//import "@openzeppelin/contracts/math/SafeMath.sol";
import "./UCChangeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UCToken is UCChangeable, ERC20 {
    //using SafeMath for uint256;

    /// Public properties
    string constant public name = "UC";
    string constant public symbol = "UC";
    string constant public standard = "UC Token v1.0";
    uint8 constant public decimals = 18;

    constructor(address pathAddress, uint256 initialSupply) UCChangeable(pathAddress, "UCToken") public {
        //balanceOf[msg.sender] = initialSupply;
        //_totalSupply = initialSupply;
        _mint(msg.sender, initialSupply);
    }
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function mint(address account, uint256 amount) public auth returns (bool) {
        _mint(account, amount);
        return true;
    }

    /**
     * @dev Exchange UCs for collateral, burn new tokens in exchangefor collateral and assign to sender
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param _amount amount of UC okens to burn
     * @return The number of UCs buyer received
     */
    function burn(address _account, uint256 _amount) public auth returns (bool)  {
        require(_amount > 0, "UC amount required");
        _burn(_account, _amount);

        return true;

    }

}