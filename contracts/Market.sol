pragma solidity >=0.5.0;

import "./interfaces/IMarket.sol";
import "./Product.sol";

contract Market {

    string public name;
    address public owner;

    constructor
    (
        string memory _name,
        address _owner
    )
    {
        name = _name;
        owner = _owner;
    }

    address[] public products;
    
    event ProductCreated(string name, uint32 quantity, uint price, uint8 currency, uint8[] _region, uint8[] _category);

    function createProduct (string memory _name, uint32 _quantity, uint _price, uint8 _currency, uint8[] memory _region, uint8[] memory _category) public returns (address) {
        require (msg.sender == owner, "Caller does not own Market");
        
        Product product = new Product(payable(msg.sender), _name, _quantity, _price, _currency, _region, _category);
        products.push(address(product));
        
        emit ProductCreated(_name, _quantity, _price, _currency, _region, _category);

        return address(product);
    }


}   