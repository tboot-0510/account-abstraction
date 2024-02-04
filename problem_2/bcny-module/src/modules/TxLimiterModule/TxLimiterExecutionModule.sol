// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "../../common/ReentrancyGuard.sol";
import { Enum } from "../../common/Enum.sol";

interface ISmartAccount {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 txGas
    ) external returns (bool);
}

interface ITxLimiterExecutionModule {
    event TransactionExecuted(address user, uint256 count);
    error LimitReached(address user, uint128 limit);
}

contract TxLimiterExecutionModule is Ownable, ReentrancyGuard, ITxLimiterExecutionModule {
    mapping(address => uint256) public transactionCount;

    ISmartAccount public immutable smartAccount;

    mapping(address => uint256) internal lastTransactionTime;
    uint256 private constant DAY_IN_SECONDS = 86400;

    constructor(address _smartAccountAddress) {
        require(_smartAccountAddress != address(0), "SmartAccount address cannot be zero.");
        smartAccount = ISmartAccount(_smartAccountAddress);
    }

    function validTxCount(address user, uint128 transactionsLimit) public view returns (bool) {
        if ((block.timestamp - lastTransactionTime[user]) >= DAY_IN_SECONDS) {
            return true;
        }
        if (transactionCount[user] >= transactionsLimit) return false;

        return true;
    }

    function updateTxCount(address user) private {
        if ((block.timestamp - lastTransactionTime[user]) >= DAY_IN_SECONDS) {
            transactionCount[user] = 0;
            lastTransactionTime[user] = block.timestamp;
            return;
        }

        transactionCount[user]++;
        lastTransactionTime[user] = block.timestamp;
    }

    function executeTransaction(address to, uint256 value, bytes calldata data) public {
        require(
            smartAccount.execTransactionFromModule(to, value, data, Enum.Operation.Call, 0),
            "Could not execute transaction"
        );

        updateTxCount(msg.sender);

        emit TransactionExecuted(msg.sender, transactionCount[msg.sender]);
    }
}
