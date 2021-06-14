pragma solidity >=0.8.00 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../contracts/LunchVenue_updated.sol";
import "https://github.com/GNSPS/solidity-bytes-utils/blob/5d251ad816e804d55ac39fa146b4622f55708579/contracts/BytesLib.sol";


// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
/// Inherit 'LunchVenue' contract
contract LunchVenueTest is LunchVenue {
    using BytesLib for bytes;
    
    // Variables used to emulate different accounts
    address acc0; 
    address acc1;
    address acc2; 
    address acc3;
    address acc4;
    
    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // Initiate account variables
        acc0 = TestsAccounts.getAccount(0); 
        acc1 = TestsAccounts.getAccount(1); 
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }
    
    /// Account at zero index (account-0) is default account, so manager will be set to acc0
    function managerTest() public {
        Assert.equal(manager, acc0, 'Manager should be acc0');
    }
    
    /// Add lunch venue as manager
    /// When msg.sender isn't specified , default account (i.e., account -0) is considered as the sender
    function setLunchVenue() public {
        Assert.equal(addVenue('Courtyard Cafe'), 1, 'Should be equal to 1'); 
        Assert.equal(addVenue('Uni Cafe'), 2, 'Should be equal to 2');
    }
    
    /// Try to add lunch venue as a user other than manager. This should fail
    /// #sender: account-1
    function setLunchVenueFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addVenue(string)", "Atomic Cafe"));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        }else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }
    
    /// Set friends as account-0
    /// #sender doesn't need to be specified explicitly for account-0
    function setFriend() public {
        Assert.equal(addFriend(acc0, 'Alice'), 1, 'Should be equal to 1');
        Assert.equal(addFriend(acc1, 'Bob'), 2, 'Should be equal to 2'); 
        Assert.equal(addFriend(acc2, 'Charlie'), 3, 'Should be equal to 3');
        Assert.equal(addFriend(acc3, 'Eve'), 4, 'Should be equal to 4');
    }
    
    /// Test if friend already added
    function setFriendAlreadyExistFailure() public {
        Assert.equal(addFriend(acc0, 'Alice'), 4, 'number of friends should not change');
    }  
    
    /// Try adding friend as a user other than manager. This should fail 
    /// #sender: account-1
    function setFriendNonManagerFailure() public {
        (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("addFriend(address,string)", acc4, 'Daniels'));
        if (success == false) {
            string memory reason = abi.decode(result.slice(4, result.length - 4), (string));
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        }else {
            Assert.ok(false, 'Method Execution should fail');
        }
    }
    
    /// Try to vote while voting is closed 
    function voteWhileNotOpen() public {
        try this.doVote(2) returns (bool f) { 
            Assert.ok(false, 'Method execution should fail');
        } 
        catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Can vote only while voting is open.', 'Failed with unexpected reason');
        } 
        catch (bytes memory /*lowLevelData*/) { 
            Assert.ok(false, 'Failed unexpected');
        } 
    }
    
    /// Open Voting
    function OpenVoting() public {
        Assert.ok(openVoting(), "Voting is open");
    }

    /// Vote as Bob (acc1)
    /// #sender: account-1
    function vote() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }
    
    /// Vote as Bob (acc1) AGAIN
    /// #sender: account-1
    function voteAgain() public {
        Assert.equal(doVote(1), false, "Voting result should be false");
    }
    /// Vote as Charlie 
    /// #sender: account-2
    function vote2() public {
        Assert.ok(doVote(1), "Voting result should be true");
    }
    /// Try voting as a user not in the friends list. This should fail 
    /// #sender: account-4
    function voteFailure() public {
        Assert.equal(doVote(1), false, "Voting result should be false");
    }
    /// Vote as Eve
    /// #sender: account-3
    function vote3() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }

    /// Verify lunch venue is set correctly
    function lunchVenueTest() public {
        Assert.equal(votedVenue, 'Uni Cafe', 'Selected venue should be Uni Cafe'); 
    }
    /// Verify voting is now closed
    function voteClosed() public {
        Assert.equal(voteOpen, false, 'Voting should be closed');
    }
    /// Verify voting after vote closed. This should fail 
    /// #sender: account-2
    function voteAfterClosedFailure() public {
        try this.doVote(1) returns (bool validVote) {
            Assert.ok(false, 'Method Execution Should Fail'); 
        } 
        catch Error(string memory reason) {
            // Compare failure reason, check if it is as expected
            Assert.equal(reason, 'Can vote only while voting is open.', 'Failed with unexpected reason');
        } 
        catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpectedly'); 
        }
    } 
}