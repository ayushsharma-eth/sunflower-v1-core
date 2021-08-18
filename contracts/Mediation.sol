pragma solidity >=0.8.6;

import "./interfaces/IERC20.sol";
import "./Appeal.sol";
import "./MarketFactory.sol";
import "./Bank.sol";

contract Mediation {

    address public appealAddress;
    address public tokenAddress;
    address public marketFactoryAddress;
    uint public minStakingRequirement;

    address public bankAddress;

    constructor(
        address _appealAddress,
        address _tokenAddress,
        address _marketFactoryAddress,
        uint _minStakingRequirement,
        address _bankAddress
    ) 
    {
        appealAddress = _appealAddress;
        tokenAddress = _tokenAddress;
        marketFactoryAddress = _marketFactoryAddress;
        minStakingRequirement = _minStakingRequirement;
        bankAddress = _bankAddress;
    }

    mapping(address => Arbitrator) public arbitrators;

    struct Arbitrator {
        bool isArbitrator;
        uint timer;
    }

    function join() external 
    {
        require(!arbitrators[msg.sender].isArbitrator, "Already Arbitrator");

        Appeal appeal = Appeal(appealAddress);
        require(!appeal.isJustice(msg.sender), "Cannot be Justice");
        require(!appeal.isCooldownActive(msg.sender), "Must wait until cooldown has passed");

        Bank bank = Bank(bankAddress);
        require(bank.stakedBalance(msg.sender) >= minStakingRequirement, "Insufficient stake");
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

    function fire (address addr) external {
        require(msg.sender == bankAddress, "Sunflower-V1/FORBIDDEN");
        arbitrators[addr].isArbitrator = false; // Can no longer be assigned new orders
    }

    function isArbitrator (address addr) external view returns (bool) {
        return arbitrators[addr].isArbitrator;
    }

    function isCooldownActive (address addr) external view returns (bool) {
        return block.timestamp >= arbitrators[addr].timer;
    }

}