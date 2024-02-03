// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ISmartAccount {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data
    ) external;
}

contract CustomExecutionModule {
    uint256 public constant MAX_TRANSACTIONS_PER_DAY = 3;

    mapping(address => uint256) public transactionCount;
    mapping(address => uint256) public lastTransactionTimestamp;

    ISmartAccount public smartAccount;
}
