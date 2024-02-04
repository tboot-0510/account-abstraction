# account-abstraction


### Smart contract addresses 
On Mumbai and Base Sepolia :
```
https://mumbai.polygonscan.com/address/0xA0D935C90EAB68f1CC791Ed463498EEA0d868303

https://base-sepolia.blockscout.com/address/0xA0D935C90EAB68f1CC791Ed463498EEA0d868303
```

# Biconomy module

Created the module in: ```bcny-module/modules/TxLimiterModule```

According to this link : https://docs.biconomy.io/modules
There exists two types of modules: 
- validation modules: They define different signature schemes or authorization mechanisms to validate who is allowed to perform what action on the account, by implementing standard interfaces.
- Execution modules: These modules define custom execution functions to facilitate the actions allowed by the account.

The design of a module is twofold: 
1) Create a validation module that verifies the module signature and aborts if the user spends more ether or reaches the limit of transactions per day
   a) Following https://docs.biconomy.io/tutorials/customValidationModule
    - The smart contract should be initialized with the address of ```executionContract```
    - Implement the ```_verifySignature``` method according to the scheme.
      - The idea is to decode the module signature, to extract the transaction value, and to check it against a specific limit
        - If the value of the tx is above threshold, revert
        - Else continue
      - Then we check the storage of ```executionContract``` to see if it reached the threshold transaction limit
        - If yes revert
        - Else continue
2) Create an execution smart contract that updates the counter for each transaction and executes the associated transaction
   a) Following the diagram @Execution Modules
     - Implement the ```executeTransaction``` function from the ```ModuleManager.sol``` inherited by ```SmartAccount.sol```
     - The transaction is already validated in the previous step, so we only execute the ```execTransactionFromModule``` from ```SmartAccount.sol```
     - If it succeeds, we update the counter number for that address and the last timestamp of the transaction. 


## TO DO : 
- Module tests