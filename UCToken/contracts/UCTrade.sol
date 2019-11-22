pragma solidity >=0.4.21 <0.6.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./UCToken.sol";
import "./UCStorage.sol";
import "./UCCrawlingBand.sol";
import "./UCCollateralTokenInterface.sol";

/**
 * @title UCTrade
 * @dev Contract destination for aquiring and selling UCs.
 */
contract UCTrade is ReentrancyGuard {
    using SafeMath for uint256;

    address public admin;
    UCToken public ucToken;
    //UCStorage public ucStorage;
    UCCrawlingBand public ucCrawlingBand; // The reference to UCCrawlingBand implementation.

    //uint256 private _currentRate; // simple test as if there was only one acceptable stablecoin

    constructor(UCToken _ucToken, UCCrawlingBand _ucCrawlingBand) public {
        admin = msg.sender;
        ucToken = _ucToken;
        //ucStorage = _ucStorage;
        ucCrawlingBand = _ucCrawlingBand;
    }

    // MODIFIERS
    modifier onlyAdmin() {
        require(msg.sender == address(admin), "admin only function");
        _;
    }

    struct CollateralToken {
        address tokenAddr; // acceptable ERC20 token address
        uint256 price; // price in US Dollar / 10000000 (7 decimals)
        uint256 balance; // total amount of tokens
        UCCollateralTokenInterface token;
    }
    mapping (address => CollateralToken) public collateralTokens; //mapping of accepted token addresses balances

    function acceptNewCollateralToken(address _tokenAddr, uint256 _price) public onlyAdmin {
        // TODO: check if is ERC compatible token

        // check if token hasn't been included yet
        require (collateralTokens[_tokenAddr].tokenAddr == address(0), "Collateral token already included.");

        collateralTokens[_tokenAddr] = CollateralToken({
            tokenAddr: _tokenAddr,
            price: _price,
            balance: 0,
            token: UCCollateralTokenInterface(_tokenAddr)
        });
    }

    struct SaleOrder {
    address addr; // acccount address
    uint amount; // UC amount to sell
    uint price;  // price is willing to sell
    uint expirationInMinutes; // how long the order should valid, in minutes, before expiring
    }

    struct PurchaseOrder {
    address addr;
    uint amount; // UC amount wants to purchase
    uint price;  // UC price
    uint expirationInMinutes; // how long the order should valid, in minutes, before expiring
    }

    
    /**
     * @dev Make new tokens in exchangefor collateral and assign to sender
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param _collateralToken collateral Token Address
     * @param _amount amount of collateral Token to exchange
     * @param _minUCAmount minimum amount of UCs desired in exchange for the collateral
     * @return The amount of UCs buyer received
     */
    function mint(address _collateralToken, uint256 _amount, uint256 _minUCAmount) public nonReentrant returns (uint256) {
        require(_amount > 0, "collateral required");

        CollateralToken storage cToken = collateralTokens[_collateralToken];
        // make sure token is an approved token
        require (cToken.tokenAddr != address(0), "Collateral token no found.");

        // check rate
        uint256 ucCeilingPrice = ucCrawlingBand.getCurrentCeilingPrice();
        uint256 ucAmount = _amount.mul((cToken.price.div(ucCeilingPrice)));
        require(ucAmount >= _minUCAmount, "Calculated UC amount below minimum.");

        // transfer to reserves
        cToken.balance = cToken.balance.add(_amount);
        require(cToken.token.transferFrom(msg.sender, address(this), _amount), "Transfer of collateral failed.");
        //if (!cToken.token.transferFrom(msg.sender, address(this), _amount)) revert("Transfer of collateral failed.");

        // mint UC
        require(ucToken.mint(msg.sender, ucAmount), "Couldn't mint UC token.");

        return ucAmount;
    }

    /**
     * @dev Exchange UCs for collateral, burMake new tokens in exchangefor collateral and assign to sender
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param _collateralToken collateral Token Address
     * @param _amount amount of UC okens to burn
     * @return The amount of Collateral seller received
     */
    function burn(uint256 _amount, address _collateralToken) public nonReentrant returns (uint256) {
        require(_amount > 0, "UC amount required");
        uint256 balance = ucToken.balanceOf(msg.sender);
        require(balance >= _amount, "");

        // return default
        CollateralToken storage cToken = collateralTokens[_collateralToken];
        // make sure token is an approved token
        require (cToken.tokenAddr != address(0), "collateral token not found.");

        // check rate
        uint256 ucFloorPrice = ucCrawlingBand.getCurrentFloorPrice();
        uint256 cAmount = _amount.mul((ucFloorPrice.div(cToken.price)));
        //require(cAmount >= _minColAmount);

        // transfer from reserves
        if (!cToken.token.transferFrom(address(this), msg.sender, cAmount)) revert("Couldn't transfer collateral tokens");
        cToken.balance = cToken.balance.sub(cAmount);

        // burn UC
        ucToken.burn(msg.sender, _amount);

        return cAmount;

    }


}