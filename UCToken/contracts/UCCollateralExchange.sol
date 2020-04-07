// pragma solidity >=0.4.21 <0.6.0;

// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
// import "./UCToken.sol";
// import "./UCStorage.sol";
// import "./UCCrawlingBand.sol";
// import "./UCChangeable.sol";
// //import "./UCCollateralTokenInterface.sol"; // replaced by ERC20Detailed
// import "./libraries/UnorderedKeySet.sol"; // or import {UnorderedKeySetLib} from "./libraries/UnorderedKeySet.sol";

// /**
//  * @title UCExchange (maybe rename to UCTrade)
//  * @dev Contract destination for aquiring and selling UCs in exchange for a collateral token.
//  */
// contract UCCollateralExchange is ReentrancyGuard, UCChangeable {
//     using SafeMath for uint256;
//     using UnorderedKeySetLib for UnorderedKeySetLib.Set;

//     /// Public Properties
//     address public collateralAddress; // acceptable ERC20 collateral token address
//     uint256 public price; // price in US Dollar / 1000000 (6 decimals)
//     //uint256 public balance; // total amount of tokens (contract balance) // must check on token

//     /// Contract Navigation Properties
//     UCToken ucToken;
//     UCCrawlingBand ucCrawlingBand; // The reference to UCCrawlingBand implementation.
//     ERC20Detailed collateralToken;
//     //UCStorage public ucStorage; // to be implemented (decoupled from UCToken)

//     /// Objects (Structs)
//     struct SaleOrder {
//     address addr; // acccount address
//     uint256 amount; // UC amount to sell
//     uint256 price;  // price is willing to sell
//     uint256 time; // time the order was placed
//     uint256 expirationInMinutes; // how long the order should valid, in minutes, before expiring
//     }
//     struct PurchaseOrder {
//     address addr; // maker address
//     uint256 amount; // UC amount wants to purchase
//     uint256 price;  // UC price in USD
//     uint256 time; // time the order was placed
//     uint256 expirationInMinutes; // how long the order should valid, in minutes, before expiring
//     }

//     /// Public Mappings
//     mapping (address => uint256) public balances; // amount of USD available for buyers to place orders on orderBook
//     mapping(bytes32 => SaleOrder) public saleOrders;
//     mapping(bytes32 => PurchaseOrder) public purchaseOrders;

//     /// Private lists
//     UnorderedKeySetLib.Set saleOrdersSet;
//     UnorderedKeySetLib.Set purchaseOrdersSet;


//     constructor(address pathAddress, address _collateralAddress) UCChangeable(pathAddress, "UCCollateralExchange") public {
//         ucToken = UCToken(ucPath.getPath("UCToken"));
//         ucCrawlingBand = UCCrawlingBand(ucPath.getPath("UCCrawlingBand"));
//         collateralToken = ERC20Detailed(collateralAddress);
//     }

//     /// Public Auth Methods

//     // update collateral price
//     // TODO UPdate to ChangeRequest type of update
//     function updatePrice(uint256 _price) public auth {
//         price = _price;
//     }

//     /// Public Methods

//     // returns token rate in UC
//     function currentRate() public view returns(uint256 rate) {
//         // uint256 ucCeilingPrice = ucCrawlingBand.getCurrentCeilingPrice();
//         // uint256 rate = price.div(ucCeilingPrice);
//         // return rate;
//         return price.div(ucCrawlingBand.getCurrentCeilingPrice());
//     }

//     function newSaleOrder(uint _amount, uint _price, uint _expirationInMinutes) public returns (bool) {
//         require(_amount > 0, "UC amount required");
//         // check if sender has enough balance
//         require(ucToken.transferFrom(msg.sender, this, _amount), "Couldn't transfer UC token.");

//         bytes32 key = keccak256(msg.sender, _amount, _price, _expirationInMinutes, block.number);
//         saleOrdersSet.insert(key); // Note that this will fail automatically if the key already exists.
//         SaleOrder storage o = saleOrders[key];
//         o.amount = _amount;
//         o.price = _price;
//         o.expirationInMinutes = _expirationInMinutes;
//         emit OrderBookChange(msg.sender, key, "newSaleOrder", _amount, _price, _expirationInMinutes);
//     }

