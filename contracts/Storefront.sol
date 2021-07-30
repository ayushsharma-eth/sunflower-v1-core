pragma solidity >=0.5.0;

import "./interfaces/IStorefront.sol";
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
        Product p = new Product (_name, _quantity, _region, _category);
    }


}   