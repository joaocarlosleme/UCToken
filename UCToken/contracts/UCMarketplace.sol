pragma solidity >=0.4.21 <0.6.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "./UCToken.sol";
import "./UCStorage.sol";
import "./UCCrawlingBand.sol";
//import "./UCCollateralTokenInterface.sol"; // replaced by ERC20Detailed
import "./libraries/UnorderedKeySet.sol"; // or import {UnorderedKeySetLib} from "./libraries/UnorderedKeySet.sol";

/**
 * @title UCMarketplace
 * @dev Contract destination for aquiring and selling UCs.
 */
contract UCMarketplace is UCChangeable, ReentrancyGuard {
    using SafeMath for uint256;
    using UnorderedKeySetLib for UnorderedKeySetLib.Set;
    using UnorderedAddressSetLib for UnorderedAddressSetLib.Set;

    /// Public Properties

    /// Contract Navigation Properties
    UCToken public ucToken;
    UCCrawlingBand public ucCrawlingBand; // The reference to UCCrawlingBand implementation.
    //UCStorage public ucStorage;

    /// Objects (Structs)
    struct Collateral {
        address tokenAddr; // acceptable ERC20 token address
        uint256 price; // price in US Dollar / 1000000 (6 decimals)
        uint256 orderbookBalance; // total amount of tokens on orderBooks (contract balance)
        bool paused;
        ERC20Detailed token;
        mapping (address => uint256) balances; // maker balance for order books (user balances)
    }
    struct SaleOrder {
    address addr; // acccount address
    uint amount; // UC amount to sell
    uint price;  // price is willing to sell in USD
    address collateral; // the collareral seller wants in exchange
    uint256 expiration; // time the order expires
    }
    struct PurchaseOrder {
    address addr; // maker address
    uint amount; // UC amount wants to purchase
    //uint price;  // UC price in USD
    address collateral;
    uint collAmount;
    uint256 expiration; // time the order expires
    }

    /// Public Mappings
    mapping(address => Collateral) public collaterals; // mapping of collateralTokens by token address
    mapping(bytes32 => SaleOrder) public saleOrders;
    mapping(bytes32 => PurchaseOrder) public purchaseOrders;
    //mapping (address => uint256) public usdBalances; // amount of USD available for buyers to place orders on orderBook

    /// Private lists
    UnorderedAddressSetLib.Set collateralsSet;
    UnorderedKeySetLib.Set saleOrdersSet;
    UnorderedKeySetLib.Set purchaseOrdersSet;

    /// Modifiers
    modifier collateralActive(address collateral) {
        require(collateralsSet.exists(collateral), "Collateral doesn't exist");
        require(!collaterals[collateral].paused, "Collateral temporary paused.");
        _;
    }

    constructor(address pathAddress) UCChangeable(pathAddress, "UCMarketplace") public {
        ucToken = UCToken(ucPath.getPath("UCToken"));
        ucCrawlingBand = UCCrawlingBand(ucPath.getPath("UCCrawlingBand"));
    }

    /// Public Methods - Authorized only

    function acceptNewCollateral(address _tokenAddr, uint256 _price, bool _paused) public auth {
        // TODO: check if is ERC compatible token

        // check if token hasn't been included yet
        collateralsSet.insert(_tokenAddr); // Note that this will fail automatically if the _tokenAddr already exists.
        //require (collaterals[_tokenAddr].tokenAddr == address(0), "Collateral token already included.");

        collaterals[_tokenAddr] = Collateral({
            tokenAddr: _tokenAddr,
            price: _price,
            orderbookBalance: 0,
            paused: _paused,
            token: ERC20Detailed(_tokenAddr)
        });
        emit NewCollateral(_tokenAddr, _price, _paused);
    }
    function updateCollateral(address _tokenAddr, uint256 _price, bool _paused) public auth {
        require(collateralsSet.exists(_tokenAddr), "Collateral doesn't exist");
        Collateral storage c = collaterals[_tokenAddr];
        c.price = _price;
        c.paused = _paused;
        emit CollateralUpdated(_tokenAddr, _price, _paused);
    }

    /// Public Methods
    function getCollateralsCount() public view returns(uint count) {
        return collateralsSet.count();
    }
    function getCollateralAddressAtIndex(uint _index) public view returns(address _address) {
        return collateralsSet.keyAtIndex(_index);
    }
    function getCollateralBalance(address _tokenAddr, bool includeOrderbook) public view returns (uint256) {
        require(collateralsSet.exists(_tokenAddr), "Collateral doesn't exist");
        uint256 totalAmount = collaterals[_tokenAddr].token.balanceOf(address(this));
        if(includeOrderbook) {
            return totalAmount;
        } else {
            return totalAmount.sub(collaterals[_tokenAddr].orderbookBalance);
        }
    }
    function getCollateralRate(address _tokenAddr) public returns(uint256 rate) {
        require(collateralsSet.exists(_tokenAddr), "Collateral doesn't exist");
        return collaterals[_tokenAddr].price.div(ucCrawlingBand.getCurrentCeilingPrice());
    }

    function addSaleOrder(uint _amount, uint _price, address _collateral, uint _expiration) public collateralActive(_collateral) {
        require(_amount > 0, "UC amount required");
        //require(collateralsSet.exists(_collateral), "Collateral doesn't exist");
        // check if sender has enough balance
        require(ucToken.transferFrom(msg.sender, address(this), _amount), "Couldn't transfer UC token.");

        bytes32 key = keccak256(abi.encodePacked(msg.sender, _amount, _price, _collateral, _expiration, block.number));
        saleOrdersSet.insert(key); // Note that this will fail automatically if the key already exists.
        SaleOrder storage o = saleOrders[key];
        o.amount = _amount;
        o.price = _price;
        o.collateral = _collateral;
        o.expiration = _expiration;
        emit OrderBookChange(msg.sender, key, "addSaleOrder", _price, _collateral, _expiration);
    }
    //// instead of update, must remove and place another one.
    // function updateSaleOrder(bytes32 _key, uint _amount, uint _price, uint _expirationInMinutes) public {
    //     require(saleOrdersSet.exists(_key), "SaleOrder doesn't exist");
    //     SaleOrder storage o = saleOrders[_key];
    //     require(o.addr = msg.sender, "order doesn't belong to sender");
    //     o.amount = _amount;
    //     o.price = _price;
    //     o.prexpirationInMinutesice = _expirationInMinutes;
    //     emit OrderBookChange(msg.sender, _key, "updateSaleOrder", _price, _expirationInMinutes);
    // }
    function cancelSaleOrder(bytes32 _key) public {
        require(saleOrdersSet.exists(_key), "SaleOrder doesn't exist");
        SaleOrder storage o = saleOrders[_key];
        require(o.addr == msg.sender, "order doesn't belong to sender");
        require(ucToken.transferFrom(address(this), msg.sender, o.amount), "Couldn't transfer UC token.");

        saleOrdersSet.remove(_key); // Note that this will fail automatically if the key doesn't exist
        delete saleOrders[_key];
        emit OrderBookChange(msg.sender, _key, "SaleOrderCancelled", o.price, o.addr, o.expiration);
    }
    function getSaleOrdersCount() public view returns(uint count) {
        return saleOrdersSet.count();
    }
    function getSaleOrderKeyAtIndex(uint _index) public view returns(bytes32 key) {
        return saleOrdersSet.keyAtIndex(_index);
    }

    function matchSaleOrder(bytes32 _key, address _buyer, address _collateral, uint256 _amount)
        public collateralActive(_collateral) returns (bool) {
        require(saleOrdersSet.exists(_key), "SaleOrder doesn't exist");
        require(collateralsSet.exists(_collateral), "Collateral doesn't exist");

        SaleOrder storage o = saleOrders[_key];
        // check sale order expiration
        if(o.expiration <= now) {
            cancelSaleOrder(_key);
            revert("Sale order expired.");
        }
        Collateral storage c = collaterals[_collateral];
        // check price match
        uint256 offerTotalValue = c.price.mul(_amount);
        uint256 saleTotalValue = o.price.mul(o.amount);
        require(offerTotalValue >= saleTotalValue, "asking price above offer");
        // check buyer funds
        uint256 buyerBalance = c.balances[msg.sender]; // amount of collateral buyer already transfered
        if(_amount > buyerBalance) {
            addCollateral(_collateral, _amount.sub(buyerBalance));
        }
        // remove collateral from buyer
        debitCollateral(c, msg.sender, _amount);
        // add collateral to seller
        Collateral storage sc = collaterals[o.collateral];
        uint256 scAmount = saleTotalValue.div(sc.price);
        transferCollateral(sc.token, o.addr, scAmount);
        // transfer UCs
        ucToken.transfer(_buyer, o.amount);

        deleteSaleOrder(_key);

        // maybe break orderBookChange into 3 events (new, removed, match)
        emit OrderBookChange(_buyer, _key, "matchSaleOrder", offerTotalValue, _collateral, o.expiration);

        return true;
    }



    /**
     * @dev Deposit collateral for placing purchase orders.
     * The equivalent amount of USD is credited for placing the orders at a later time.
     * @param _collateral collateral Token Address
     * @param _amount amount of collateral Token to exchange
     */
    function addCollateral(address _collateral, uint256 _amount) public collateralActive(_collateral) {
        //require(collateralsSet.exists(_collateral), "Collateral doesn't exist");
        Collateral storage cToken = collaterals[_collateral];
        // transfer to collateral reserves
        require(cToken.token.transferFrom(msg.sender, address(this), _amount), "Transfer of collateral failed.");
        // // credit USD
        // //uint256 ucCeilingPrice = ucCrawlingBand.getCurrentCeilingPrice();
        // uint256 usdAmount = _amount.mul(cToken.price);
        // usdBalances[msg.sender] = usdBalances[msg.sender].add(usdAmount);

        // credit collateral balance to user
        creditCollateral(cToken, msg.sender, _amount);

        emit Deposit(_collateral, msg.sender, _amount);
    }

    // // sample function for Ether deposits
    // function deposit() payable {
    //     tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
    //     lastActiveTransaction[msg.sender] = block.number;
    //     Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    // }

    function withdraw(address _collateral, uint256 _amount) public returns (bool success) {
        require(collateralsSet.exists(_collateral), "Collateral doesn't exist");
        Collateral storage cToken = collaterals[_collateral];
        // remove credit collateral balance from user & check enough balance
        debitCollateral(cToken, msg.sender, _amount);
        // transfer from collateral reserves
        transferCollateral(cToken.token, msg.sender, _amount);
        return true;
    }

    /**
     * @dev Make new tokens in exchangefor collateral and assign to sender
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param _collateral collateral Token Address
     * @param _amount amount of collateral Token to exchange
     * @param _minUCAmount minimum amount of UCs desired in exchange for the collateral
     * @return The amount of UCs buyer received
     */
    function mint(address _collateral, uint256 _amount, uint256 _minUCAmount) public nonReentrant collateralActive(_collateral) returns (bool) {
        require(_amount > 0, "collateral required");

        Collateral storage cToken = collaterals[_collateral];
        // make sure token is an approved token
        require (cToken.tokenAddr != address(0), "Collateral token not found.");

        // check rate
        uint256 ucCeilingPrice = ucCrawlingBand.getCurrentCeilingPrice();
        uint256 ucAmount = (_amount.mul(cToken.price)).div(ucCeilingPrice);
        require(ucAmount >= _minUCAmount, "Calculated UC amount below minimum.");

        // transfer to reserves // TODO: place reserves on different contract to differentiate balance from orderbook balance
        //cToken.balance = cToken.balance.add(_amount); // no longer dduplicating balance. Use function to get balance from token contract.
        require(cToken.token.transferFrom(msg.sender, address(this), _amount), "Transfer of collateral failed.");
        //if (!cToken.token.transferFrom(msg.sender, address(this), _amount)) revert("Transfer of collateral failed.");

        // mint UC
        require(ucToken.mint(msg.sender, ucAmount), "Couldn't mint UC token.");

        emit Mint(_amount, msg.sender, _amount, _collateral);

        return true;
    }

    /**
     * @dev Exchange UCs for collateral, burMake new tokens in exchangefor collateral and assign to sender
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param _amount amount of UC okens to burn
     * @param _collateral collateral Token Address
     * @return The amount of Collateral seller received
     */
    function burn(uint256 _amount, address _collateral) public nonReentrant collateralActive(_collateral) returns (bool) {
        // TODO: implement check minimum balances for each collateral (maybe also do this check when placing an order)

        require(_amount > 0, "UC amount required");
        uint256 balance = ucToken.balanceOf(msg.sender);
        require(balance >= _amount, "");

        // return default
        Collateral storage cToken = collaterals[_collateral];
        // make sure token is an approved token
        require(cToken.tokenAddr != address(0), "collateral token not found.");

        // check rate
        uint256 ucFloorPrice = ucCrawlingBand.getCurrentFloorPrice();
        uint256 cAmount = (_amount.mul(ucFloorPrice)).div(cToken.price);
        //require(cAmount >= _minColAmount, "Collateral amount to receive is below minimum.");

        // transfer from reserves
        //if (!cToken.token.transfer(msg.sender, cAmount)) revert("Couldn't transfer collateral tokens");
        require(cToken.token.transfer(msg.sender, cAmount), "Couldn't transfer collateral tokens");
        cToken.orderbookBalance = cToken.orderbookBalance.sub(cAmount);

        // burn UC
        require(ucToken.burn(msg.sender, _amount), "Couldn't burn UC token.");

        emit Burn(_amount, msg.sender, cAmount, _collateral);

        //return cAmount;
        return true;

    }

    /**
     * @dev Get UC tokens in exchangefor collateral and assign to sender
     * Order is fulfilled either from OrderBook or Minted, whaever is cheaper
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param _collateral collateral Token Address
     * @param _amount amount of collateral Token to exchange
     * @param _minUCAmount minimum amount of UCs desired in exchange for the collateral
     * @return The amount of UCs buyer received
     */
    function buy(address _collateral, uint256 _amount, uint256 _minUCAmount) public nonReentrant returns (bool) {
        require(_amount > 0, "collateral required");

        Collateral storage cToken = collaterals[_collateral];
        // make sure token is an approved token
        require (cToken.tokenAddr != address(0), "Collateral token not found.");

        // check rate
        uint256 ucCeilingPrice = ucCrawlingBand.getCurrentCeilingPrice();
        uint256 ucAmount = (_amount.mul(cToken.price)).div(ucCeilingPrice);
        require(ucAmount >= _minUCAmount, "Calculated UC amount below minimum.");

        // transfer to reserves
        cToken.orderbookBalance = cToken.orderbookBalance.add(_amount);
        require(cToken.token.transferFrom(msg.sender, address(this), _amount), "Transfer of collateral failed.");
        //if (!cToken.token.transferFrom(msg.sender, address(this), _amount)) revert("Transfer of collateral failed.");

        // mint UC
        require(ucToken.mint(msg.sender, ucAmount), "Couldn't mint UC token.");

        emit Mint(_amount, msg.sender, _amount, _collateral);

        return true;
    }

    /**
     * @dev Get Total reserves balance (amount * price) for every collateral
     * @return The total reserves value in USD (6 decimals)
     */
    function getReservesBalance() public view returns(uint256) {
        uint256 totalBalance = 0;
        uint256 collateralCount = getCollateralsCount();
        for (uint256 i = 0; i < collateralCount; i++) {
            address collateralAddress = getCollateralAddressAtIndex(i);
            Collateral memory collateral = collaterals[collateralAddress];
            uint256 collateralBalance = getCollateralBalance(collateralAddress, false);
            totalBalance = totalBalance.add(collateralBalance.mul(collateral.price));
        }
        return totalBalance;
    }

    /// EVENTS

    /**
     * @dev Emitted when UC tokens are created
     *
     *
     * Note that `value` may be zero.
     */
    event Mint(uint256 amount, address indexed to, uint256 cost, address indexed collateral);

    /**
     * @dev Emitted UC tokens are destroied
     *
     */
    event Burn(uint256 amount, address indexed from, uint256 returned, address indexed collateral);

    /**
     * @dev Emitted when collateral tokens are deposited
     *
     */
    event Deposit(address indexed collateral, address indexed from, uint256 amount);

    /**
     * @dev Emitted when collateral tokens are withdrawn
     *
     */
    event Withdraw(address indexed collateral, address indexed to, uint256 amount);

    event NewCollateral(address indexed tokenAddr, uint256 price, bool paused);

    event CollateralUpdated(address tokenAddr, uint256 price, bool paused);

    event OrderBookChange(address addr, bytes32 key, string eventType, uint price, address collateral, uint expirationInMinutes);

    /// Private Methods

    /**
     * @dev Credit collateral to OrderBook Balance
     * It does not change collateral ownership
     *
     */
    function creditCollateral(Collateral storage collateral, address _to, uint256 _amount) private {
        // credit collateral balance to user
        collateral.balances[_to] = collateral.balances[_to].add(_amount);
        // add orderBook balance
        collateral.orderbookBalance = collateral.orderbookBalance.add(_amount);
    }
    /**
     * @dev Debit collateral from OrderBook
     * It does not change collateral ownership
     *
     */
    function debitCollateral(Collateral storage collateral, address _to, uint256 _amount) private {
        // debit amount from user collateral balance
        collateral.balances[_to] = collateral.balances[_to].sub(_amount, "Not enough balance");
        // add orderBook balance
        collateral.orderbookBalance = collateral.orderbookBalance.sub(_amount);
    }
    /**
     * @dev Credit collateral to OrderBook
     *
     */
    function transferCollateral(ERC20Detailed collateral, address _to, uint256 _amount) private {
        require(collateral.transfer(_to, _amount), "Transfer of collateral failed.");
        emit Withdraw(address(collateral), _to, _amount);
    }
    function deleteSaleOrder(bytes32 _key) private {
        saleOrdersSet.remove(_key); // Note that this will fail automatically if the key doesn't exist
        delete saleOrders[_key];
    }
}