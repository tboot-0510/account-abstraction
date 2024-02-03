// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import {BaseAuthorizationModule} from "./BaseAuthorizationModule.sol";
import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";

contract CustomValidationModule is BaseAuthorizationModule {
    string public constant NAME = "TransactionLimiter";
    string public constant VERSION = "0.0.1";

    error LimitReached(address user, uint128 limit);
    error CanNotBeZero();
    error NotEOAOwner();

    uint128 public limitValue;
    uint128 public transactionsLimit;
    uint256 private constant DAY_IN_SECONDS = 86400;

    mapping(address => uint128) internal dailyNbTransactions;
    mapping(address => uint256) internal lastTransactionTime;

    function initForSmartAccount(
        uint128 _limitValue,
        uint128 _transactionsLimit
    ) external returns (address) {
        if (_limitValue == 0 || _transactionsLimit == 0) revert CanNotBeZero();
        limitValue = _limitValue;
        transactionsLimit = _transactionsLimit;
        return address(this);
    }

    /**
     * @param dataHash Hash of the data to be validated.
     * @param signature Signature to be validated.
     * @param callData userOps callData.
     * @return true if signature is valid, false otherwise.
     */
    function _verifySignature(
        bytes32 dataHash,
        bytes memory signature,
        bytes calldata callData
    ) internal returns (bool) {
        if (limitValue == 0 || transactionsLimit == 0) revert CanNotBeZero();

        require(callData.length >= 68, "Calldata too short");

        bytes4 functionId = bytes4(callData[:4]);

        if (functionId != bytes4(0x0000189a)) return false;

        address userSigner = (dataHash.toEthSignedMessageHash()).recover(
            signature
        );

        uint128 value = abi.decode(callData[36:68], (uint128));

        if (value > limitValue) revert LimitReached(userSigner, limitValue);

        return true;
    }

    // function recoverAccess(address payable _wallet, address _newOwner) public {
    //     // require(onlyFriends(_wallet, msg.sender), "sender not a friend");
    //     bytes32 recoveryHash = getRecoveryHash(
    //         _wallet,
    //         _newOwner,
    //         _walletsNonces[_wallet]
    //     );
    //     require(
    //         isConfirmedByRequiredFriends(recoveryHash, _wallet),
    //         "Not enough confirmations"
    //     );
    //     SmartAccount smartAccount = SmartAccount(payable(_wallet));
    //     require(
    //         smartAccount.execTransactionFromModule(
    //             _wallet,
    //             0,
    //             // abi.encodeCall("setOwner", (newOwner)),
    //             abi.encodeWithSignature("setOwner(address)", _newOwner),
    //             Enum.Operation.Call
    //         ),
    //         "Could not execute recovery"
    //     );
    //     _walletsNonces[_wallet]++;
    // }

    function updateTransactionCount(address user) public {
        if ((block.timestamp - lastTransactionTime[user]) >= DAY_IN_SECONDS) {
            dailyNbTransactions[user] = 0;
        }
        if (dailyNbTransactions[user] >= transactionsLimit)
            revert LimitReached(user, transactionsLimit);

        dailyNbTransactions[user]++;
        lastTransactionTime[user] = block.timestamp;
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external virtual override returns (uint256) {
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
