pragma solidity >=0.5.0;

import "./interfaces/IOrder.sol";

// Has Ethereum Balance

contract Order {

    address public customer;
    address payable public seller;
    address public product;

    string public encryptedAddress; //encrypted with seller's public key
    uint public quantity;
    bool public accepted;

    uint public escrowAmount;
    uint public escrowCurrency; //ETH: 0, DAI: 1

    constructor
    (
        address _customer,
        address payable _seller,
        address _product,

        string memory _encryptedAddress, //encrypted with seller's public key
        uint  _quantity,

        uint  _escrowAmount,
        uint  _escrowCurrency
    )
    {
        customer = _customer;
        seller = _seller;
        product = _product;

        encryptedAddress = _encryptedAddress;
        quantity = _quantity;
        accepted = false;

        escrowAmount = _escrowAmount;
        escrowCurrency = _escrowCurrency;
    }

    function releaseEscrow () public {
        require (msg.sender == customer, "Not Customer");
        if (escrowCurrency == 0)
        {
            bool sent = seller.send(escrowAmount);
            require(sent == true, "Transfer failed");
        }
        else
        {
            revert("Currency not yet supported");
        }
    }

    function accept () public {
        require (msg.sender == product);
        accepted = true;
    }

    receive() external payable {
        //require(msg.sender == OrderFactory);
    }

}