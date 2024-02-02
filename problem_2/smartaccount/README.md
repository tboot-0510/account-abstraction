# account-abstraction


### Smart contract addresses 
On Mumbai and Base Sepolia :
```
https://mumbai.polygonscan.com/address/0xA0D935C90EAB68f1CC791Ed463498EEA0d868303

https://base-sepolia.blockscout.com/address/0xA0D935C90EAB68f1CC791Ed463498EEA0d868303
```

### Biconomy module
Custom Validation Module : ```CustomValidationModule.sol``````
Idea behind ```_verifySignature(...)``` implementation: 

- We assume that the user is sending on transaction at the time using ```encodeExecute```from ```BiconomySmartAccountV2.ts```
- During ```buildUserOp```, the transaction ```to```, ```value``` and ```data``` is encoded using ```encodeExecute```
- Transaction calldata is formatted by a series of hex-bytes code : 
  - 4 first bytes : keccak256(functionSignature), i.e: ethers.id("execute_ncC(address,uint256,bytes)") => '0x0000189aa837583008638f6cac2ce6b55733abf2489048e3ebd2e2b11e6e2837'. 4 first bytes of callData transaction represents the 4 first bytes of the function signature.
  - Following 32 bytes : destination address of the transaction
  - Next 32 bytes : value of the transaction. 
  - Rest is the encoded data.
- First we extract the functionSignature from userOps.callData and compare it to keccak256(functionSignature)
- Retrieve the address of the user that signed the message.
- Decode the value attached to the call data and verify it doesn't succeeds the imposed limit.
- Verify that the last transaction stored for a user in the mapping minus the current block timestamp is less than 1 DAY.
- Update the last transaction time mapping and daily transaction counter passed the requirements.

#### Flow
- Smart contract account calls the validation module and calls ```initForSmartAccount(uint128 _limitValue, uint128 _transactionsLimit)```. This sets the desired values in storage.


