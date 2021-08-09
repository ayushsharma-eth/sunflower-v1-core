pragma solidity >=0.8.6;

import "./interfaces/IERC20.sol";
import "./MarketFactory.sol";

contract Mediation {

    address public tokenAddress;
    address public marketFactoryAddress;
    uint public minStakingRequirement;

    mapping(address => Arbitrator) public arbitrators;

    struct Arbitrator {
        bool isArbitrator;
        uint escrowAmount;
        uint timer;
    }

    // Must approve this contract first with desired amount to stake
    function stake(address arbitrator, uint amount) external payable {
        require(amount > 0, "Amount must be greater than zero");
        IERC20 Token = IERC20(tokenAddress);
        uint256 allowance = Token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Amount higher than allowance");
        Token.transferFrom(msg.sender, address(this), amount);
        arbitrators[arbitrator].escrowAmount += amount;
    }

    function join() external 
    {
        require(!arbitrators[msg.sender].isArbitrator, "Already Arbitrator");
        require(arbitrators[msg.sender].escrowAmount >= minStakingRequirement, "Insufficient stake");

        arbitrators[msg.sender].isArbitrator = true;
    }


    function resetTimer(address arbitrator) external {
        MarketFactory MF = MarketFactory(marketFactoryAddress);
        require(MF.isMarket(msg.sender), "Sunflower-V1/FORBIDDEN");

        arbitrators[arbitrator].timer = block.timestamp * 14 * 24 * 3600;
    }

    function quit(address arbitrator) external {
        require(msg.sender == arbitrator, "Not specified Arbitrator");
        require(arbitrators[arbitrator].isArbitrator, "Not Arbitrator");

        arbitrators[arbitrator].isArbitrator = false; // Can no longer be assigned new orders
    }

    function unstake(uint amount, address arbitrator) external {
        require(amount > 0, "Amount must be greater than zero");
        require(msg.sender == arbitrator, "Not specified Arbitrator");
        require(amount <= arbitrators[arbitrator].escrowAmount, "Insufficient stake");
        
        IERC20 Token = IERC20(tokenAddress);

        if (arbitrators[arbitrator].escrowAmount - amount >= minStakingRequirement)
        {
            Token.transfer(msg.sender, amount);
            arbitrators[arbitrator].escrowAmount -= amount;
        }
        else
        {
            require(block.timestamp >= arbitrators[arbitrator].timer, "Cooldown still active");
            Token.transfer(msg.sender, amount);
            arbitrators[arbitrator].escrowAmount -= amount;
            if (arbitrators[arbitrator].isArbitrator) arbitrators[arbitrator].isArbitrator == false;
        }
    }
}