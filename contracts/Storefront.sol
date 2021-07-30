pragma solidity >=0.5.0;

contract Storefront {

    string public name;
    address public owner;

    constructor(
        string memory _nameOfStorefront,
        address _owner
    )
    public
    {
        name = _nameOfStorefront;
        owner = _owner;
    }

    function createProduct () public 
    {
        require(msg.sender == owner, "Caller is not owner");
        

    }

}   