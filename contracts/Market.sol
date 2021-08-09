//SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;
pragma experimental ABIEncoderV2;

import "./interfaces/IMarket.sol";
import "./Rating.sol";
import "./Mediation.sol";

contract Market {

    string public name;
    address public merchant;
    address public ratingAddress;
    address public mediationAddress;
    uint public productIndex;
    uint public totalProducts;
    
    constructor
    (
        string memory _name,
        address _merchant,
        address _ratingAddress
    ) {
        name = _name;
        merchant = _merchant;
        ratingAddress = _ratingAddress;
        productIndex = 0;
        totalProducts = 0;
    }

    struct Product {
        string name;
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

        string encryptedAddress; //encrypted with merchant's public key
        uint32 quantity;

        uint escrowAmount;
        uint8 escrowCurrency;

        uint8 region;

        address arbitrator;
    }
    
    mapping(uint => Product) public products; // Product ID to Product Structure (use loop that incrementes by 1 from 0 until you find all order structures, as given by totalProducts)
    mapping(uint => Order[]) public orders; // Product ID to Order Structures
    mapping(uint => uint) public totalOrders; // Product ID to number of Orders (use loop that incrementes by 1 from 0 until you find all order structures, as given by totalOrders)
    
    event ProductCreated(string name, uint32 quantity, uint price, uint8 currency, uint8[] _region, uint8[] _category, uint index);
    event ProductDeleted(string name, uint index);

    // Merchant functions

    function createProduct (string memory _name, uint32 _quantity, uint _price, uint8 _currency, uint8[] memory _region, uint8[] memory _category) external
    {
        require (msg.sender == merchant, "Caller is not Merchant");
        
        Product memory product = Product(
            _name,
            _quantity,
            _price,
            _currency,
            _region,
            _category
        );
        
        products[productIndex] = product;
        totalProducts++;

        emit ProductCreated(_name, _quantity, _price, _currency, _region, _category, productIndex++);
    }

    function deleteProduct (uint productId) external 
    {
        require(msg.sender == merchant, "Caller not Merchant");

        emit ProductDeleted(products[productId].name, productId);

        delete products[productId];
        delete orders[productId];

        totalProducts--;
    }

    function approveOrder (uint productId, uint orderId) external {
        require(msg.sender == merchant, "Caller not Merchant");
        require(!orders[productId][orderId].accepted, "Already accepted");
        
        orders[productId][orderId].accepted = true;
        
        // Deduct Product Contract

        require(orders[productId][orderId].quantity <= products[productId].quantity, "Insufficient stock to accept order");
        products[productId].quantity -= orders[productId][orderId].quantity;
    }

    // Manual Management functions

    function updateMarketName (string memory _name) external 
    {
        require(msg.sender == merchant, "Caller not merchant");
        name = _name;
    }

    function updateProductQuantity (uint32 quantity, uint productId) external 
    {
        require(msg.sender == merchant, "Caller not merchant");
        products[productId].quantity = quantity;
    }

    function updateProductName (string memory _name, uint productId) external 
    {
        require(msg.sender == merchant, "Caller not merchant");
        products[productId].name = _name;
    }

    function updateProductRegions (uint8[] memory region, uint productId) external 
    {
        require(msg.sender == merchant, "Caller not merchant");
        products[productId].region = region;
    }

    // Customer functions

    function purchaseWithEth(uint productId, string memory encryptedAddress, uint32 quantity, uint8 region, address arbitrator) external payable
    {        
        require(products[productId].quantity >= quantity, "Insufficient stock");

        uint price = products[productId].price;
        uint cost = price * quantity;
         
        require(msg.value == cost, "Incorrect Amount Sent");

        bool matchRegion = false;
        for (uint i = 0; i < products[productId].region.length; i++)
        {
            if (products[productId].region[i] == region)
            {
                matchRegion == true;
                break;
            }
        }

        require(matchRegion, "Region not accepted");

        Mediation mediation = Mediation(mediationAddress);
        if (arbitrator != address(0)) // Enter ZERO_ADDRESS for no Arbitrator
            require(mediation.isArbitrator(arbitrator), "Provided Arbitrator Address is not an Arbitrator");

        Order memory order = Order(
            false,
            payable(msg.sender),
            productId,
            encryptedAddress,
            quantity,
            cost,
            products[productId].currency,
            region,
            arbitrator
        );

        orders[productId].push(order);
        totalOrders[productId]++;
    }
    
    function releaseEscrow (uint productId, uint orderId) external 
    {
        require (orders[productId][orderId].accepted, "Not yet accepted"); // Neither buyer or merchant can release before accepted
        require (msg.sender == orders[productId][orderId].customer || msg.sender == merchant, "Caller not customer or merchant");

        bool sent = payable(merchant).send(orders[productId][orderId].escrowAmount);
        require(sent == true, "Transfer failed");
        
        // Enable Reviews
        Rating rating = Rating(ratingAddress);
        rating.mayReview(address(this), productId, merchant, orders[productId][orderId].customer, orders[productId][orderId].arbitrator, orderId);

        delete orders[productId][orderId];
        totalOrders[productId]--;
    }

    function revokeEscrow (uint productId, uint orderId) external 
    {
        require(msg.sender == orders[productId][orderId].customer, "Caller not customer");
        require(!orders[productId][orderId].accepted, "Already accepted");

        bool sent = orders[productId][orderId].customer.send(orders[productId][orderId].escrowAmount);
        require(sent == true, "Tranfer failed");
        
        delete orders[productId][orderId];
        totalOrders[productId]--;
    }
    
}   