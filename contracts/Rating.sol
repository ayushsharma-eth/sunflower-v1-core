//SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./MarketFactory.sol";

// Stores rating 
contract Rating {

    address public marketFactoryAddress;

    constructor
    (
        address _marketFactoryAddress
    ) {
        marketFactoryAddress = _marketFactoryAddress;
    }

    struct Review {
        uint8 typeOfReviewer; // 0: Buyer, 1: Merchant, 2: Arbitrator
        address reviewer;
        address market;
        uint product;
        uint8 rating; // Likert Scale 1-5
        bytes32 message; // Shortened link to signed message hosted offchain, like a forum
    }

    mapping(address => Review[]) public buyerRatings; // Mapping Buyer address to structure
    mapping(address => Review[]) public merchantRatings; // Mapping Merchant address to structure
    mapping(address => Review[]) public arbitratorRatings; // Mapping Arbitrator address to structure

    mapping(address => mapping(address => Ticket)) mayRate; // Can an address rate another address and who is who

    struct Ticket
    {
        bool eligible;
        uint8 typeOfReviewee;
        uint8 typeOfReviewer;
        address market;
        uint product;
    }

    function mayReview(address market, uint product, address merchant, address buyer, address arbitrator) external {
        require(msg.sender == market, "Sunflower-V1/FORBIDDEN");
        MarketFactory MF = MarketFactory(marketFactoryAddress);
        require(MF.isMarket(market), "Sunflower-V1/FORBIDDEN");

        if(arbitrator)
        {
            Ticket memory ticket1 = Ticket(
                true,
                0, // Buyer
                2, // Arbitrator
                market,
                product
            );

            mayRate[arbitrator][buyer] = ticket1;

            Ticket memory ticket2 = Ticket(
                true,
                1, // Merchant
                2, // Arbitrator
                market,
                product
            );

            mayRate[arbitrator][merchant] = ticket2;

            Ticket memory ticket3 = Ticket(
                true,
                2, // Arbitrator
                0, // Buyer
                market,
                product
            );

            mayRate[buyer][arbitrator] = ticket3;

            Ticket memory ticket4 = Ticket(
                true,
                2, // Arbitrator
                1, // Merchant
                market,
                product
            );

            mayRate[buyer][arbitrator] = ticket4;
        }

        // Buyer can rate Merchant

        Ticket memory ticket5 = Ticket(
            true,
            1, // Merchant
            0, // Buyer
            market,
            product
        );

        mayRate[buyer][merchant] = ticket5;

        Ticket memory ticket6 = Ticket(
            true,
            0, // Buyer
            1, // Merchant
            market,
            product
        );

        mayRate[merchant][buyer] = ticket6;
    }

    function _review(address reviwee, address reviewer, uint8 rating, bytes32 message) external
    {
        require(mayRate[reviewer][reviwee].eligible, "Ineligible");
        
        Review memory review = Review(
            mayRate[reviewer][reviee].typeOfReviewer,
            reviewer,
            mayRate[reviewer][reviee].market,
            mayRate[reviewer][reviee].product,
            rating, // Likert Scale 1-5
            message // Shortened link to signed message hosted offchain, like a forum
        );

        if (mayRate[reviewer][reviwee].typeOfReviewee == 0) // Would prefer switch but DNE
        {
            buyerRatings[reviwee].push(review);
        }
        else if (mayRate[reviewer][reviwee].typeOfReviewee == 1)
        {
            merchantRatings[reviwee].push(review);
        }
        else
        {
            arbitratorRatings[reviwee].push(review);
        }
    }

}