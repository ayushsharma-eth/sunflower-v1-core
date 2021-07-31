pragma solidity >=0.5.0;

import "./interfaces/IOrder.sol";

// Has Ethereum Balance

contract Order {

    address payable public customer;
    address payable public merchant;
    address public product;

    string public encryptedAddress; //encrypted with merchant's public key
    uint public quantity;
    bool public accepted;

    uint public escrowAmount;
    uint public escrowCurrency; //ETH: 0, DAI: 1

    constructor
    (
        address payable _customer,
        address payable _merchant,
        address _product,

        string memory _encryptedAddress, //encrypted with merchant's public key
        uint  _quantity,

        uint  _escrowAmount,
        uint  _escrowCurrency
    )
    {
        customer = _customer;
        merchant = _merchant;
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
            bool sent = merchant.send(escrowAmount);
            require(sent == true, "Transfer failed");
        }
        else
        {
            revert("Currency not yet supported");
        }
    }


    // Buyer can revoke escrow at any time if order not accepted
    function revokeEscrow () public {
        require (msg.sender == customer, "Not Customer");
        require (accepted == false, "Already accepted");
        bool sent = customer.send(escrowAmount);
        require(sent == true, "Transfer failed");
    }

    function accept () public {
        require (msg.sender == product);
        accepted = true;
    }

    function fund() external payable {
        //require(msg.sender == OrderFactory);
    }

}