pragma solidity >= 0.5.0;

//import "./interfaces/IProduct.sol";
import "./Order.sol";

contract Product {

    address payable public merchant;
    bytes32 public name;
    uint32 public quantity;
    uint public price;
    uint8 public currency; //ETH is 0, DAI is 1
    uint8[] public region;
    uint8[] public category;

    constructor
    (
        address payable _merchant,
        bytes32 _name,
        uint32 _quantity,
        uint _price,
        uint8 _currency,
        uint8[] memory _region,
        uint8[] memory _category
    )
    {
        merchant = _merchant;
        name = _name;
        quantity = _quantity;
        price = _price;
        currency = _currency;
        region = _region;
        category = _category;
    }

    // Manual Management functions

    function updateQuantity (uint32 _quantity) external {
        require(msg.sender == merchant, "Caller not merchant");
        quantity = _quantity;
    }

    function updateName (bytes32 _name) external {
        require(msg.sender == merchant, "Caller not merchant");
        name = _name;
    }

    function updateRegions (uint8[] memory _region) external {
        require(msg.sender == merchant, "Caller not merchant");
        region = _region;
    }

    // Accept Orders

    function approveOrder (address payable _order) external {
        require(msg.sender == merchant, "Not Merchant");

        Order order = Order(_order);

        require(!order.accepted(), "Already accepted");
        require(order.product() == address(this), "Order does not belong to this Product");

        // Deduct Product Contract

        require(order.quantity() <= quantity, "Insufficient stock to accept order");
        uint32 newQuantity = quantity - order.quantity();
        quantity = newQuantity;
        order.accept();
    }
}