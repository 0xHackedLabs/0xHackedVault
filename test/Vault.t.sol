// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultTest is Test {
    using SafeMath for uint;
    Vault public vault;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address whitehat = vm.addr(1);
    address feeTo = vm.addr(11);

    function setUp() public {
        vm.createSelectFork("https://rpc.flashbots.net", 17007841);
        vm.label(USDC, "USDC");
        vault = new Vault();
        vm.label(address(vault), "Vault");
        vm.label(whitehat, "Whitehat");
    }

    function testAddCase() public {
        bytes16 uuid = 0x12345678901234567890123456789012;
        // address whitehat = vm.addr(1);
        uint caseId = vault.addCase(uuid, whitehat);
        assertEq(caseId, 0);
    }

    function testSetParams() public {
        vault.setParams(feeTo, 101);
        assertEq(vault.feeTo(), feeTo);
        assertEq(vault.basisPointsRate(), 101);
    }

    function testDepositAndPay() public {
        vault.setParams(feeTo, 500);
        address payer = vm.addr(2);
        vm.label(payer, "Payer");
        deal(USDC, payer, 1000000);
        bytes16 uuid = 0x12345678901234567890123456789012;
        uint caseId = vault.addCase(uuid, whitehat);

        // payer deposit
        vm.startPrank(payer);
        uint amount = 1000;
        IERC20(USDC).approve(address(vault), amount);

        vault.deposit(caseId, USDC, 1000);
        vm.stopPrank();
        assertEq(IERC20(USDC).balanceOf(address(vault)), amount);

        // payer pay to whithat
        vm.startPrank(payer);
        vault.payToWhiteHat(caseId, USDC, amount);
        vm.stopPrank();

        assertEq(IERC20(USDC).balanceOf(address(vault)), 0);
        uint fee = amount.mul(500).div(10000);
        assertEq(IERC20(USDC).balanceOf(feeTo), fee);
        assertEq(IERC20(USDC).balanceOf(whitehat), amount.sub(fee));
    }

    function testOtherPayToWhitehat() public {
        vault.setParams(feeTo, 500);
        address payer = vm.addr(2);
        vm.label(payer, "Payer");
        deal(USDC, payer, 1000000);
        bytes16 uuid = 0x12345678901234567890123456789012;
        uint caseId = vault.addCase(uuid, whitehat);

        // payer deposit
        vm.startPrank(payer);
        uint amount = 1000;
        IERC20(USDC).approve(address(vault), amount);

        vault.deposit(caseId, USDC, 1000);
        vm.stopPrank();

        // other can not pay to whithat
        address other = vm.addr(3);
        vm.startPrank(other);
        vm.expectRevert("not enough balance");
        vault.payToWhiteHat(caseId, USDC, amount);
        vm.stopPrank();
    }
}
