//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.6;

import "./interfaces/IERC20.sol";
import "./Mediation.sol";
import "./Appeal.sol";
import "./Market.sol";
import "./MarketFactory.sol";
import "./Rating.sol";

contract Bank {
    
    address public tokenAddress;
    address public marketFactoryAddress;
    address public ratingAddress;
    address public mediationAddress;
    address public appealAddress;

    constructor
    (
        address _tokenAddress,
        address _marketFactoryAddress,
        address _ratingAddress,
        address _mediationAddress,
        address _appealAddress
    )
    {
        tokenAddress = _tokenAddress;
        marketFactoryAddress = _marketFactoryAddress;
        ratingAddress = _ratingAddress;
        mediationAddress = _mediationAddress;
        appealAddress = _appealAddress;
    }

    struct Escrow {
        bool accepted;
        address customer;
        address merchant;
        address arbitrator;
        uint escrowAmount;
    }

    mapping(address => uint) public sunBalance; // Unstaked suns (such as rewards)
    mapping(address => uint) public stakedBalance; // Staked suns
    mapping(address => uint) public ethBalance;
    mapping(address => uint) public daiBalance;
    mapping(address => mapping(uint => mapping(uint => Escrow))) public ethEscrow; // [marketAddress][productId][orderId] = Escrow struct
    mapping(address => mapping(uint => mapping(uint => Escrow))) public daiEscrow;

    // Staking Functions

    // Must approve this contract first with desired amount to stake
    function stake(uint amount) external payable {
        require(amount > 0, "Amount must be greater than zero");
        IERC20 Token = IERC20(tokenAddress);
        uint256 allowance = Token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Amount higher than allowance");
        Token.transferFrom(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
    }

    function unstake(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= ethBalance[msg.sender], "Insufficient stake");
        
        IERC20 Token = IERC20(tokenAddress);
        Mediation mediation = Mediation(mediationAddress);
        Appeal appeal = Appeal(appealAddress);

        // Check if Arbitrator
        if (mediation.isArbitrator(msg.sender) || mediation.isCooldownActive(msg.sender)) {
            uint arbitratorStakingRequirement = mediation.minStakingRequirement();
            require (ethBalance[msg.sender] - amount >= arbitratorStakingRequirement, "Amount would violate minstakingrequirement");
            Token.transfer(msg.sender, amount);
            ethBalance[msg.sender] -= amount;
            return;
        }

        // Check if Justice
        if (appeal.isJustice(msg.sender) || appeal.isCooldownActive(msg.sender)) {
            uint justiceStakingRequirement = appeal.minStakingRequirement();
            require (ethBalance[msg.sender] - amount >= justiceStakingRequirement, "Amount would violate minstakingrequirement");
            Token.transfer(msg.sender, amount);
            ethBalance[msg.sender] -= amount;
            return;
        }


        // Else (if cooldowns are not active AND not currently Arbitrator nor Justice)

        Token.transfer(msg.sender, amount);
        ethBalance[msg.sender] -= amount;
    }

    // Deposit/Withdraw Functions

    function withdrawEth (uint amount) external {
        require(amount <= ethBalance[msg.sender], "Insufficient Balance");
        bool sent = payable(msg.sender).send(amount);
        require(sent == true, "Transfer failed");
        ethBalance[msg.sender] -= amount;
    }

    function depositEth (address target) external payable {
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