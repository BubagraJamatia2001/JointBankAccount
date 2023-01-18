# Joint Bank Account with Multiple Approvals

This project was made with the help of BlockchainExpert course from Algoexpert taught by Tim Ruscica. 

- This project offers a smart contract for creating joint bank account. Each Account can have a maximum of 4 owners and each owner can have a maximum of 3 accounts in this bank. 
- Each owner can deposit any amount of funds in their account.
- For withdrawal of funds, the account owners, other than the creator of the request, must approve the withdrawal request for the creator to withdraw funds.
- The project is accompanied by automated test cases and a minimal front-end application for interacting with some contract functionalities.

## Getting Started
To test and deploy the smart contract, follow the steps as given below:
1. Install [Node.js](https://nodejs.org/en/download/)
2. Clone the repository: ``
3. `cd JointBankAccount`
4. `npm install`
5. Testing the contract, run `npx hardhat test`
6. Contract Deployment to your `localhost` network
    - `npx hardhat node `
    - `npx hardhat run --network localhost .\scripts\deploy.js`
Run the above two commands in separate terminals

## FrontEnd
1. Install the [Liveserver Extension](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer) in VSCode
2. Open [base.html](frontend/base.html)
3. Start the liveserver by clickin "Go Live" button in the bottom right hand corner of your VSCode
4. Import any accounts as required into the MataMask and change your metamask network to "Hardhat"
5. Interact with the contract

## Following Functionalities to add
- [x] createAccount
- [ ] requestWithdrawl
- [ ] deposit
- [x] getAccounts
- [ ] getApprovals
- [ ] getBalance
- [ ] getOwners
- [ ] approveWithdrawl
- [ ] withdraw

