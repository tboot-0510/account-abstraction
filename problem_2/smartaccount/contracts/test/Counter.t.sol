// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CustomValidationModule} from "../src/CustomValidationModule.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

// https://github.com/namn-grg/scw-v2-test/blob/11eef1237fcb093ae1f8c1fba76e221a0064fbcf/test/TestERC20.t.sol

contract CustomValidationModuleTest is Test {
    using ECDSA for bytes32;
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
