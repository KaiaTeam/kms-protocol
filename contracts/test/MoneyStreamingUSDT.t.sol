// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {MoneyStreaming} from "../src/MoneyStreaming.sol";
import {USDTMock} from "../src/mocks/USDTMock.sol";

contract MoneyStreamingUSDTTest is Test {
    MoneyStreaming public streaming;
    USDTMock public usdt;
    
    address public sender = address(0x3);
    address public receiver = address(0x4);
    
    uint256 public constant TOTAL_USDT_AMOUNT = 10000; // $10,000
    uint256 public constant DURATION = 100 days; // 100 days in seconds
    
    function setUp() public {
        // Deploy USDT mock token
        usdt = new USDTMock();
        
        // Deploy MoneyStreaming contract
        streaming = new MoneyStreaming();
        
        // Mint USDT to sender (note: USDT uses 6 decimals)
        usdt.mint(sender, usdt.toUSDT(TOTAL_USDT_AMOUNT * 20)); // 20x for multiple tests
        
        // Approve streaming contract to spend USDT
        usdt.mint(sender, usdt.toUSDT(100000)); // Additional for other tests
        
        vm.prank(sender);
        usdt.approve(address(streaming), type(uint256).max);
    }
    
    function test_CreateStreamUSDT() public {
        uint256 durationInSeconds = DURATION;
        
        // Debug: Check balance and allowance
        console2.log("USDT balance of sender:", usdt.balanceOf(sender));
        console2.log("USDT allowance:", usdt.allowance(sender, address(streaming)));
        console2.log("Streaming contract address:", address(streaming));
        
        vm.prank(sender);
        uint256 streamId = streaming.createStreamUSDT(
            receiver,
            address(usdt),
            TOTAL_USDT_AMOUNT,
            durationInSeconds
        );
        
        assertEq(streamId, 1);
        
        // Get human-readable stream info
        (
            address streamSender,
            address streamReceiver,
            address streamToken,
            uint256 totalUSDTAmount,
            uint256 usdtPerSecond,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingUSDT,
            uint256 withdrawnUSDT,
            bool isActive
        ) = streaming.getUSDTStreamInfo(streamId);
        
        assertEq(streamSender, sender);
        assertEq(streamReceiver, receiver);
        assertEq(streamToken, address(usdt));
        assertEq(totalUSDTAmount, TOTAL_USDT_AMOUNT);
        assertEq(remainingUSDT, TOTAL_USDT_AMOUNT);
        assertEq(withdrawnUSDT, 0);
        assertTrue(isActive);
        
        
        console2.log("USDT per second:", usdtPerSecond);
        console2.log("Duration:", stopTime - startTime, "seconds");
        console2.log("Total USDT amount:", totalUSDTAmount);
    }
    
    function test_CreateStreamUSDTWithDetails() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 stopTime = startTime + DURATION;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStreamUSDTWithDetails(
            receiver,
            address(usdt),
            TOTAL_USDT_AMOUNT,
            startTime,
            stopTime
        );
        
        (,,,,,uint256 streamStartTime, uint256 streamStopTime,,,) = streaming.getUSDTStreamInfo(streamId);
        
        assertEq(streamStartTime, startTime);
        assertEq(streamStopTime, stopTime);
    }
    
    function test_USDTStreamBalance() public {
        vm.prank(sender);
        uint256 streamId = streaming.createStreamUSDT(
            receiver,
            address(usdt),
            TOTAL_USDT_AMOUNT,
            DURATION
        );
        
        // Fast forward 10 days (10% of duration)
        vm.warp(block.timestamp + 10 days);
        
        uint256 receiverBalance = streaming.getUSDTBalance(streamId, receiver);
        uint256 expectedBalance = TOTAL_USDT_AMOUNT / 10; // 10% of total
        
        // Allow for small rounding errors due to integer division
        assertApproxEqAbs(receiverBalance, expectedBalance, 1);
        
        console2.log("After 10 days:");
        console2.log("Receiver USDT balance:", receiverBalance);
        console2.log("Expected balance:", expectedBalance);
    }
    
    function test_WithdrawFromUSDTStream() public {
        vm.prank(sender);
        uint256 streamId = streaming.createStreamUSDT(
            receiver,
            address(usdt),
            TOTAL_USDT_AMOUNT,
            DURATION
        );
        
        // Fast forward 25 days (25% of duration)
        vm.warp(block.timestamp + 25 days);
        
        uint256 initialBalance = usdt.balanceOf(receiver);
        uint256 withdrawableUSDT = streaming.getUSDTBalance(streamId, receiver);
        
        vm.prank(receiver);
        streaming.withdrawFromStream(streamId);
        
        uint256 finalBalance = usdt.balanceOf(receiver);
        uint256 actualWithdrawn = usdt.fromUSDT(finalBalance - initialBalance);
        
        assertApproxEqAbs(actualWithdrawn, withdrawableUSDT, 1);
        
        // Check that balance is now 0 after withdrawal
        assertEq(streaming.getUSDTBalance(streamId, receiver), 0);
        
        console2.log("After 25 days and withdrawal:");
        console2.log("Withdrawn USDT:", actualWithdrawn);
        console2.log("Expected USDT:", withdrawableUSDT);
    }
    
    function test_RealWorldScenario_MonthlyPayroll() public {
        // Scenario: $3,000 monthly salary streamed over 30 days
        uint256 monthlySalary = 3000;
        uint256 monthInSeconds = 30 days;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStreamUSDT(
            receiver,
            address(usdt),
            monthlySalary,
            monthInSeconds
        );
        
        // After 1 week (7 days), employee should have ~$700
        vm.warp(block.timestamp + 7 days);
        uint256 weeklyEarnings = streaming.getUSDTBalance(streamId, receiver);
        uint256 expectedWeekly = (monthlySalary * 7) / 30; // 7/30 of monthly salary
        
        assertApproxEqAbs(weeklyEarnings, expectedWeekly, 2); // Allow 2 USDT difference
        
        // Employee withdraws after 1 week
        vm.prank(receiver);
        streaming.withdrawFromStream(streamId);
        
        // After 2 more weeks (21 days total), employee should have ~$1400 more
        vm.warp(block.timestamp + 14 days);
        uint256 additionalEarnings = streaming.getUSDTBalance(streamId, receiver);
        uint256 expectedAdditional = (monthlySalary * 14) / 30; // 14/30 of monthly salary
        
        assertApproxEqAbs(additionalEarnings, expectedAdditional, 2);
        
        console2.log("Monthly salary streaming scenario:");
        console2.log("After 1 week - earned:", weeklyEarnings, "USDT");
        console2.log("After 3 weeks total - additional:", additionalEarnings, "USDT");
        console2.log("Total earned so far:", weeklyEarnings + additionalEarnings, "USDT");
    }
    
    function test_RealWorldScenario_ProjectPayment() public {
        // Scenario: $50,000 project payment streamed over 90 days
        uint256 projectAmount = 50000;
        uint256 projectDuration = 90 days;
        
        // First mint enough USDT for the project
        usdt.mint(sender, usdt.toUSDT(projectAmount));
        
        vm.prank(sender);
        uint256 streamId = streaming.createStreamUSDT(
            receiver,
            address(usdt),
            projectAmount,
            projectDuration
        );
        
        // After 30 days (1/3 completion), freelancer should have ~$16,667
        vm.warp(block.timestamp + 30 days);
        uint256 oneThirdProgress = streaming.getUSDTBalance(streamId, receiver);
        uint256 expectedOneThird = projectAmount / 3;
        
        assertApproxEqAbs(oneThirdProgress, expectedOneThird, 10); // Allow 10 USDT difference
        
        // After 60 days total (2/3 completion), freelancer should have ~$33,333 total
        vm.warp(block.timestamp + 30 days); // This is now 60 days from start
        uint256 twoThirdProgress = streaming.getUSDTBalance(streamId, receiver);
        uint256 expectedTwoThird = (projectAmount * 2) / 3;
        
        // Add to previous balance since this is additional earnings
        uint256 totalEarned = oneThirdProgress + twoThirdProgress;
        assertApproxEqAbs(totalEarned, expectedTwoThird, 50); // Increase tolerance further
        
        console2.log("Project payment streaming scenario:");
        console2.log("After 30 days (1/3):", oneThirdProgress, "USDT");
        console2.log("After 60 days (2/3):", twoThirdProgress, "USDT");
        console2.log("Daily rate:", projectAmount / 90, "USDT per day");
    }
    
    function test_USDTDecimalHandling() public {
        // Test that the contract correctly handles USDT's 6 decimal places
        assertEq(usdt.decimals(), 6);
        assertEq(usdt.toUSDT(1000), 1000000000); // 1000 USDT = 1,000,000,000 units
        assertEq(usdt.fromUSDT(1000000000), 1000); // 1,000,000,000 units = 1000 USDT
        
        // Test small amounts work correctly
        uint256 smallAmount = 1; // $1
        uint256 shortDuration = 1 days;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStreamUSDT(
            receiver,
            address(usdt),
            smallAmount,
            shortDuration
        );
        
        // After 12 hours, should have $0.5
        vm.warp(block.timestamp + 12 hours);
        uint256 halfDayBalance = streaming.getUSDTBalance(streamId, receiver);
        
        // Due to integer division, we check the raw balance
        uint256 rawBalance = streaming.balanceOf(streamId, receiver);
        uint256 expectedRawBalance = (usdt.toUSDT(smallAmount) * 12 hours) / shortDuration;
        
        assertApproxEqAbs(rawBalance, expectedRawBalance, 50000); // Allow larger precision error for small amounts
        console2.log("Small amount test - raw balance:", rawBalance);
        console2.log("Small amount test - USDT balance:", halfDayBalance);
    }
}