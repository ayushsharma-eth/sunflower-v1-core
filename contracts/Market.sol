pragma solidity >=0.5.0;

import "./interfaces/IMarket.sol";
import "./Product.sol";

contract Storefront {

    string public name;
    address public owner;

    constructor
    (
        string memory _nameOfStorefront,
        address _owner
    )
    public
    {
        name = _nameOfStorefront;
        owner = _owner;
    }

    function createProduct (string memory _name, uint _quantity, uint[] memory _region, uint[] memory _category) public {
        require (msg.sender == owner, "Caller does not own Storefront");
        
        //newProduct = new Product(msg.sender, _name, _quantity, _region, _category); 

        //return newProduct;
    }


}   