// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Test } from "../lib/forge-std/src/Test.sol";
import { console } from "../lib/forge-std/src/console.sol";
import { EntryPoint } from "@account-abstraction/contracts/core/EntryPoint.sol";
import { SmartAccount } from "../src/SmartAccount.sol";
import { SmartAccountFactory } from "../src/SmartAccountFactory.sol";
import { EcdsaOwnershipRegistryModule } from "../src/modules/EcdsaOwnershipRegistryModule.sol";
import { SmartContractOwnershipRegistryModule } from "../src/modules/SmartContractOwnershipRegistryModule.sol";
import { UserOperation } from "../lib/account-abstraction/contracts/interfaces/UserOperation.sol";

import { ERC4337Utils } from "../src/ERC4337Utils.sol";
import { ECDSA } from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import { IERC20 } from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { IEntryPoint } from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import { TxLimiterExecutionModule } from "../src/modules/TxLimiterModule/TxLimiterExecutionModule.sol";
import { TxLimiterValidationModule } from "../src/modules/TxLimiterModule/TxLimiterValidationModule.sol";

interface ISAFactory {
    function deployCounterFactualAccount(
        address moduleSetupContract,
        bytes calldata moduleSetupData,
        uint256 index
    ) external returns (address proxy);

    function deployAccount(
        address moduleSetupContract,
        bytes calldata moduleSetupData
    ) external returns (address proxy);

    function getAddressForCounterFactualAccount(
        address moduleSetupContract,
        bytes calldata moduleSetupData,
        uint256 index
    ) external view returns (address _account);
}

contract TransactionLimiterModuleTest is Test {
    using ECDSA for bytes32;
    uint256 public forkNumber;

    uint256 public smartAccountDeploymentIndex;
    address public userSA;
    address public txLimiterExecutionModuleAddress;
    address public txLimiterValidationModuleAddress;
    address public smartAccountFactoryAddress;

    address public smartAccountOwner;
    uint256 public saOwnerKey;
    address public alice;
    address public bob;

    EntryPoint public ep;
    IEntryPoint public entryPoint;
    SmartAccount public smartAccountImplementation;
    SmartAccountFactory public smartAccountFactory;
    TxLimiterValidationModule public txLimiterValidationModule;
    TxLimiterExecutionModule public txLimiterExecutionModule;

    function setUp() public {
        ep = new EntryPoint();
        smartAccountImplementation = new SmartAccount(ep);
        smartAccountFactory = new SmartAccountFactory(address(smartAccountImplementation));
        txLimiterExecutionModule = new TxLimiterExecutionModule(address(smartAccountImplementation));
        txLimiterValidationModule = new TxLimiterValidationModule(address(txLimiterExecutionModule));

        vm.deal(address(ep), 5 ether);
        vm.deal(address(txLimiterExecutionModule), 5 ether);
        vm.deal(smartAccountFactoryAddress, 5 ether);

        txLimiterValidationModuleAddress = address(txLimiterValidationModule);
        txLimiterExecutionModuleAddress = address(txLimiterExecutionModule);
        smartAccountFactoryAddress = address(smartAccountFactory);

        // Initializes EOA Addresses
        (smartAccountOwner, saOwnerKey) = makeAddrAndKey("smartAccountOwner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // Deploy SA and fund it with 5 ether
        bytes memory txnData1 = abi.encodeWithSignature("initForSmartAccount(uint128,uint128)", 2, 2);
        userSA = ISAFactory(smartAccountFactoryAddress).deployCounterFactualAccount(
            txLimiterValidationModuleAddress,
            txnData1,
            smartAccountDeploymentIndex
        );
        vm.deal(userSA, 5 ether);
    }

    function testInitForSmartAccount() public {
        TxLimiterValidationModule.LimiterSettings memory settings = txLimiterValidationModule.getLimits(userSA);
        assertEq(settings.limitValue, 2, "Limit value does not match expected value");
        assertEq(settings.transactionsLimit, 2, "Transactions value does not match expected value");
    }

    function testReInitForSmartAccountAfterDeployed() public {
        vm.expectRevert();
        bytes memory txnData1 = abi.encodeWithSignature("initForSmartAccount(uint128,uint128)", 2, 2);
        userSA = ISAFactory(smartAccountFactoryAddress).deployCounterFactualAccount(
            txLimiterValidationModuleAddress,
            txnData1,
            smartAccountDeploymentIndex
        );
    }

    function testValidationModule() public {
        vm.deal(alice, 2 ether);
        bytes memory txnData1 = abi.encode(bob, 1 ether);
        UserOperation memory userOp = fillUserOp(ep, userSA, txnData1);
        uint256 transactionValue = 1 ether;

        bytes32 hashed1 = hash(userOp);
        bytes32 hashed2 = keccak256(abi.encode(hashed1, address(ep), block.chainid));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(saOwnerKey, hashed2.toEthSignedMessageHash());
        bytes memory encodedValue = abi.encode(transactionValue);
        bytes memory tempSignature = abi.encodePacked(r, s, v);
        bytes memory combinedData = abi.encode(tempSignature, encodedValue);
        userOp.signature = abi.encode(combinedData, txLimiterValidationModuleAddress);

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = userOp;
        vm.prank(userSA);
        ep.handleOps(ops, payable(bob)); // ERROR "AA24 signature error"
    }

    /*  HELPER FUNCTIONS FOR CONSTRUCTING AND SIGNING USER-OP   */
    function fillUserOp(
        EntryPoint _entryPoint,
        address _sender,
        bytes memory _data
    ) internal view returns (UserOperation memory op) {
        op.sender = _sender;
        // op.nonce = _entryPoint.getNonce(_sender, 0);
        op.nonce = 0;
        op.callData = _data;
        op.callGasLimit = 10000000;
        op.verificationGasLimit = 10000000;
        op.preVerificationGas = 50000;
        op.maxFeePerGas = 50000;
        op.maxPriorityFeePerGas = 1;
    }

    function getSender(UserOperation memory userOp) internal pure returns (address) {
        return userOp.sender;
    }

    function pack(UserOperation memory userOp) internal pure returns (bytes memory ret) {
        address sender = getSender(userOp);
        uint256 nonce = userOp.nonce;
        bytes32 hashInitCode = keccak256(userOp.initCode);
        bytes32 hashCallData = keccak256(userOp.callData);
        uint256 callGasLimit = userOp.callGasLimit;
        uint256 verificationGasLimit = userOp.verificationGasLimit;
        uint256 preVerificationGas = userOp.preVerificationGas;
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        bytes32 hashPaymasterAndData = keccak256(userOp.paymasterAndData);

        return
            abi.encode(
                sender,
                nonce,
                hashInitCode,
                hashCallData,
                callGasLimit,
                verificationGasLimit,
                preVerificationGas,
                maxFeePerGas,
                maxPriorityFeePerGas,
                hashPaymasterAndData
            );
    }

    function hash(UserOperation memory userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }
}
