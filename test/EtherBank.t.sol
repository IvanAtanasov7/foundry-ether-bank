// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {EtherBank} from "../src/EtherBank.sol";
import {DeployEtherBank} from "../script/DeployEtherBank.s.sol";

contract EtherBankTest is Test {
    EtherBank public etherBank;

    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");
    address USER3 = makeAddr("user3");

    uint256 public constant SEND_VALUE = 1 ether;

    uint256 public constant USER1_STARTING_BALANCE = 10 ether;
    uint256 public constant USER2_STARTING_BALANCE = 5 ether;
    uint256 public constant USER3_STARTING_BALANCE = 3 ether;

    function setUp() external {
        DeployEtherBank deployEtherBank = new DeployEtherBank();
        etherBank = deployEtherBank.run();
        vm.deal(USER1, USER1_STARTING_BALANCE);
        vm.deal(USER2, USER2_STARTING_BALANCE);
        vm.deal(USER3, USER3_STARTING_BALANCE);
    }

    function testMinimumDepositUsdIsHundred() external view {
        assertEq(etherBank.MINIMUM_USD_DEPOSIT(), 100e18);
    }

    function testOwnerIsMsgSender() external view {
        assertEq(etherBank.getOwnerAddress(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() external view {
        uint256 version = etherBank.getVersion();
        assertEq(version, 4);
    }

    function testFailDepositWithoutEnoughtETH() external {
        vm.expectRevert(EtherBank.EtherBank__NotEnoughEthSend.selector);
        etherBank.deposit();
    }

    function testDepositUpdatesDataStructure() external {
        vm.prank(USER1);

        etherBank.deposit{value: SEND_VALUE}();
        uint256 amountSend = etherBank.getAccountBalance(USER1);
        assertEq(amountSend, SEND_VALUE);
    }

    function testDepositWithMultipleUsersUpdateDataStructure() external {
        // USER1
        vm.prank(USER1);
        etherBank.deposit{value: USER1_STARTING_BALANCE}();
        uint256 balanceUser1 = etherBank.getAccountBalance(USER1);
        assertEq(balanceUser1, USER1_STARTING_BALANCE);

        // USER2
        vm.prank(USER2);
        etherBank.deposit{value: USER2_STARTING_BALANCE}();
        uint256 balanceUser2 = etherBank.getAccountBalance(USER2);
        assertEq(balanceUser2, USER2_STARTING_BALANCE);

        // USER3
        vm.prank(USER3);
        etherBank.deposit{value: USER3_STARTING_BALANCE}();
        uint256 balanceUser3 = etherBank.getAccountBalance(USER3);
        assertEq(balanceUser3, USER3_STARTING_BALANCE);
    }

    function testAddUserToArrayOfUsers() external {
        vm.prank(USER1);
        etherBank.deposit{value: SEND_VALUE}();
        address user = etherBank.getUserAddress(0);
        assertEq(user, USER1);
    }

    function testAddMultipleUsersToArrayOfUsers() external {
        // USER1
        vm.prank(USER1);
        etherBank.deposit{value: USER1_STARTING_BALANCE}();
        address user1 = etherBank.getUserAddress(0);
        assertEq(user1, USER1);

        // USER2
        vm.prank(USER2);
        etherBank.deposit{value: USER2_STARTING_BALANCE}();
        address user2 = etherBank.getUserAddress(1);
        assertEq(user2, USER2);

        // USER3
        vm.prank(USER3);
        etherBank.deposit{value: USER3_STARTING_BALANCE}();
        address user3 = etherBank.getUserAddress(2);
        assertEq(user3, USER3);
    }

    function testWithdrawWithSingleUser() external {
        vm.prank(USER1);
        etherBank.deposit{value: USER1_STARTING_BALANCE}();

        uint256 startingUserBalance = etherBank.getAccountBalance(USER1);
        uint256 startingEtherBankBalance = etherBank.getBalance();

        vm.prank(USER1);
        uint256 withdrawAmount = 1 ether;
        etherBank.withdraw(withdrawAmount);

        uint256 endUserBalance = etherBank.getAccountBalance(USER1);
        uint256 endEtherBankBalance = etherBank.getBalance();

        assertEq(endUserBalance, startingUserBalance - withdrawAmount);
        assertEq(endEtherBankBalance, startingEtherBankBalance - withdrawAmount);
    }

    function testWithdrawWithMultipleUsers() external {
        // USER2
        vm.prank(USER2);
        etherBank.deposit{value: USER2_STARTING_BALANCE}();

        uint256 startingUser2Balance = etherBank.getAccountBalance(USER2);
        uint256 startingEtherBankBalanceUser2 = etherBank.getBalance();

        vm.prank(USER2);
        uint256 withdrawAmountUser2 = 2 ether;
        etherBank.withdraw(withdrawAmountUser2);

        uint256 endUser2Balance = etherBank.getAccountBalance(USER2);
        uint256 endEtherBankBalanceUser2 = etherBank.getBalance();

        assertEq(endUser2Balance, startingUser2Balance - withdrawAmountUser2);
        assertEq(endEtherBankBalanceUser2, startingEtherBankBalanceUser2 - withdrawAmountUser2);

        // USER3
        vm.prank(USER3);
        etherBank.deposit{value: USER3_STARTING_BALANCE}();

        uint256 startingUser3Balance = etherBank.getAccountBalance(USER3);
        uint256 startingEtherBankBalanceUser3 = etherBank.getBalance();

        vm.prank(USER3);
        uint256 withdrawAmountUser3 = 3 ether;
        etherBank.withdraw(withdrawAmountUser3);

        uint256 endUser3Balance = etherBank.getAccountBalance(USER3);
        uint256 endEtherBankBalanceUser3 = etherBank.getBalance();

        assertEq(endUser3Balance, startingUser3Balance - withdrawAmountUser3);
        assertEq(endEtherBankBalanceUser3, startingEtherBankBalanceUser3 - withdrawAmountUser3);
    }

    function testFailWithdrawWithInsufficientBalance() external {
        vm.prank(USER1);
        etherBank.deposit{value: USER1_STARTING_BALANCE}();

        vm.prank(USER1);
        uint256 withdrawAmount = 50 ether;
        vm.expectRevert(EtherBank.EtherBank__WithdrawInsufficientBalance.selector);
        etherBank.withdraw(withdrawAmount);
    }

    function testFailWithdrawZeroAmount() external {
        vm.prank(USER1);
        etherBank.deposit{value: USER1_STARTING_BALANCE}();

        vm.prank(USER1);
        uint256 withdrawAmount = 0 ether;
        vm.expectRevert(EtherBank.EtherBank__WithdrawAmount.selector);
        etherBank.withdraw(withdrawAmount);
    }

    function testTransferBetweenUsers() external {
        vm.prank(USER1);
        etherBank.deposit{value: USER1_STARTING_BALANCE}();

        vm.prank(USER1);
        etherBank.transfer(payable(USER2), SEND_VALUE);

        assertEq(etherBank.getAccountBalance(USER1), USER1_STARTING_BALANCE - SEND_VALUE);
        assertEq(etherBank.getAccountBalance(USER2), SEND_VALUE);
    }

    function testFailTransferSelfAccount() external {
        vm.prank(USER1);
        etherBank.deposit{value: USER1_STARTING_BALANCE}();

        vm.prank(USER1);
        vm.expectRevert(EtherBank.EtherBank__SelfAccountTransfer.selector);
        etherBank.transfer(payable(USER1), SEND_VALUE);
    }

    function testFailTransferWithInsufficientBalance() external {
        vm.prank(USER1);
        etherBank.deposit{value: USER1_STARTING_BALANCE}();

        uint256 transferAmount = 50 ether;

        vm.prank(USER1);
        vm.expectRevert(EtherBank.EtherBank__TransferInsufficientBalance.selector);
        etherBank.transfer(payable(USER2), transferAmount);
    }

    function testFailWithInvalidRecipientAddress() external {
        vm.prank(USER1);
        etherBank.deposit{value: USER1_STARTING_BALANCE}();

        vm.prank(USER1);
        vm.expectRevert(EtherBank.EtherBank__InvalidRecipientAddress.selector);
        etherBank.transfer(payable(address(0)), SEND_VALUE);
    }

    function testFailTransferAmountWithZero() external {
        vm.prank(USER1);
        etherBank.deposit{value: USER1_STARTING_BALANCE}();

        vm.prank(USER1);
        vm.expectRevert(EtherBank.EtherBank__TransferAmount.selector);
        etherBank.transfer(payable(USER2), 0);
    }
}
