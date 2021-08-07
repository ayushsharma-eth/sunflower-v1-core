pragma solidity >=0.8.6;

import "./MarketFactory.sol";

contract Mediation {

    address public marketFactoryAddress;
    uint public minStakingRequirement;

    mapping(address => Arbitrator) public arbitrators;

    struct Arbitrator {
        bool isArbitrator;
        uint escrowAmount;
        uint timer;
    }

    function stake(address arbitrator) external payable {
        // Handle gov erc 20 tx
        uint amount = 0; // <<<
        arbitrators[arbitrator].escrowAmount += amount;
    }

    function hire() external 
    {
        require(!arbitrators[msg.sender].isArbitrator, "Already Arbitrator");
        require(arbitrators[msg.sender].escrowAmount >= minStakingRequirement, "Insufficient stake");
        
        Arbitrator memory arbitrator = Arbitrator(
            true,
            4,
            block.timestamp + 14 * 24 * 3600
        );

        arbitrators[msg.sender] = arbitrator;
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
        require(msg.sender == arbitrator, "Not specified Arbitrator");
        require(arbitrators[arbitrator].isArbitrator, "Not Arbitrator");
        require(amount <= arbitrators[arbitrator].escrowAmount, "Insufficient stake");

        if (arbitrators[arbitrator].escrowAmount - amount >= minStakingRequirement)
        {
            // Transfer gov tokens to Arbitrator address
            arbitrators[arbitrator].escrowAmount -= amount;
        }
        else
        {
            require(block.timestamp >= arbitrators[arbitrator].timer, "Cooldown still active");
            // Transfer gov tokens to Arbitrator address
            arbitrators[arbitrator].escrowAmount -= amount;
            if (arbitrators[arbitrator].isArbitrator) arbitrators[arbitrator].isArbitrator == false;
        }
    }

}