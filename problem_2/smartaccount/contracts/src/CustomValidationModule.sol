// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {BaseAuthorizationModule} from "./BaseAuthorizationModule.sol";
import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";

contract CustomeValidationModule is BaseAuthorizationModule {
    string public constant NAME = "TransactionLimiter";
    string public constant VERSION = "0.0.1";

    error LimitReached(address user, uint128 limit);
    error CanNotBeZero();

    uint128 public limitValue;
    uint128 public transactionsLimit;
    uint256 private constant DAY_IN_SECONDS = 86400;

    mapping(address => uint128) internal dailyNbTransactions;
    mapping(address => uint256) internal lastTransactionTime;

    /**
        Smart contract account calls this function with msg.sender as smart account address
        It updates the relevant storage for the msg sender, It could be ownership information as mentioned in ECDSAOwnsership Module.
        The function signature of this method will be used as moduleSetupData in Account Factory
    */
    function initForSmartAccount(
        uint128 _limitValue,
        uint128 _transactionsLimit
    ) external returns (address) {
        if (_limitValue == 0) revert CanNotBeZero();
        if (_transactionsLimit == 0) revert CanNotBeZero();
        limitValue = _limitValue;
        transactionsLimit = _transactionsLimit;
        startDate = block.timestamp;
        return address(this);
    }

    /**
     * @param dataHash Hash of the data to be validated.
     * @param signature Signature to be validated.
     * @param callData userOps callData.
     * @param smartAccount expected signer Smart Account address.
     * @return true if signature is valid, false otherwise.
     */

    // if user sends one transaction then :
    // - encodeExecute(to, value, data)
    // ethers.id("execute_ncC(address,uint256,bytes)") => '0x0000189aa837583008638f6cac2ce6b55733abf2489048e3ebd2e2b11e6e2837'
    function _verifySignature(
        bytes32 dataHash,
        bytes memory signature,
        bytes calldata callData
    ) internal view returns (bool) {
        require(callData.length >= 68, "Calldata too short");

        bytes4 functionId = bytes4(callData[:4]);

        if (functionId != bytes4(0x0000189a)) return false;

        address userSigner = (dataHash.toEthSignedMessageHash()).recover(
            signature
        );

        uint128 value = abi.decode(data[36:68], (uint128));

        if (value > limitValue) revert LimitReached(userSigner, limitValue);

        if (
            (block.timestamp - lastTransactionTime[userSigner]) >=
            DAY_IN_SECONDS
        ) {
            dailyTransactionCount[user] = 0;
        }

        require(
            dailyTransactionCount[userSigner] < transactionsLimit,
            LimitReached(userSigner, transactionsLimit)
        );

        dailyTransactionCount[userSigner]++;
        lastTransactionTime[userSigner] = block.timestamp;
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external view virtual override returns (uint256) {
        (bytes memory moduleSignature, ) = abi.decode(
            userOp.signature,
            (bytes, address)
        );
        if (_verifySignature(userOpHash, moduleSignature, userOp.callData)) {
            return VALIDATION_SUCCESS;
        }
        return SIG_VALIDATION_FAILED;
    }

    function isValidSignature(
        bytes32 dataHash,
        bytes memory moduleSignature
    ) public view virtual override returns (bytes4) {
        return
            isValidSignatureForAddress(dataHash, moduleSignature, msg.sender);
    }

    function isValidSignatureForAddress(
        bytes32 dataHash,
        bytes memory moduleSignature,
        address smartAccount
    ) public view virtual override returns (bytes4) {
        if (
            _verifySignature(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n52",
                        dataHash,
                        smartAccount
                    )
                ),
                moduleSignature,
                smartAccount
            )
        ) {
            return EIP1271_MAGIC_VALUE;
        }
        return bytes4(0xffffffff);
    }

    function isValidSignatureUnsafe(
        bytes32 dataHash,
        bytes memory moduleSignature
    ) public view virtual returns (bytes4) {
        return
            isValidSignatureForAddressUnsafe(
                dataHash,
                moduleSignature,
                msg.sender
            );
    }

    function isValidSignatureForAddressUnsafe(
        bytes32 dataHash,
        bytes memory moduleSignature,
        address smartAccount
    ) public view virtual returns (bytes4) {
        if (_verifySignature(dataHash, moduleSignature, smartAccount)) {
            return EIP1271_MAGIC_VALUE;
        }
        return bytes4(0xffffffff);
    }
}
