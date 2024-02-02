// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract VulnerableContract {
    mapping(address => uint256) public balances;
    address public owner;

    event TransferOwnership(address owner, address newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner is zero address");
        owner = newOwner;
        emit TransferOwnership(msg.sender, newOwner);
    }
}
