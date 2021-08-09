pragma solidity >=0.8.6;

import "./MarketFactory.sol";
import "./Rating.sol";
import "./Appeal.sol";
import "./Mediation.sol";
import "./Sun.sol"; 

contract Deployer {

    bool public deployed;

    constructor() {
        deployed = false;
    }

    struct Addresses {
        address token;
        address marketFactory;
        address rating;
        address mediation;
        address appeal;
    }

    Addresses public addresses;

    function deploy(uint totalSupply, uint arbitratorStake, uint justiceStake) external {
        require(!deployed, "Already deployed");
        
        // Deploy Governance Token
        ERC20Basic Sun = new ERC20Basic(totalSupply);

        // Deploy Market Factory
        MarketFactory MF = new MarketFactory();
        
        // Deploy Rating
        Rating rating = new Rating(address(MF));
        MF.updateRatingAddress(address(rating));

        // Deploy Mediation
        Mediation mediation = new Mediation(address(Sun), address(MF), arbitratorStake);

        // Deploy Appeal
        Appeal appeal = new Appeal(address(Sun), justiceStake);

        Addresses memory _addresses = Addresses(
            address(Sun),
            address(MF),
            address(rating),
            address(mediation),
            address(appeal)
        );

        addresses = _addresses;

        deployed = true;
    }
}