pragma solidity >=0.8.6;

import "./Market.sol";

contract Bank {
    
    address public marketFactoryAddress;
    address public ratingAddress;

    constructor
    (
        address _marketFactoryAddress,
        address _ratingAddress
    )
    {
        marketFactoryAddress = _marketFactoryAddress;
        ratingAddress = _ratingAddress;
    }

    struct Escrow {
        bool accepted;
        address customer;
        address merchant;
        address arbitrator;
        uint escrowAmount;
    }

    mapping(address => uint) public sunBalance; // Unstaked suns
    mapping(address => uint) public stakedBalance;
    mapping(address => uint) public ethBalance;
    mapping(address => uint) public daiBalance;
    mapping(address => mapping(uint => mapping(uint => Escrow))) public ethEscrow; // [marketAddress][productId][orderId] = Escrow struct
    mapping(address => mapping(uint => mapping(uint => Escrow))) public daiEscrow;

    // Deposit/Withdraw Functions

    function withdrawEth (uint amount) external {
        require(amount <= ethBalance[msg.sender], "Insufficient Balance");
        bool sent = payable(msg.sender).send(amount);
        require(sent == true, "Transfer failed");
        ethBalance[msg.sender] -= amount;
    }

    function depositEth (address target) external {
        ethBalance[target] += msg.value;
    }

    // Market Functions

    function purchaseWithEth(address marketAddress, uint productId, string memory encryptedAddress, uint32 quantity, uint8 region, address arbitrator) external payable
    {        
        MarketFactory MF = MarketFactory(marketFactoryAddress);
        require(MF.isMarket(marketAddress), "Invalid Market Address");

        Market market = Market(marketAddress);
        market.recieveOrderEth(payable(msg.sender), productId, encryptedAddress, quantity, msg.value, 0, region, arbitrator);

        // Order was valid if they got this far
        address merchant = market.merchant();

        uint orderId = market.totalOrders(productId);
        ethEscrow[marketAddress][productId][--orderId] = Escrow(false, msg.sender, merchant, arbitrator, msg.value);
    }

    function acceptOrderEth(uint productId, uint orderId) external {
        MarketFactory MF = MarketFactory(marketFactoryAddress);
        require(MF.isMarket(msg.sender), "Sunflower-V1/FORBIDDEN");

        ethEscrow[msg.sender][productId][orderId].accepted = true;
    }

    function releaseEscrowEth (address marketAddress, uint productId, uint orderId, uint dst) external 
    {
        // dst => 0: Buyer 1: Merchant
        require (dst == 0 || dst == 1, "Invalid Destination");
        require (ethEscrow[marketAddress][productId][orderId].accepted, "Not yet accepted"); // Neither buyer, merchant, nor arbitrator can release before accepted

        if ((msg.sender == ethEscrow[marketAddress][productId][orderId].customer || msg.sender == ethEscrow[marketAddress][productId][orderId].arbitrator) && dst == 1) { // Buyer can release to Merchant
            // Add eth to merchant balance
            ethBalance[ethEscrow[marketAddress][productId][orderId].merchant] += ethEscrow[marketAddress][productId][orderId].escrowAmount;
            
            // Enable Reviews
            Rating rating = Rating(ratingAddress);
            rating.mayReview(address(this), productId, ethEscrow[marketAddress][productId][orderId].merchant, ethEscrow[marketAddress][productId][orderId].customer, ethEscrow[marketAddress][productId][orderId].arbitrator, orderId);

            delete ethEscrow[marketAddress][productId][orderId]; // Prevents multiple payouts & Clear Storage
        }

        if ((msg.sender == ethEscrow[marketAddress][productId][orderId].merchant || msg.sender == ethEscrow[marketAddress][productId][orderId].arbitrator) && dst == 0) { // Merchant can release to Buyer
            // Add eth to customer balance
            ethBalance[ethEscrow[marketAddress][productId][orderId].customer] += ethEscrow[marketAddress][productId][orderId].escrowAmount;

            // Enable Reviews
            Rating rating = Rating(ratingAddress);
            rating.mayReview(address(this), productId, ethEscrow[marketAddress][productId][orderId].merchant, ethEscrow[marketAddress][productId][orderId].customer, ethEscrow[marketAddress][productId][orderId].arbitrator, orderId);

            delete ethEscrow[marketAddress][productId][orderId]; // Prevents multiple payouts & Clear Storage
        }
        
        revert("Caller not party");
    }

    function revokeEscrowEth (address marketAddress, uint productId, uint orderId) external 
    {
        require(msg.sender == ethEscrow[marketAddress][productId][orderId].customer, "Caller not customer"); // Will revert if invalid market address
        require(!ethEscrow[marketAddress][productId][orderId].accepted, "Already accepted");

        // Add eth to customer balance;
        ethBalance[msg.sender] += ethEscrow[marketAddress][productId][orderId].escrowAmount;

        delete ethEscrow[marketAddress][productId][orderId]; // Prevents multiple payouts & Clear Storage
        Market market = Market(marketAddress);
        market.deleteOrder(productId, orderId);
    }

}