// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { BaseAuthorizationModule } from "../BaseAuthorizationModule.sol";
import { UserOperation } from "@account-abstraction/contracts/interfaces/UserOperation.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Enum } from "../../common/Enum.sol";

interface ITxLimiterValidationModule {
    struct LimiterSettings {
        uint128 limitValue;
        uint128 transactionsLimit;
    }

    error CanNotBeZero();
    error LimitReached(address user, uint128 limit);
    error AlreadyInitedForSmartAccount(address);
    event TransactionExecuted(address user, uint256 count);
}

interface ITxLimiterExecutionModule {
    function validTxCount(address user, uint128 limit) external view returns (bool);
}

interface ISmartAccount {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 txGas
    ) external returns (bool);
}

contract TxLimiterValidationModule is BaseAuthorizationModule, ITxLimiterValidationModule {
    using ECDSA for bytes32;

    string public constant NAME = "TransactionLimiter";
    string public constant VERSION = "0.0.1";

    bytes4 constant SCA_EXECUTE = bytes4(keccak256("execute(address,uint256,bytes)"));

    bytes4 constant SCA_EXECUTE_OPTIMIZED = bytes4(keccak256("execute_ncC(address,uint256,bytes)"));

    mapping(address => uint256) public transactionCount;
    mapping(address => LimiterSettings) public _smartAccountSettings;
    mapping(address => uint256) internal lastTransactionTime;
    uint256 private constant DAY_IN_SECONDS = 86400;

    ISmartAccount public immutable _smartAccount;

    constructor(address _smartAccountAddress) {
        require(_smartAccountAddress != address(0), "SmartAccount address cannot be zero.");
        _smartAccount = ISmartAccount(_smartAccountAddress);
    }

    function getLimits(address user) public view returns (LimiterSettings memory) {
        return _smartAccountSettings[user];
    }

    function initForSmartAccount(uint128 _limitValue, uint128 _transactionsLimit) external returns (address) {
        if (_limitValue == 0 || _transactionsLimit == 0) revert CanNotBeZero();
        if (_smartAccountSettings[msg.sender].transactionsLimit > 0) revert AlreadyInitedForSmartAccount(msg.sender);

        _smartAccountSettings[msg.sender] = LimiterSettings(_limitValue, _transactionsLimit);
        return address(this);
    }

    function _verifySignature(
        bytes32 dataHash,
        bytes memory signature,
        address smartAccount
    ) internal view returns (bool) {
        (bytes memory signatureWithValues, bytes memory valueBytes) = abi.decode(signature, (bytes, bytes));

        address userSigner = (dataHash.toEthSignedMessageHash()).recover(signatureWithValues);
        if (userSigner != smartAccount) return false;

        uint256 transactionValue = abi.decode(valueBytes, (uint256));

        LimiterSettings storage settings = _smartAccountSettings[smartAccount];
        if (settings.limitValue == 0 || settings.transactionsLimit == 0) revert CanNotBeZero();

        if (uint128(transactionValue) > settings.limitValue) revert LimitReached(userSigner, settings.limitValue);

        if (!validTxCount(userSigner, settings.transactionsLimit))
            revert LimitReached(userSigner, settings.transactionsLimit);

        return true;
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
            _smartAccount.execTransactionFromModule(to, value, data, Enum.Operation.Call, 0),
            "Could not execute transaction"
        );

        updateTxCount(msg.sender);

        emit TransactionExecuted(msg.sender, transactionCount[msg.sender]);
    }

    function decodeUserOpCallData(
        bytes calldata userOpCalldata
    ) private pure returns (address dest, bytes4 selector, bytes calldata data, uint256 callValue) {
        bytes4 scaSelector = bytes4(userOpCalldata[:4]);

        if (scaSelector != SCA_EXECUTE && scaSelector != SCA_EXECUTE_OPTIMIZED) {
            revert("Wrong selector");
        }
        // padded address (bytes4 selector + padding of 12 bytes) i.e. 4+12 = 16 to 16+20 = 36
        dest = address(bytes20(userOpCalldata[16:36]));

        // uint256 (bytes4 selector + padded address of 32 bytes) i.e. 4+32 = 36 to 36+32 = 68
        callValue = uint256(bytes32(userOpCalldata[36:68]));

        // bytes (bytes4 selector + padded address of 32 bytes + uint256 of 32 bytes + offset of bytes32 + length of bytes32 + bytes4 of selector) i.e. 4+32+32+32+32 = 132 to 132+4 = 136
        selector = bytes4(userOpCalldata[132:136]);

        // bytes :136 to end
        data = userOpCalldata[136:];
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external virtual override returns (uint256) {
        (bytes memory moduleSignature, ) = abi.decode(userOp.signature, (bytes, address));

        if (_verifySignature(userOpHash, moduleSignature, userOp.sender)) {
            return VALIDATION_SUCCESS;
        }

        return SIG_VALIDATION_FAILED;
    }

    function isValidSignature(
        bytes32 dataHash,
        bytes memory moduleSignature
    ) public view virtual override returns (bytes4) {
        return isValidSignatureForAddress(dataHash, moduleSignature, msg.sender);
    }

    function isValidSignatureForAddress(
        bytes32 dataHash,
        bytes memory moduleSignature,
        address smartAccount
    ) public view virtual returns (bytes4) {
        if (
            _verifySignature(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n52", dataHash, smartAccount)),
                moduleSignature,
                smartAccount
            )
        ) {
            return EIP1271_MAGIC_VALUE;
        }
        return bytes4(0xffffffff);
    }

    function isValidSignatureUnsafe(bytes32 dataHash, bytes memory moduleSignature) public virtual returns (bytes4) {
        return isValidSignatureForAddressUnsafe(dataHash, moduleSignature, msg.sender);
    }

    function isValidSignatureForAddressUnsafe(
        bytes32 dataHash,
        bytes memory moduleSignature,
        address smartAccount
    ) public virtual returns (bytes4) {
        if (_verifySignature(dataHash, moduleSignature, smartAccount)) {
            return EIP1271_MAGIC_VALUE;
        }
        return bytes4(0xffffffff);
    }
}