//     function updateSaleOrder(bytes32 _key, uint _amount, uint _price, uint _expirationInMinutes) public {
//         require(saleOrdersSet.exists(_key), "SaleOrder doesn't exist");
//         SaleOrder storage o = saleOrders[_key];
//         require(o.addr = msg.sender, "order doesn't belong to sender");
//         o.amount = _amount;
//         o.price = _price;
//         o.expirationInMinutes = _expirationInMinutes;
//         emit OrderBookChange(msg.sender, _key, "updateSaleOrder", _amount, _price, _expirationInMinutes);
//     }

//     function removeSaleOrder(bytes32 _key) public {
//         require(saleOrdersSet.exists(_key), "SaleOrder doesn't exist");
//         SaleOrder storage o = saleOrders[_key];
//         require(o.addr == msg.sender, "order doesn't belong to sender");
//         // Transfer UCs back to seller
//         ucToken.transfer(msg.sender, o.amount), "Couldn't transfer UC token.");
//         uint256 amount = o.amount;
//         uint256 price = o.price;
//         uint256 expirationInMinutes = o.expirationInMinutes;
//         saleOrdersSet.remove(_key); // Note that this will fail automatically if the key doesn't exist
//         delete saleOrders[_key];
//         emit OrderBookChange(msg.sender, _key, "removeSaleOrder", amount, price, expirationInMinutes);
//     }

//     function getSaleOrderCount() public view returns(uint count) {
//         return saleOrdersSet.count();
//     }

//     function getSaleOrderKeyAtIndex(uint _index) public view returns(bytes32 key) {
//         return saleOrdersSet.keyAtIndex(_index);
//     }

//     /**
//      * @dev Deposit collateral for placing purchase orders.
//      * The equivalent amount of USD is credited for placing the orders at a later time.
//      * @param _amount amount of collateral Token to exchange
//      */
//     function addCollateral(uint256 _amount) public {
//         // transfer collateral to  reserves
//         //balance = balance.add(_amount);
//         require(collateralToken.transferFrom(msg.sender, address(this), _amount), "Transfer of collateral failed.");
//         // credit token balance
//        balances[msg.sender] = balances[msg.sender].add(_amount);

//         emit CollateralAdded(msg.sender, _amount);
//     }

// /// sample function for Ether deposits
// //   function deposit() payable {
// //     tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
// //     lastActiveTransaction[msg.sender] = block.number;
// //     Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
// //   }

//   function withdraw(address token, uint256 amount) public returns (bool success) {
//     //if (block.number.sub(lastActiveTransaction[msg.sender]) < inactivityReleasePeriod) revert("Can't withdraw within inactive period");
//     tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount, "Not enough balance");
//     if (token == address(0)) {
//       msg.sender.transfer(amount); // throws on failure
//     } else {
//         require(Token(token).transfer(msg.sender, amount), "Transfer failed");
//     }
//     Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
//   }

//     /**
//      * @dev Make new tokens in exchangefor collateral and assign to sender
//      * This function has a non-reentrancy guard, so it shouldn't be called by
//      * another `nonReentrant` function.
//      * @param _collateralToken collateral Token Address
//      * @param _amount amount of collateral Token to exchange
//      * @param _minUCAmount minimum amount of UCs desired in exchange for the collateral
//      * @return The amount of UCs buyer received
//      */
//     function mint(address _collateralToken, uint256 _amount, uint256 _minUCAmount) public nonReentrant returns (bool) {
//         require(_amount > 0, "collateral required");

//         CollateralToken storage cToken = collateralTokens[_collateralToken];
//         // make sure token is an approved token
//         require (cToken.tokenAddr != address(0), "Collateral token not found.");

//         // check rate
//         uint256 ucCeilingPrice = ucCrawlingBand.getCurrentCeilingPrice();
//         uint256 ucAmount = (_amount.mul(cToken.price)).div(ucCeilingPrice);
//         require(ucAmount >= _minUCAmount, "Calculated UC amount below minimum.");

//         // transfer to reserves
//         cToken.balance = cToken.balance.add(_amount);
//         require(cToken.token.transferFrom(msg.sender, address(this), _amount), "Transfer of collateral failed.");
//         //if (!cToken.token.transferFrom(msg.sender, address(this), _amount)) revert("Transfer of collateral failed.");

//         // mint UC
//         require(ucToken.mint(msg.sender, ucAmount), "Couldn't mint UC token.");

