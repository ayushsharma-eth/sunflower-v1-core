pragma solidity >= 0.5.0;

import "./interfaces/IProduct.sol";

contract Product {

    string public name;
    uint public quantity;
    uint[] public region;
    uint[] public category;

    constructor
    (
        string memory _name,
        uint _quantity,
        uint[] memory _region,
        uint[] memory _category
    )
    public
    {
        name = _name;
        quantity = _quantity;
        region = _region;
        category = _category;
    }
}