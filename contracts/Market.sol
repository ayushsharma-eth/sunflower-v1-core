pragma solidity >=0.5.0;

import "./interfaces/IMarket.sol";
import "./Storefront.sol";

contract Market {

    mapping(address => address[]) public storefront; //Input address of user, recieve storefront addresses

    event StoreFrontCreated(address owner, address storefront, uint);

    function createStorefront (string memory name) public {
        
    }





}