// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Factory.sol";

contract CounterTest is Test {
    Factory public factory;
    address feeTo;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function setUp() public {
        factory = new Factory();
        feeTo = vm.addr(16);
    }

    function testAddCase() public {
        bytes16 uuid = 0x12345678901234567890123456789012;
        address whitehat = vm.addr(1);
        uint caseId = factory.addCase(uuid, whitehat);
        assertEq(caseId, 1);
    }

    function testSetParams() public {
        address addr = vm.addr(2222);
        factory.setParams(feeTo, 101);
        assertEq(factory.feeTo(), feeTo);
        assertEq(factory.basisPointsRate(), 101);
    }


}
