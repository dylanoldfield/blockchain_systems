// SPDX-License-Identifier: UNLICENSED
 pragma solidity ^0.8.0;
 /// @title Contract to agree on the lunch venue
 contract LunchVenue{
     
     struct Friend { 
         string name;
         bool voted; 
         
     }
     
     struct Vote {
        uint venue;
        address voterAddress; 
        
     }
     

    /// @dev - Soldity blocks variables into 256bit blocks
    
    uint public numVenues; // default uint value is 0 - saves gas
    uint public numFriends;// default uint value is 0 - saves gas
    uint public numVotes; // default uint value is 0 - saves gas
    uint private timeOut = 100; // number of blocks to timeout after  
    uint private startBlock; // block number at contract creation
    uint private endBlock; //ending block
    
    address public manager; //Manager of lunch venues
    string public votedVenue = ""; //Where to have lunch
    mapping (uint => string) public venues;//List of venues (venue no, name) 
    mapping(address => Friend) public friends; //List of friends (address, Friend)
    mapping (uint => Vote) private votes; //List of votes (vote no, Vote)
    mapping (uint => uint) private results; //List of vote counts (venue no, no of votes)
    
    bool public voteOpen; //voting is closed, voteOpen= false, saves gas not initialising to default
    bool public cancelled; // cancelled = false, saves gas not initialising to default
     
     // Creates a new lunch venue contract
    constructor () {
        manager = msg.sender; //Set contract creator as manager 
        startBlock = block.number;
        endBlock = startBlock + timeOut;
        
    }
 
    /// @notice Add a new lunch venue
    /// @param name Name of the venue
    /// @return Number of lunch venues added so far
    function addVenue(string memory name) public restricted votingClosed notCancelled returns (uint){
        numVenues ++; 
        venues[numVenues] = name;
        return numVenues; 
    }
    
    /// @notice Add a new friend who can vote on lunch venue
    /// @param friendAddress Friend’s account address
    /// @dev require statement added to optimise gas cost for failed tx
    /// @param name Friend’s name
    /// @return Number of friends added so far
    function addFriend(address friendAddress, string memory name) public restricted votingClosed notCancelled returns (uint){
        Friend memory f; 
        f.name = name;
        f.voted = false; 
        require(bytes(friends[friendAddress].name).length == 0, 'friend already added.');
        friends[friendAddress] = f;
        numFriends ++;
        return numFriends; 
    }
    
    
    /// @notice function for manager to open voting once all venues and friends added 
    function openVoting() public votingClosed restricted notCancelled returns (bool){
        voteOpen = true;   
        return voteOpen; 
    }
    
    
    /// @notice added if statement to check if the friend has already voted
    /// @dev added revert statements to optimise gas spending on failed txs
    function doVote(uint venue) public votingOpen notCancelled returns (bool validVote){ 
     
        require(bytes(friends[msg.sender].name).length != 0 , "friend does not exist."); //Does friend exist? 
        require(friends[msg.sender].voted == false, "friend has already voted."); // Has the friend voted? 
        require(bytes(venues[venue]).length != 0, "venue does not exist.");  //Does venue exist?
    
        validVote = true;
        friends[msg.sender].voted = true; 
        Vote memory v;
        v.voterAddress = msg.sender; 
        v.venue = venue;
        numVotes ++; 
        votes[numVotes] = v;
 
        if (numVotes >= numFriends/2 + 1) { //Quorum is met
            finalResult(); 
        }
        return validVote; 
    }

    /// @notice Determine winner venue
    /// @dev If top 2 venues have the same no of votes, final result depends on vote order
    function finalResult() private{ 
        uint highestVotes = 0;
        uint highestVenue = 0;
        for (uint i = 1; i <= numVotes; i++){   //For each vote 
            uint voteCount = 1;
            if(results[votes[i].venue] > 0) { // Already start counting 
                voteCount += results[votes[i].venue];
             }
            results[votes[i].venue] = voteCount;
            if (voteCount > highestVotes){ // New winner
                highestVotes = voteCount; 
                highestVenue = votes[i].venue;
            } 
        }
        votedVenue = venues[highestVenue]; //Chosen lunch venue 
        voteOpen = false; //Voting is now closed
        cancelled = true; // Contract is now closed
    }
    
    /// @notice Determine if the contract has been cancelled/timed out - this function is run whenever a transcation occurs unless contract already cancelled
    /// @dev will cancel automatically if timed out
    function contractTimedOut()  private returns (bool){ 
        if (block.number >= endBlock){
            finalResult();
        }
            
        return cancelled;
    }
    
    /// @notice Cancel the contract and determine the winner
    function managerCancel() public restricted notCancelled returns (bool){ 
        finalResult();
        cancelled = true;
        return cancelled;
    }

    
    /// @notice Only manager can do
    modifier restricted() {
        require (msg.sender == manager, "Can only be executed by the manager");
        _;
    }
    
    /// @notice Only when voting is still open
    modifier votingOpen() {
        require(voteOpen == true, "Can vote only while voting is open.");
        _;
    } 
    
    /// @notice Only when voting is still closed
    modifier votingClosed() {
        require(voteOpen == false, "Can only do this action when voting is closed.");
        _;
    }
    
    /// @notice Will check if the contract has timed out or been cancelled
    /// @dev the reason I have the intial require statment is to revert the transaction immediately if the contract is already cancelled...
    /// otherwise it will check if the contract has timed out and cost extra gas.
    modifier notCancelled() {
        require(cancelled == false, "Contract has timed out/cancelled.");
        require(contractTimedOut() == false, "Contract has timed out/cancelled.");
        _;
    } 
 }
