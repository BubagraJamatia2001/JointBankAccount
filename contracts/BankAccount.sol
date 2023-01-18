//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <=0.8.17;

contract BankAccount {
    event Deposit(
        address indexed user,
        uint256 indexed accountId,
        uint256 value,
        uint256 timestamp
    );
    event WithdrawRequested(
        address indexed user,
        uint256 indexed accountId,
        uint256 indexed withdrawId,
        uint256 amount,
        uint256 timestamp
    );
    event Withdraw(uint256 indexed withdrawId, uint256 timestamp);
    event AccountCreated(
        address[] owners,
        uint256 indexed id,
        uint256 timestamp
    );

    struct WithdrawRequest {
        address user;
        uint256 amount;
        uint256 approvals;
        mapping(address => bool) ownersApproved;
        bool approved;
    }

    struct Account {
        address[] owners;
        uint256 balance;
        mapping(uint256 => WithdrawRequest) withdrawRequests;
    }

    mapping(uint256 => Account) accounts;
    mapping(address => uint256[]) userAccount;

    uint256 nextAccountId;
    uint256 nextWithdrawId;

    modifier accountOwner(uint256 accountId) {
        // Checks if the current user is one of the owner of the Account with the given accountId
        bool isOwner = false;
        for (uint256 idx; idx < accounts[accountId].owners.length; idx++) {
            if (accounts[accountId].owners[idx] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "You are not an owner of this account");
        _;
    }

    modifier validOwner(address[] calldata owners) {
        // Checks if the number of owners exceeds the limit of owners that an Account can hold i.e 4
        //(including the one who created the account)
        //Also checks for duplicates among the list of owners
        require(owners.length + 1 <= 4, "Maximum of 4 owners per account");
        for (uint256 i; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                revert("Current User already present in the same owners array");
            }
            for (uint256 j = i + 1; j < owners.length; j++) {
                if (owners[i] == owners[j]) {
                    revert("No Duplicate Owners");
                }
            }
        }
        _;
    }

    modifier sufficientBalance(uint256 accountId, uint256 amount) {
        //Checks if the Account has sufficient balance to withdraw funds
        require(accounts[accountId].balance >= amount, "Insufficient Balance");
        _;
    }

    modifier canApprove(uint256 accountId, uint256 withdrawId) {
        //Checks if the current withdraw request can be approved
        require(
            !accounts[accountId].withdrawRequests[withdrawId].approved,
            "This request is already approved"
        );
        require(
            accounts[accountId].withdrawRequests[withdrawId].user != msg.sender,
            "The current user initiated the withdraw request and hence, is not allowed to approve"
        );
        require(
            accounts[accountId].withdrawRequests[withdrawId].user != address(0),
            "The request doesn't exist"
        );
        require(
            !accounts[accountId].withdrawRequests[withdrawId].ownersApproved[
                msg.sender
            ],
            "The current user have already approved this request"
        );
        _;
    }

    modifier canWithdraw(uint256 accountId, uint256 withdrawId) {
        // Checks if the use is allowed to withdraw funds 
        require(
            accounts[accountId].withdrawRequests[withdrawId].user == msg.sender,
            "The current user is not the owner of this request or this request has been completed"
        );
        require(
            accounts[accountId].withdrawRequests[withdrawId].approved,
            "This request is not approved or has been completed"
        );
        _;
    }

    function deposit(uint256 accountId)
        external
        payable
        accountOwner(accountId)
    { //Allows the user to deposit funds to an account upon verification
        accounts[accountId].balance += msg.value;
    }

    function createAccount(address[] calldata otherOwners)
        external
        validOwner(otherOwners)
    {   //Allows the user to create an Account with/without other owners
        address[] memory owners = new address[](otherOwners.length + 1);
        owners[otherOwners.length] = msg.sender;

        uint256 id = nextAccountId;

        for (uint256 idx; idx < owners.length; idx++) {
            if (idx < owners.length - 1) {
                owners[idx] = otherOwners[idx];
            }

            if (userAccount[owners[idx]].length > 2) {
                revert("Each user can have a maximum of 3 accounts");
            }

            userAccount[owners[idx]].push(id);
        }

        accounts[id].owners = owners;
        nextAccountId++;
        emit AccountCreated(owners, id, block.timestamp);
    }

    function requestWithdrawl(uint256 accountId, uint256 amount)
        external
        accountOwner(accountId)
        sufficientBalance(accountId, amount)
    {
        // Initiates Withdraw Request ticket to be approved later
        uint256 id = nextWithdrawId;
        WithdrawRequest storage request = accounts[accountId].withdrawRequests[
            id
        ];
        request.user = msg.sender;
        request.amount = amount;
        nextWithdrawId++;
        emit WithdrawRequested(
            msg.sender,
            accountId,
            id,
            amount,
            block.timestamp
        );
    }

    function approveWithdrawl(uint256 accountId, uint256 withdrawId)
        external
        accountOwner(accountId)
        canApprove(accountId, withdrawId)
    {   //Allows the owner of an account to approve the withdraw request 
        //provided the owner is not the creator of the withdraw request
        WithdrawRequest storage request = accounts[accountId].withdrawRequests[
            withdrawId
        ];
        request.approvals++;
        request.ownersApproved[msg.sender] = true;

        if (request.approvals == accounts[accountId].owners.length - 1) {
            request.approved = true;
        }
    }

    function withdraw(uint256 accountId, uint256 withdrawId)
        external
        canWithdraw(accountId, withdrawId)
    {   // Allows the creator of the withdraw request to withdraw funds from the account
        uint256 amount = accounts[accountId]
            .withdrawRequests[withdrawId]
            .amount;
        require(accounts[accountId].balance >= amount, "Insufficient Balance");

        accounts[accountId].balance -= amount;
        delete accounts[accountId].withdrawRequests[withdrawId];

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent);

        emit Withdraw(withdrawId, block.timestamp);
    }

    function getBalance(uint256 accountId) public view returns (uint256) {
        //Shows the balance of the account
        return accounts[accountId].balance;
    }

    function getOwners(uint256 accountId)
        public
        view
        returns (address[] memory)
    {   //Provides a list of the owner(s) address belonging to an account
        return accounts[accountId].owners;
    }

    function getApprovals(uint256 accountId, uint256 withdrawId)
        public
        view
        returns (uint256)
    {   //Shows the count of approvals given to a withddraw request
        return accounts[accountId].withdrawRequests[withdrawId].approvals;
    }

    function getAccounts() public view returns (uint256[] memory) {
        //Provides the accountID of the accounts the user have with them
        return userAccount[msg.sender];
    }
}
