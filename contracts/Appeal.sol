//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.6;

import "./interfaces/IERC20.sol";
import "./Mediation.sol";
import "./Bank.sol";

contract Appeal {
    
    address public mediationAddress;
    address public tokenAddress;
    uint public minStakingRequirement; //5% of protocol (Real value TBD)
    address bankAddress;

    constructor(
        address _mediationAddress,
        address _tokenAddress,
        uint _minStakingRequirement,
        address _bankAddress
    )
    {
        mediationAddress = _mediationAddress;
        tokenAddress = _tokenAddress;
        minStakingRequirement = _minStakingRequirement;
        bankAddress = _bankAddress;
    }

    struct Justice {
        bool isJustice;
        uint timer;
    }

    mapping(address => Justice) justices;

    function join() external { //become Justice (locks tokens for minTime)
        require(!justices[msg.sender].isJustice, "Already Justice");

        Mediation mediation = Mediation(mediationAddress);
        require(!mediation.isArbitrator(msg.sender), "Cannot be Arbitrator");
        require(!mediation.isCooldownActive(msg.sender), "Must wait until cooldown has passed");

        Bank bank = Bank(bankAddress);
        require(bank.stakedBalance(msg.sender) >= minStakingRequirement, "Insufficient stake");
        justices[msg.sender].isJustice = true;
    }

    function quit() external {
        require(justices[msg.sender].isJustice, "Not Justice");
        justices[msg.sender].isJustice = false;
    }

    function fire(address justice) external {
        require(msg.sender == bankAddress, "Sunflower-V1/FORBIDDEN");
        justices[justice].isJustice = false;
    }

    function isJustice(address addr) external view returns (bool) {
        return justices[addr].isJustice;
    }

    function isCooldownActive (address addr) external view returns (bool) {
        return block.timestamp < justices[addr].timer;
    }
}