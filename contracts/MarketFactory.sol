pragma solidity >=0.5.0;

import "./interfaces/IMarketFactory.sol";
import "./Market.sol";

contract MarketFactory {

    mapping(address => address[]) public storefront; //Input address of user, recieve storefront addresses

    event MarketCreated(address owner, address storefront, uint);

    function createMarket (string memory name) public {
        
    }





}