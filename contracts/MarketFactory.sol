//SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./interfaces/IMarketFactory.sol";
import "./Market.sol";

contract MarketFactory {

    address public ratingAddress;

    constructor
    (
        address _ratingAddress
    ) {
        ratingAddress = _ratingAddress;
    }

    mapping(address => address[]) public markets; // Merchant Address => Markets
    //mapping(address => address) public merchants; // Market => Merchant Address
    mapping(address => bool) public isMarket; 
    address[] allMarkets; // Can fetch all merchants from market contract

    event MarketCreated(address merchant, address market);

    function createMarket (string memory _name) external
    {
        Market market = new Market(_name, msg.sender, ratingAddress);
        markets[msg.sender].push(address(market));
        //merchants[address(market)] = msg.sender;
        allMarkets.push(address(market));
        isMarket[address(market)] = true;

        emit MarketCreated(msg.sender, address(market));
    }

    function returnMarkets (address merchant) external view returns (address[] memory)
    {
        return markets[merchant]; // Return all markets of given merchant
    }

    // function returnMerchant (address market) external view returns (address)
    // {
    //     return merchants[market]; // Return merchant for given market
    // }
}