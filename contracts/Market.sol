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
    
    event ProductCreated(string name, uint quantity, uint price, uint currency, uint[] _region, uint[] _category);

    function createProduct (string memory _name, uint _quantity, uint _price, uint _currency, uint[] memory _region, uint[] memory _category) public returns (address) {
        require (msg.sender == owner, "Caller does not own Market");
        
        Product product = new Product(payable(msg.sender), _name, _quantity, _price, _currency, _region, _category);
        products.push(address(product));
        
        emit ProductCreated(_name, _quantity, _price, _currency, _region, _category);

        return address(product);
    }


}   