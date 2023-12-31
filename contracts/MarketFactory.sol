//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.6;

import "./interfaces/IMarketFactory.sol";
import "./Market.sol";

contract MarketFactory {

    address public ratingAddress;
    address public deployerAddress;
    address public mediationAddress;
    address public bankAddress;

    constructor () {
        deployerAddress = msg.sender;
    }

    mapping(address => address[]) public markets; // Merchant Address => Markets
    mapping(address => bool) public isMarket; 
    address[] allMarkets; // Can fetch all merchants from market contract

    event MarketCreated(address merchant, address market);

    function createMarket (string memory _name) external
    {
        Market market = new Market(_name, msg.sender, ratingAddress, mediationAddress, bankAddress);
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

    function returnAllMarkets () external view returns (address[] memory)
    {
        return allMarkets;
    }

    function updateRatingAddress (address _ratingAddress) external {
        require(msg.sender == deployerAddress, "Sunflower-V1/FORBIDDEN");
        ratingAddress = _ratingAddress;
    }

    function updateMediationAddress (address _mediationAddress) external {
        require(msg.sender == deployerAddress, "Sunflower-V1/FORBIDDEN");
        mediationAddress = _mediationAddress;
    }

    function updateBankAddress (address _bankAddress) external {
        require(msg.sender == deployerAddress, "Sunflower-V1/FORBIDDEN");
        bankAddress = _bankAddress;
    }
}