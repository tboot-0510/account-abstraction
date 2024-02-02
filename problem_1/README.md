## Vulnerable code

### Vulnerabilities
- Reentrancy attack 
- Pragma solidity version missing
  - If version < 0.8, operations could lead to overflow/underflow
  - If version >= 0.8, no problem
- ```transferOwnership(address newOwner)``` has no verification on address(0)

### Explanation of different attacks
- Reentrancy attack :
``` 
function withdraw(uint256 amount) public { 
    require(balances[msg.sender] >= amount, "Insufficient balance");
    (bool success, ) = msg.sender.call{value: amount}(""); 
    require(success, "Transfer failed"); 
    balances[msg.sender] -= amount;
}
```
A reentrancy attack occurs when a contract calls another contract before it resolves its state. This happens when a function is externally invoked during its execution. 
```(bool success, ) = msg.sender.call{value: amount}(""); ``` allowing it to be run multiple times in a single transaction. For example, a malicious contract (contract B) that calls ```withdraw()``` on contract A will have a ```fallback() external payable``` method that could read the state balance of contract A, as the balance is updated after the succesful call, it's state balance never changes in the fallback, so contract B can run multiple transaction in a single one and drain the ```address(contractA).balance```.

- Overflow/Underflow :
  Before Solidity 0.8, SafeMath operations where required to prevent operations to exceed their designated declared type. For example, uint8 uses 8 bytes and stores values from 0 to 255. If any operation leads the value to become 256 or -1, then it leads to an over/under flow.

- ```transferOwnership(address newOwner)```:
  If the newOwner is set to address(0) then the contract will loose it's ownership feature.
  However here, no functions are safeguarded with the onlyOwner modifier, so there are no major implications.