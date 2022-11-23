//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.9.0; 
// ---------------------------------------------------------------------------- // EIP-20: ERC-20 Token Standard // https://eips.ethereum.org/EIPS/eip-20 // -----------------------------------------

contract Crowdfunding{
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public target;
    uint public deadline;
    uint public raisedAmount;
    uint public noOFContributors;

    constructor(uint _target, uint _deadline){
        target = _target;
        deadline = block.timestamp + _deadline;
        minimumContribution = 1 ether;
        manager = msg.sender;
    }

    struct Request{
        string description;
        address payable recipants;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public numRequests;

    function sendEth() public payable{
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minimumContribution, "Minimum Contribution is not met");

        if(contributors[msg.sender] == 0){
            noOFContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp > deadline && raisedAmount < target, "You Are Eligible For Refund");
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }
     
     modifier onlyManager(){
         require(msg.sender == manager);
         _;
    }

    function createRequest(string memory _description, address payable _recipants, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipants = _recipants;
        newRequest.value = _value;
        newRequest.noOfVoters = 0;
        newRequest.completed = false;
    }

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender] > 0, "You Must Contribute To Vote");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false, "You Have Voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount >= target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "The request has completed");
        require(thisRequest.noOfVoters > (noOFContributors/2));
        thisRequest.recipants.transfer(thisRequest.value);
    }


}