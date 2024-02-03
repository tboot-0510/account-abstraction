// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {EntryPoint} from "@account-abstraction/contracts/core/EntryPoint.sol";
import {SmartAccountFactory} from "@biconomy-devx/account-contracts-v2/contracts/smart-account/factory/SmartAccountFactory.sol";
import {SmartAccount} from "@biconomy-devx/account-contracts-v2/contracts/smart-account/SmartAccount.sol";

import {CustomValidationModule} from "../src/validation/CustomValidationModule.sol";

import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

// https://github.com/namn-grg/scw-v2-test/blob/11eef1237fcb093ae1f8c1fba76e221a0064fbcf/test/TestERC20.t.sol

contract CustomValidationModuleTest is Test {
    using ECDSA for bytes32;
    CustomValidationModule public validationModule;
    IEntryPoint public ep;
    SmartAccount smartAccount;
    SmartAccountFactory smartAccountFactory;

    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        validationModule = new CustomValidationModule();
        ep = new EntryPoint();
        smartAccount = new SmartAccount(ep);
        vm.label(address(smartAccount), "Smart Account Implementation");
    }

    function getSmartAccountWithModule(
        address _moduleSetupContract,
        bytes memory _setupData,
        uint256 _index,
        string memory _label
    ) internal returns (SmartAccount sa) {
        sa = SmartAccount(
            payable(
                smartAccountFactory.deployCounterFactualAccount(
                    _moduleSetupContract,
                    _moduleSetupData,
                    _index
                )
            )
        );
        vm.label(address(sa), _label);
    }

    function getCustomModuleSetupData(
        uint128 _limitValue,
        uint128 _transactionsLimit
    ) internal pure returns (bytes memory) {
        return
            abi.encodeCall(
                CustomValidationModule.initForSmartAccount,
                (_limitValue, _transactionsLimit)
            );
    }

    function test_sendLimit() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }
}
