pragma solidity >=0.4.21 <0.6.0;


/**
 * @title UCCrawlingBand
 * @dev Business logic for the UC price crawling band target in US Dollars.
 */
contract UCCrawlingBand {

    uint256 public latestCeilingPrice = 10000000; // lastest updated CeilingPrice in US Dollar / 10000000 (7 decimals)
    uint256 public latestFloorPrice = 9000000; // lastest updated FloorPrice in US Dollar / 10000000 (7 decimals)

    /**
     * @dev Returns the current target UC ceiling price in US Dollar.
     * Note that...
     * TODO: implement pause modifier
     * @return UC Ceiling Price in US Dollar
     */
    function getCurrentCeilingPrice() public view returns (uint256) {
        // uint256 elapsedTime = block.timestamp.sub(openingTime());
        // uint256 timeRange = closingTime().sub(openingTime());
        // uint256 rateRange = _initialRate.sub(_finalRate);
        // return _initialRate.sub(elapsedTime.mul(rateRange).div(timeRange));
        
        // for testing purpose
        return latestCeilingPrice;
    }
    /**
     * @dev Returns the current target UC floor price in US Dollar / 10000000.
     * Note that...
     * TODO: implement pause modifier
     * @return UC Floor Price in US Dollar in US Dollar / 10000000
     */
    function getCurrentFloorPrice() public view returns (uint256) {
        // uint256 elapsedTime = block.timestamp.sub(openingTime());
        // uint256 timeRange = closingTime().sub(openingTime());
        // uint256 rateRange = _initialRate.sub(_finalRate);
        // return _initialRate.sub(elapsedTime.mul(rateRange).div(timeRange));
        
        // for testing purpose
        return latestFloorPrice;
    }

}