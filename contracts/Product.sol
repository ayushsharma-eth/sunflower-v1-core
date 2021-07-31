pragma solidity >= 0.5.0;

import "./interfaces/IProduct.sol";

contract Product {

    address public owner;
    string public name;
    uint public quantity;
    uint[] public region;
    uint[] public category;

    constructor
    (
        address _owner,
        string memory _name,
        uint _quantity,
        uint[] memory _region,
        uint[] memory _category
    )
    public
    {
        owner = _owner;
        name = _name;
        quantity = _quantity;
        region = _region;
        category = _category;
    }

    function updateQuantity (uint _quantity) public {
        require(msg.sender == owner, "Caller not owner");
        quantity = _quantity;
    }

    function updateName (string memory _name) public {
        require(msg.sender == owner, "Caller not owner");
        name = _name;
    }

    function updateRegions (uint[] memory _region) public {
        require(msg.sender == owner, "Caller not owner");
        region = _region;
    }

}