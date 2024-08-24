// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Crowdfunding {
    address public owner; // Owner of the contract
    struct Campaign {
        string title;
        string description;
        address benefactor;
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
    }

    mapping(uint => Campaign) public campaigns;
    uint[] public campaingnsIds; // An arraay to save all campaignsIds

    event CampaignCreated(
        string _title,
        string _description,
        address _benefactor,
        uint256 _goal,
        uint _duration
    );

    event DonationReceived(uint _campainId, uint _amount);

    event CampaignEnded(
        Campaign selectedCampaign,
        uint amountSentToBenefactor,
        uint targetAmount
    );

    constructor() {
        // Set the owner to the account that deploys the contract
        owner = msg.sender;
    }
    //Function to createCampaign
    /**
     * @dev Creates a new campaign with specified details.
     * @param _title The title of the campaign.
     * @param _description The description of the campaign.
     * @param _benefactor The address of the benefactor who will receive the funds.
     * @param _goal The fundraising goal for the campaign in wei.
     * @param _duration The duration of the campaign in seconds.
     * @return Returns the newly created Campaign structure.
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        address _benefactor,
        uint256 _goal,
        uint _duration // In seconds
    ) public returns (Campaign memory) {
        require(_goal > 0, "Goal should be greater than zero.");
        Campaign memory newCampain = Campaign({
            title: _title,
            description: _description,
            benefactor: _benefactor,
            goal: _goal,
            deadline: block.timestamp + _duration, //Get the current time and add the deadline duration to it.
            amountRaised: 0
        });
        uint campaignlength = campaingnsIds.length; //Get the lenght of the campaign Ids to dynamically assign IDs to the campaign list.
        uint campaignId = campaignlength + 1; //Increament Campaign ID by 1
        campaigns[campaignId] = newCampain;
        emit CampaignCreated(
            _title,
            _description,
            _benefactor,
            _goal,
            _duration
        );
        return newCampain;
    }

    // Function to donateToCampain
    /**
     * @dev Allows users to donate to an active campaign by sending ETH.
     * @param _campaignId The ID of the campaign to which the donation is made.
     * @return Returns the updated Campaign structure after the donation is added.
     */
    function donate(uint _campaignId) public payable returns (Campaign memory) {
        Campaign storage selectedCampaign = campaigns[_campaignId];
        require(msg.value > 0, "Donation amount must be greater than zero");
        require(
            block.timestamp < selectedCampaign.deadline,
            "Campaign has already ended"
        );
        selectedCampaign.amountRaised += msg.value;
        emit DonationReceived(_campaignId, msg.value);
        return selectedCampaign;
    }

    //Fucntion to EndCampaign
    /**
     * @dev Ends a campaign after the deadline has passed and transfers the raised amount to the benefactor.
     * @param _campaignId The ID of the campaign to end.
     * @return Returns the ended Campaign structure.
     */
    function endCampaign(
        uint _campaignId
    ) public payable returns (Campaign memory) {
        Campaign storage selectedCampaign = campaigns[_campaignId];
        require(
            block.timestamp >= selectedCampaign.deadline,
            "Campaign is still ongoing"
        );
        require(
            selectedCampaign.amountRaised > 0,
            "Campaign already ended or no funds raised"
        );
        // Transfer the raised amount to the benefactor
        (bool success, ) = payable(selectedCampaign.benefactor).call{
            value: selectedCampaign.amountRaised
        }("");
        require(success, "Transfer to benefactor failed.");
        // Emit the event
        emit CampaignEnded(
            selectedCampaign,
            selectedCampaign.amountRaised,
            selectedCampaign.goal
        );
        // Reset the raised amount to avoid re-entrancy or multiple withdrawals
        selectedCampaign.amountRaised = 0;
        return selectedCampaign;
    }

    /**
     * @dev Allows the contract owner to withdraw any leftover funds in the contract.
     * Only the owner can call this function.
     */
    function withdrawLeftoverFunds() public payable onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        payable(owner).transfer(address(this).balance); //One way transfer to the owner of the contract.
    }

    /**
     * @dev Modifier to ensure only the owner of the contract can execute certain functions.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }
}
