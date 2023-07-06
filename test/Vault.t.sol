// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultTest is Test {
    using SafeMath for uint;
    Vault public vault;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address whitehat = vm.addr(1);
    address operator = vm.addr(2);
    address feeTo = vm.addr(11);

    function setUp() public {
        vm.createSelectFork("https://rpc.flashbots.net", 17607841);
        vm.label(USDC, "USDC");
        vm.label(WETH, "WETH");
        vault = new Vault();
        vm.label(address(vault), "Vault");
        vm.label(whitehat, "Whitehat");
    }

    function testAddCase() public {
        vault.setParams(feeTo, 101, operator);
        bytes16 uuid = 0x12345678901234567890123456789012;
        vm.expectRevert("caller is not the operator");
        vault.addCase(uuid, whitehat);

        vm.startPrank(operator);
        uint caseId = vault.addCase(uuid, whitehat);
        assertEq(caseId, 0);
        vm.stopPrank();
    }

    function testSetParams() public {
        vault.setParams(feeTo, 101, operator);
        assertEq(vault.feeTo(), feeTo);
        assertEq(vault.basisPointsRate(), 101);
        assertEq(vault.operator(), operator);
    }

    function testDepositAndPay() public {
        vault.setParams(feeTo, 500, operator);
        address payer = vm.addr(2);
        vm.label(payer, "Payer");
        deal(USDC, payer, 1000000);
        bytes16 uuid = 0x12345678901234567890123456789012;
        vm.prank(operator);
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

    function testDepositAndMultiPay() public {
        vault.setParams(feeTo, 500, operator);
        address payer = vm.addr(2);
        vm.label(payer, "Payer");
        deal(USDC, payer, 1000000);
        deal(WETH, payer, 1000000);
        bytes16 uuid = 0x12345678901234567890123456789012;
        vm.prank(operator);
        uint caseId = vault.addCase(uuid, whitehat);

        // payer deposit
        vm.startPrank(payer);
        uint amount = 1000;
        IERC20(USDC).approve(address(vault), amount);
        IERC20(WETH).approve(address(vault), amount);


        vault.deposit(caseId, USDC, 1000);
        vault.deposit(caseId, WETH, 1000);
        vm.stopPrank();

        assertEq(IERC20(USDC).balanceOf(address(vault)), amount);
        assertEq(IERC20(WETH).balanceOf(address(vault)), amount);

        // payer pay to whithat
        vm.startPrank(payer);
        vault.payToWhiteHat(caseId, USDC, 200);
        vault.payToWhiteHat(caseId, USDC, amount - 200);
        vault.payToWhiteHat(caseId, WETH, 200);
        vault.payToWhiteHat(caseId, WETH, amount - 200);
        vm.stopPrank();

        assertEq(IERC20(USDC).balanceOf(address(vault)), 0);
        uint fee = amount.mul(500).div(10000);
        assertEq(IERC20(USDC).balanceOf(feeTo), fee);
        assertEq(IERC20(USDC).balanceOf(whitehat), amount.sub(fee));
        assertEq(IERC20(WETH).balanceOf(feeTo), fee);
        assertEq(IERC20(WETH).balanceOf(whitehat), amount.sub(fee));
    }

    function testOtherPayToWhitehat() public {
        vault.setParams(feeTo, 500, operator);
        address payer = vm.addr(2);
        vm.label(payer, "Payer");
        deal(USDC, payer, 1000000);
        bytes16 uuid = 0x12345678901234567890123456789012;
        vm.prank(operator);
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
        vm.expectRevert("no enough balance");
        vault.payToWhiteHat(caseId, USDC, amount);
        vm.stopPrank();
    }
}
