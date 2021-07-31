pragma solidity >=0.5.0;

//import "./interfaces/IMarketFactory.sol";
import "./Market.sol";

contract MarketFactory {

    mapping(address => address[]) public markets; // Merchant Address => Markets

    event MarketCreated(address owner, address market);

    function createMarket (bytes32 _name) public returns (address)
    {
        Market market = new Market(_name, msg.sender);
        markets[msg.sender].push(address(market));

        emit MarketCreated(msg.sender, address(market));

        return address(market); // Returns address of newly created Market
    }

    function returnMarkets (address merchant) public view returns (address[] memory)
    {
        return markets[merchant]; // Return all markets of given merchant
    }
}