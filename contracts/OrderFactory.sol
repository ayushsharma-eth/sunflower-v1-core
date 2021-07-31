pragma solidity >=0.5.0;

import "./interfaces/IOrderFactory.sol";
import "./Product.sol";
import "./Order.sol";

contract OrderFactory {
    
    mapping(address => address[]) orders; // Customer -> Orders
    mapping(address => address[]) productOrders; // Product -> Orders
    
    function purchaseWithEth (address productAddress, string memory encryptedAddress, uint32 quantity) public payable returns (address)
    {
        Product product = Product(productAddress);

        require(product.quantity() >= quantity, "Insufficient stock");

        uint price = product.price();
        uint cost = price * quantity;
         
        require(msg.value == cost, "Incorrect Amount Sent");

        Order order = new Order(payable(msg.sender), product.merchant(), productAddress, encryptedAddress, quantity, cost, product.currency());
        bool sent = payable(address(order)).send(msg.value);
        require(sent == true, "Failed to send Ether");

        // Add order to both maps
        orders[msg.sender].push(address(order));
        productOrders[productAddress].push(address(order));

        return address(order);
    }

    function returnOrders (address customer) public view returns (address[] memory)
    {
        return orders[customer]; //returns all orders of a customer
    }

    function returnProductOrders (address product) public view returns (address[] memory)
    {
        return productOrders[product]; //returns all orders of a customer
    }

}