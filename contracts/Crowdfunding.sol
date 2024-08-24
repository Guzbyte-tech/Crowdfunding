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

    /**
     * @notice Creates a new fundraising campaign.
     * @dev The campaign's deadline is calculated by adding the current block timestamp to the duration (in seconds).
     * @param _title The title of the campaign.
     * @param _description A brief description of the campaign.
     * @param _benefactor The address of the benefactor who will receive the funds raised.
     * @param _goal The target amount (in wei) that the campaign aims to raise.
     * @param _duration The duration of the campaign in seconds, after which the campaign will end.
     * @return The newly created campaign details (as a Campaign struct).
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

    /**
     * @notice Donates amount in wei to the benefactor of the campaign.
     * @dev The campaign's deadline is calculated by adding the current block timestamp to the duration (in seconds).
     * @param _campaignId The ID of the campaign.
     * @return The selected campaign details (as a Campaign struct).
     */
    function donate(uint _campaignId) public payable returns (Campaign memory) {
        Campaign storage selectedCampaign = campaigns[_campaignId];
        require(msg.value > 0, "Donation amount must be greater than zero");
        require(
            block.timestamp < selectedCampaign.deadline,
            "Campaign has already ended"
        );
        (bool success, ) = payable(selectedCampaign.benefactor).call{
            value: msg.value
        }("");
        require(success, "Donation failed.");
        selectedCampaign.amountRaised += msg.value;
        emit DonationReceived(_campaignId, msg.value);
        return selectedCampaign;
    }

    /**
     * @notice Ends the campaign.
     * @dev This function ends a selected campaign and transfer all funds to the benefactor.
     * @param _campaignId The ID of the campaign.
     * @return The selected campaign details (as a Campaign struct).
     */
    function endCampaign(
        uint _campaignId
    ) public payable returns (Campaign memory) {
        Campaign memory selectedCampaign = campaigns[_campaignId];
        require(
            block.timestamp >= selectedCampaign.deadline,
            "Campaign is still ongoing"
        );
        (bool success, ) = payable(selectedCampaign.benefactor).call{
            value: selectedCampaign.amountRaised
        }("");
        require(success, "Transfer to benefactor failed.");
        emit CampaignEnded(
            selectedCampaign,
            selectedCampaign.amountRaised,
            selectedCampaign.goal
        );
        return selectedCampaign;
    }

    /**
     * @notice Withdraw leftover funds in the campaign.
     * @dev Function to allow the owner to withdraw leftover funds.
     */
    function withdrawLeftoverFunds() public payable onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        payable(owner).transfer(address(this).balance); //One way transfer to the owner of the contract.
    }

    // Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }
}
