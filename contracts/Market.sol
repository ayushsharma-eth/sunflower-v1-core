pragma solidity >=0.5.0;

//import "./interfaces/IMarket.sol";
import "./Product.sol";

contract Market {

    bytes32 public name;
    address public owner;

    constructor
    (
        bytes32 _name,
        address _owner
    )
    {
        name = _name;
        owner = _owner;
    }

    address[] public products;
    
    event ProductCreated(bytes32 name, uint32 quantity, uint price, uint8 currency, uint8[] _region, uint8[] _category);

    function createProduct (bytes32 _name, uint32 _quantity, uint _price, uint8 _currency, uint8[] memory _region, uint8[] memory _category) external returns (address) {
        require (msg.sender == owner, "Caller does not own Market");
        
        Product product = new Product(payable(msg.sender), _name, _quantity, _price, _currency, _region, _category);
        products.push(address(product));
        
        emit ProductCreated(_name, _quantity, _price, _currency, _region, _category);

        return address(product);
    }


}   