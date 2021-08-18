//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.6;

import "./MarketFactory.sol";
import "./Bank.sol";

// Stores rating 
contract Rating {

    address public bankAddress;

    constructor
    (
        address _bankAddress
    ) 
    {
        bankAddress = _bankAddress;
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

    mapping(address => mapping(address => mapping(uint => Ticket))) public mayRate; // mayRate[reviewer][reviewee][ticketId] => Ticket struct
    mapping(address => mapping(address => uint)) public numOfTickets; //numOfTickets[reviewer][reviewee] => number of tickets **for given address pair**
    mapping(address => Ticket[]) public tickets; // All tickets for given address

    struct Ticket
    {
        bool eligible;
        uint8 typeOfReviewee;
        uint8 typeOfReviewer;
        address market;
        uint product;
        uint order;
    }

    function mayReview(address market, uint product, address merchant, address buyer, address arbitrator, uint order) external {
        require(msg.sender == bankAddress, "Sunflower-V1/FORBIDDEN");

        if(arbitrator != address(0))
        {
            Ticket memory ticket1 = Ticket(
                true,
                0, // Buyer
                2, // Arbitrator
                market,
                product,
                order
            );

            mayRate[arbitrator][buyer][numOfTickets[arbitrator][buyer]++] = ticket1;
            tickets[arbitrator].push(ticket1);

            Ticket memory ticket2 = Ticket(
                true,
                1, // Merchant
                2, // Arbitrator
                market,
                product,
                order
            );

            mayRate[arbitrator][merchant][numOfTickets[arbitrator][merchant]++] = ticket2;
            tickets[arbitrator].push(ticket2);

            Ticket memory ticket3 = Ticket(
                true,
                2, // Arbitrator
                0, // Buyer
                market,
                product,
                order
            );

            mayRate[buyer][arbitrator][numOfTickets[buyer][arbitrator]++] = ticket3;
            tickets[buyer].push(ticket3);

            Ticket memory ticket4 = Ticket(
                true,
                2, // Arbitrator
                1, // Merchant
                market,
                product,
                order
            );

            mayRate[merchant][arbitrator][numOfTickets[merchant][arbitrator]++] = ticket4;
            tickets[merchant].push(ticket4);
        }

        // Buyer & Merchant

        Ticket memory ticket5 = Ticket(
            true,
            1, // Merchant
            0, // Buyer
            market,
            product,
            order
        );

        mayRate[buyer][merchant][numOfTickets[buyer][merchant]++] = ticket5;
        tickets[buyer].push(ticket5);

        Ticket memory ticket6 = Ticket(
            true,
            0, // Buyer
            1, // Merchant
            market,
            product,
            order
        );

        mayRate[merchant][buyer][numOfTickets[merchant][buyer]++] = ticket6;
        tickets[merchant].push(ticket6);
    }

    function review(address reviewee, address reviewer, uint8 rating, uint ticketId, bytes32 message) external
    {
        require(mayRate[reviewer][reviewee][ticketId].eligible, "Ineligible");
        require(msg.sender == reviewer, "Not Reviewer");

        Review memory _review = Review(
            mayRate[reviewer][reviewee][ticketId].typeOfReviewer,
            reviewer,
            mayRate[reviewer][reviewee][ticketId].market,
            mayRate[reviewer][reviewee][ticketId].product,
            rating, // Likert Scale 1-5
            message // Shortened link to signed message hosted offchain, like a forum
        );

        if (mayRate[reviewer][reviewee][ticketId].typeOfReviewee == 0) // Would prefer switch but DNE
        {
            buyerRatings[reviewee].push(_review);
            delete mayRate[reviewer][reviewee][ticketId];
        }
        else if (mayRate[reviewer][reviewee][ticketId].typeOfReviewee == 1)
        {
            merchantRatings[reviewee].push(_review);
            delete mayRate[reviewer][reviewee][ticketId];
        }
        else
        {
            arbitratorRatings[reviewee].push(_review);
            delete mayRate[reviewer][reviewee][ticketId];
        }
    }

}