//         emit Mint(_amount, msg.sender, _amount, _collateralToken);

//         return true;
//     }

//     /**
//      * @dev Exchange UCs for collateral, burMake new tokens in exchangefor collateral and assign to sender
//      * This function has a non-reentrancy guard, so it shouldn't be called by
//      * another `nonReentrant` function.
//      * @param _amount amount of UC okens to burn
//      * @param _collateralToken collateral Token Address
//      * @return The amount of Collateral seller received
//      */
//     function burn(uint256 _amount, address _collateralToken) public nonReentrant returns (bool) {
//         require(_amount > 0, "UC amount required");
//         uint256 balance = ucToken.balanceOf(msg.sender);
//         require(balance >= _amount, "");

//         // return default
//         CollateralToken storage cToken = collateralTokens[_collateralToken];
//         // make sure token is an approved token
//         require(cToken.tokenAddr != address(0), "collateral token not found.");

//         // check rate
//         uint256 ucFloorPrice = ucCrawlingBand.getCurrentFloorPrice();
//         uint256 cAmount = (_amount.mul(ucFloorPrice)).div(cToken.price);
//         //require(cAmount >= _minColAmount, "Collateral amount to receive is below minimum.");

//         // transfer from reserves
//         //if (!cToken.token.transfer(msg.sender, cAmount)) revert("Couldn't transfer collateral tokens");
//         require(cToken.token.transfer(msg.sender, cAmount), "Couldn't transfer collateral tokens");
//         cToken.balance = cToken.balance.sub(cAmount);

//         // burn UC
//         require(ucToken.burn(msg.sender, _amount), "Couldn't burn UC token.");

//         emit Burn(_amount, msg.sender, cAmount, _collateralToken);

//         //return cAmount;
//         return true;

//     }

//     /**
//      * @dev Get UC tokens in exchangefor collateral and assign to sender
//      * Order is fulfilled either from OrderBook or Minted, whaever is cheaper
//      * This function has a non-reentrancy guard, so it shouldn't be called by
//      * another `nonReentrant` function.
//      * @param _collateralToken collateral Token Address
//      * @param _amount amount of collateral Token to exchange
//      * @param _minUCAmount minimum amount of UCs desired in exchange for the collateral
//      * @return The amount of UCs buyer received
//      */
//     function buy(address _collateralToken, uint256 _amount, uint256 _minUCAmount) public nonReentrant returns (bool) {
//         require(_amount > 0, "collateral required");

//         CollateralToken storage cToken = collateralTokens[_collateralToken];
//         // make sure token is an approved token
//         require (cToken.tokenAddr != address(0), "Collateral token not found.");

//         // check rate
//         uint256 ucCeilingPrice = ucCrawlingBand.getCurrentCeilingPrice();
//         uint256 ucAmount = (_amount.mul(cToken.price)).div(ucCeilingPrice);
//         require(ucAmount >= _minUCAmount, "Calculated UC amount below minimum.");

//         // transfer to reserves
//         cToken.balance = cToken.balance.add(_amount);
//         require(cToken.token.transferFrom(msg.sender, address(this), _amount), "Transfer of collateral failed.");
//         //if (!cToken.token.transferFrom(msg.sender, address(this), _amount)) revert("Transfer of collateral failed.");

//         // mint UC
//         require(ucToken.mint(msg.sender, ucAmount), "Couldn't mint UC token.");

//         emit Mint(_amount, msg.sender, _amount, _collateralToken);

//         return true;
//     }

//     /// EVENTS

//     /**
//      * @dev Emitted when UC tokens are created
//      *
//      *
//      * Note that `value` may be zero.
//      */
//     event Mint(uint256 amount, address indexed to, uint256 cost, address indexed collateral);

//     /**
//      * @dev Emitted UC tokens are destroied
//      *
//      */
//     event Burn(uint256 amount, address indexed from, uint256 returned, address indexed collateral);

//     /**
//      * @dev Emitted when collateral tokens are deposited
//      *
//      */
//     event Deposit(address collateralToken, address indexed from, uint256 amount, uint256 usdAmount);

//     event OrderBookChange(address addr, bytes32 key, string eventType, uint256 amount, uint256 price, uint256 expirationInMinutes);

//     event CollateralAdded(address addr, uint256 amount);

// }