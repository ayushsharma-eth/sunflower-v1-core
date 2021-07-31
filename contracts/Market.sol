pragma solidity >=0.5.0;

import "./interfaces/IMarket.sol";

contract Market {

    bytes32 public name;
    address public merchant;
    uint public productCount;
    
    constructor
    (
        bytes32 _name,
        address _merchant
    )
    {
        name = _name;
        merchant = _merchant;
        productCount = 0;
    }

    struct Product {
        bytes32 name;
        uint32 quantity;
        uint price;
        uint8 currency;
        uint8[] region;
        uint8[] category;
    }
    
    struct Order {
        bool accepted;
        address payable customer;
        uint product;

        bytes32 encryptedAddress; //encrypted with merchant's public key
        uint32 quantity;

        uint  escrowAmount;
        uint8  escrowCurrency;
    }
    
    mapping(uint => Product) public products; // Product ID to Product Structure
    mapping(uint => Order[]) public orders; // Product ID to Order Structures
    
    event ProductCreated(bytes32 name, uint32 quantity, uint price, uint8 currency, uint8[] _region, uint8[] _category);

    function createProduct (bytes32 _name, uint32 _quantity, uint _price, uint8 _currency, uint8[] memory _region, uint8[] memory _category) external returns (uint) {
        require (msg.sender == merchant, "Caller is not Merchant");
        
        Product memory product = Product(
            _name,
            _quantity,
            _price,
            _currency,
            _region,
            _category
        );
        
        products[productCount] = product;

        emit ProductCreated(_name, _quantity, _price, _currency, _region, _category);
        
        return productCount++;
    }

    function purchaseWithEth(uint productId, bytes32 encryptedAddress, uint32 quantity) external payable
    {
        
        Product memory product = products[productId];
        
        require(product.quantity >= quantity, "Insufficient stock");

        uint price = product.price;
        uint cost = price * quantity;
         
        require(msg.value == cost, "Incorrect Amount Sent");

        Order memory order = Order(
            false,
            payable(msg.sender),
            productId,
            encryptedAddress,
            quantity,
            cost,
            product.currency
        );

        // Add order to both maps
        orders[productId].push(order);
    }
    
    function approveOrder (uint productId, uint orderId) external {
        require(msg.sender == merchant, "Caller not Merchant");
        require(!orders[productId][orderId].accepted, "Already accepted");
        
        orders[productId][orderId].accepted = true;
        
        // Deduct Product Contract

        require(orders[productId][orderId].quantity <= products[productId].quantity, "Insufficient stock to accept order");
        products[productId].quantity -= orders[productId][orderId].quantity;
    }
    
    
    function releaseEscrow (uint productId, uint orderId) external {
        require (msg.sender == orders[productId][orderId].customer, "Caller not customer");
        
        bool sent = payable(merchant).send(orders[productId][orderId].escrowAmount);
        require(sent == true, "Transfer failed");
        
        delete orders[productId][orderId];
    }

    
    function revokeEscrow (uint productId, uint orderId) external {
        require(msg.sender == orders[productId][orderId].customer, "Caller not customer");
        require(!orders[productId][orderId].accepted, "Already accepted");

        bool sent = orders[productId][orderId].customer.send(orders[productId][orderId].escrowAmount);
        require(sent == true, "Tranfer failed");
        
        delete orders[productId][orderId];
    }
    
}   