pragma solidity >=0.4.21 <0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./UCToken.sol";
import "./UCChangeable.sol";
import "./UCMarketplace.sol";

/**
 * @title UCCrawlingBand
 * @dev Business logic for the UC price crawling band target in US Dollars.
 */
contract UCCrawlingBand is UCChangeable {
    using SafeMath for uint256;

    /// Public Properties
    uint256 public latestCeilingPrice; // last used CeilingPrice in US Dollar / 100000 (6 decimals)
    uint256 public latestFloorPrice; // last used FloorPrice in US Dollar / 100000 (6 decimals)
    uint256 public latestTime; // time of latest call
    uint256 public band; // in % (10 means 10%)
    uint256 public crawlingRate; // price increase per hour (11 = 0,000011 = 0,1/(365*24))
    uint256 public detachRate; // number between 1 and 100: % of crawling Rate (100 means equal crawling rate)

    /// Contract Navigation Properties
    UCToken ucToken;
    UCMarketplace ucMarketplace;


    constructor(uint256 _band, uint256 _crawlingRate, address pathAddress) UCChangeable(pathAddress, "UCCrawlingBand") public {
        band = _band;
        crawlingRate = _crawlingRate;
        ucToken = UCToken(ucPath.getPath("UCToken"));
        detachRate = 100;
    }

    /// Public Methods
    function init() public {
        require(address(ucMarketplace) == address(0), "Already initialized");
        ucMarketplace = UCMarketplace(ucPath.getPath("UCMarketplace"));
    }
    function getEstimatedCeilingPrice() public returns (uint256) {
        latestTime = now;
        if(latestCeilingPrice == 0) {
            return 1000000;
        }
        uint256 elapsedHours = (now.sub(latestTime)).div(3600);
        uint256 proposedPrice = latestCeilingPrice.add(crawlingRate.mul(elapsedHours));
        require(proposedPrice > latestCeilingPrice, "Error calculating proposed price: must be higher than latestCeilingPrice.");
        uint256 estimatedFloorPrice = getEstimatedFloorPrice();
        // check if there can be an increase on floorPrice, otherwise do not increase CeilingPrice
        if(latestFloorPrice >= estimatedFloorPrice) {
            return latestCeilingPrice;
        }
        // Check if proposed price is within price band
        uint256 priceBandLimit = (estimatedFloorPrice.mul(band)).div(100);
        if(proposedPrice >= priceBandLimit)
        {
            proposedPrice = priceBandLimit;
        }
        return proposedPrice;
    }
    function getEstimatedFloorPrice() public returns (uint256) {
        latestTime = now;
        if(latestFloorPrice == 0) {
            return 900000;
        }

        // adjust crawling rate to include increase in spread (when ceiling price grows faster than floor price, detaching from reserves)
        uint256 floorPriceCrawlingRate = (crawlingRate.mul(detachRate)).div(100);
        require(floorPriceCrawlingRate <= crawlingRate, "Error calculating floorPriceCrawlingRate: cant be greater than CrawlingRate.");

        uint256 elapsedHours = (now.sub(latestTime)).div(3600);
        uint256 proposedPrice = latestFloorPrice.add(floorPriceCrawlingRate.mul(elapsedHours));
        require(proposedPrice > latestFloorPrice, "Calculated proposed price must be higher than latestFloorPrice.");

        // check if there can be an increase on floorPrice based on reserves
        uint256 totalReserves = ucMarketplace.getReservesBalance();
        uint256 totalSupply = ucToken.totalSupply();
        if(totalReserves < proposedPrice.mul(totalSupply)) {
            proposedPrice = totalReserves.div(totalSupply);
        }
        // Check if proposed price is within price band ???

        return proposedPrice;
    }
    /**
     * @dev Returns the current target UC ceiling price in US Dollar.
     * Note that...
     * TODO: implement pause modifier
     * @return UC Ceiling Price in US Dollar
     */
    function getCurrentCeilingPrice() public returns (uint256) {
        // latestTime = now;
        // if(latestCeilingPrice == 0) {
        //     latestCeilingPrice = 1000000;
        //     return latestCeilingPrice;
        // }
        // uint256 elapsedHours = (now.sub(latestTime)).div(3600);
        // uint256 proposedPrice = latestCeilingPrice.add(crawlingRate.mul(elapsedHours));
        // require(proposedPrice > latestCeilingPrice, "Calculated proposed price must be higher than latestCeilingPrice.");
        // uint256 estimatedFloorPrice = getEstimatedFloorPrice();
        // // check if there can be an increase on floorPrice, otherwise do not increase CeilingPrice
        // if(latestFloorPrice >= estimatedFloorPrice) {
        //     return latestCeilingPrice;
        // }
        // // Check if proposed price is within price band
        // uint256 priceBandLimit = (estimatedFloorPrice.mul(band)).div(100);
        // if(proposedPrice >= priceBandLimit)
        // {
        //     proposedPrice = priceBandLimit;
        // }

        // latestCeilingPrice = proposedPrice;
        // return latestCeilingPrice;

        uint256 calculatedCeilingPrice = getEstimatedCeilingPrice();
        if(calculatedCeilingPrice > latestCeilingPrice) {
            latestCeilingPrice = calculatedCeilingPrice;
        }
        return latestCeilingPrice;
    }
    /**
     * @dev Returns the current target UC floor price in US Dollar / 10000000.
     * Note that...
     * TODO: implement pause modifier
     * @return UC Floor Price in US Dollar in US Dollar / 10000000
     */
    function getCurrentFloorPrice() public returns (uint256) {
        uint256 calculatedFloorPrice = getEstimatedFloorPrice();
        if(calculatedFloorPrice == latestFloorPrice) {
            return latestFloorPrice;
        }
        latestFloorPrice = calculatedFloorPrice;
        return latestFloorPrice;
    }

    /// Events

    event BandChanged(uint256 previousBand, uint256 newBand);
    event CrawlingRateChanged(uint256 previousRate, uint256 newRate);
    event DetachRateChanged(uint256 previousRate, uint256 newRate);

}