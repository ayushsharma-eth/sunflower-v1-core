pragma solidity >=0.8.6;

import "./interfaces/IERC20.sol";

contract Appeal {
    
    address public tokenAddress;
    uint public minStakingAmount; //5% of protocol (Real value TBD)

    constructor(
        address _tokenAddress,
        uint _minStakingAmount
    ) {
        tokenAddress = _tokenAddress;
        minStakingAmount = _minStakingAmount;
    }

    struct Justice {
        bool isJustice;
        uint escrowAmount;
        uint timer;
    }

    mapping(address => Justice) justices;

    // Must approve this contract first with desired amount to stake
    function stake(address justice, uint amount) external payable {
        require(amount > 0, "Amount must be greater than zero");
        IERC20 Token = IERC20(tokenAddress);
        uint256 allowance = Token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Amount higher than allowance");
        Token.transferFrom(msg.sender, address(this), amount);
        justices[justice].escrowAmount += amount;
    }

    function unstake(uint amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= justices[msg.sender].escrowAmount, "Insufficient stake");
        
        IERC20 Token = IERC20(tokenAddress);

        if (justices[msg.sender].escrowAmount - amount >= minStakingAmount)
        {
            Token.transfer(msg.sender, amount);
            justices[msg.sender].escrowAmount -= amount;
        }
        else
        {
            require(block.timestamp >= justices[msg.sender].timer, "Cooldown still active");
            Token.transfer(msg.sender, amount);
            justices[msg.sender].escrowAmount -= amount;
            if (justices[msg.sender].isJustice) justices[msg.sender].isJustice == false;
        }
    }

    function join() external { //become Justice (locks tokens for minTime)
        require(!justices[msg.sender].isJustice, "Already Justice");
        require(justices[msg.sender].escrowAmount >= minStakingAmount, "Insufficient stake");
        justices[msg.sender].isJustice = true;
    }

    function quit() external {
        require(justices[msg.sender].isJustice, "Not Justice");
        justices[msg.sender].isJustice = false;
    }
}