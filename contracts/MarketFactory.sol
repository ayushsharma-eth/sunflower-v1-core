pragma solidity >=0.5.0;

import "./interfaces/IMarketFactory.sol";
import "./Market.sol";

contract MarketFactory {

    mapping(address => address[]) public markets; // Merchant Address => Markets

    event MarketCreated(address merchant, address market);

    function createMarket (string memory _name) external
    {
        Market market = new Market(_name, msg.sender);
        markets[msg.sender].push(address(market));

        emit MarketCreated(msg.sender, address(market));
    }

    function returnMarkets (address merchant) external view returns (address[] memory)
    {
        return markets[merchant]; // Return all markets of given merchant
    }
}