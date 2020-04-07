// pragma solidity >=0.4.21 <0.6.0;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "./UCChangeable.sol";

// contract UCToken is UCChangeable {
//     using SafeMath for uint256;

//     /// Public properties
//     string constant public name = "UC";
//     string constant public symbol = "UC";
//     string constant public standard = "UC Token v1.0";
//     uint8 constant public decimals = 18;
//     uint256 public totalSupply;

//     /// Events
//     event Transfer(
//         address indexed _from,
//         address indexed _to,
//         uint256 _value
//     );

//     event Approval(
//         address indexed _owner,
//         address indexed _spender,
//         uint256 _value
//     );

//     /// Public Mappings
//     mapping(address => uint256) public balanceOf;
//     mapping(address => mapping(address => uint256)) public allowance;

//     constructor(address _ucPath, uint256 _initialSupply) public {
//         ucPath = UCPath(_ucPath);
//         ucPath.initializePath(address(this), "UCToken");

//         balanceOf[msg.sender] = _initialSupply;
//         totalSupply = _initialSupply;
//     }

//     /// Public Methods
//     function transfer(address _to, uint256 _value) public returns (bool success) {
//         require(balanceOf[msg.sender] >= _value, "not enough balance");

//         balanceOf[msg.sender] -= _value;
//         balanceOf[_to] += _value;

//         emit Transfer(msg.sender, _to, _value);

//         return true;
//     }

//     function approve(address _spender, uint256 _value) public returns (bool success) {
//         allowance[msg.sender][_spender] = _value;

//         emit Approval(msg.sender, _spender, _value);

//         return true;
//     }

//     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
//         require(_value <= balanceOf[_from], "not enough balance");
//         require(_value <= allowance[_from][msg.sender], "not allowed");

//         balanceOf[_from] -= _value;
//         balanceOf[_to] += _value;

//         allowance[_from][msg.sender] -= _value;

//         emit Transfer(_from, _to, _value);

//         return true;
//     }

//     /** @dev Creates `amount` tokens and assigns them to `account`, increasing
//      * the total supply.
//      *
//      * Emits a {Transfer} event with `from` set to the zero address.
//      *
//      * Requirements
//      *
//      * - `to` cannot be the zero address.
//      */
//     function mint(address account, uint256 amount) public auth returns (bool) {
//         require(account != address(0), "ERC20: mint to the zero address");

//         totalSupply = totalSupply.add(amount);
//         balanceOf[account] = balanceOf[account].add(amount);
//         emit Transfer(address(0), account, amount);
//         return true;
//     }

//     /**
//      * @dev Exchange UCs for collateral, burn new tokens in exchangefor collateral and assign to sender
//      * This function has a non-reentrancy guard, so it shouldn't be called by
//      * another `nonReentrant` function.
//      * @param _amount amount of UC okens to burn
//      * @return The number of UCs buyer received
//      */
//     function burn(address _account, uint256 _amount) public auth returns (bool)  {
//         require(_amount > 0, "UC amount required");
//         require(account != address(0), "ERC20: burn from the zero address");
//         // uint256 balance = balanceOf[_account];
//         // require(balance >= _amount, "Balance lower than amount to burn");

//         balanceOf[_account] = balanceOf[_account].sub(_amount, "ERC20: burn amount exceeds balance");
//         totalSupply = totalSupply.sub(_amount);
//         emit Transfer(_account, address(0), _amount);

//         return true;

//     }
// }
