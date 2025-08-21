// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {MoneyStreaming} from "../src/MoneyStreaming.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MoneyStreamingTest is Test {
    MoneyStreaming public streaming;
    ERC20Mock public token;
    
    address public owner = address(0x1);
    address public feeCollector = address(0x2);
    address public sender = address(0x3);
    address public receiver = address(0x4);
    
    uint256 public constant NET_AMOUNT = 1000e18; // Amount to be streamed (excluding fees)
    uint256 public constant FLOW_RATE = 10e18; // 10 tokens per second  
    uint256 public constant DURATION = 100; // 100 seconds
    uint256 public constant DEPOSIT = NET_AMOUNT + (NET_AMOUNT * 50) / 10000; // Include 0.5% platform fee
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy mock ERC20 token
        token = new ERC20Mock();
        
        // Deploy MoneyStreaming contract
        streaming = new MoneyStreaming(feeCollector);
        
        // Mint tokens to sender (more for multiple tests)
        token.mint(sender, 100000e18); // 100,000 tokens for various tests
        
        vm.stopPrank();
        
        // Approve streaming contract to spend tokens
        vm.prank(sender);
        token.approve(address(streaming), type(uint256).max);
    }
    
    function test_CreateStream() public {
        uint256 startTime = block.timestamp + 10;
        uint256 stopTime = startTime + DURATION;
        
        uint256 requiredDeposit = FLOW_RATE * DURATION;
        uint256 platformFee = (requiredDeposit * streaming.platformFeeRate()) / 10000;
        uint256 totalRequired = requiredDeposit + platformFee;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            totalRequired,
            FLOW_RATE,
            startTime,
            stopTime
        );
        
        assertEq(streamId, 1);
        
        (
            address streamSender,
            address streamReceiver,
            address streamToken,
            uint256 streamDeposit,
            uint256 streamFlowRate,
            uint256 streamStartTime,
            uint256 streamStopTime,
            uint256 remainingBalance,
            uint256 withdrawnBalance,
            bool isActive
        ) = streaming.getStream(streamId);
        
        assertEq(streamSender, sender);
        assertEq(streamReceiver, receiver);
        assertEq(streamToken, address(token));
        assertEq(streamDeposit, requiredDeposit);
        assertEq(streamFlowRate, FLOW_RATE);
        assertEq(streamStartTime, startTime);
        assertEq(streamStopTime, stopTime);
        assertEq(remainingBalance, requiredDeposit);
        assertEq(withdrawnBalance, 0);
        assertTrue(isActive);
        
        // Check fee collector received platform fee
        assertEq(token.balanceOf(feeCollector), platformFee);
    }
    
    function test_StreamBalance() public {
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + DURATION;
        
        uint256 requiredDeposit = FLOW_RATE * DURATION;
        uint256 platformFee = (requiredDeposit * streaming.platformFeeRate()) / 10000;
        uint256 totalRequired = requiredDeposit + platformFee;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            totalRequired,
            FLOW_RATE,
            startTime,
            stopTime
        );
        
        // Fast forward 50 seconds
        vm.warp(startTime + 50);
        
        uint256 expectedStreamed = FLOW_RATE * 50;
        uint256 receiverBalance = streaming.balanceOf(streamId, receiver);
        
        assertEq(receiverBalance, expectedStreamed);
    }
    
    function test_WithdrawFromStream() public {
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + DURATION;
        
        uint256 requiredDeposit = FLOW_RATE * DURATION;
        uint256 platformFee = (requiredDeposit * streaming.platformFeeRate()) / 10000;
        uint256 totalRequired = requiredDeposit + platformFee;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            totalRequired,
            FLOW_RATE,
            startTime,
            stopTime
        );
        
        // Fast forward 50 seconds
        vm.warp(startTime + 50);
        
        uint256 initialBalance = token.balanceOf(receiver);
        uint256 expectedWithdraw = FLOW_RATE * 50;
        
        vm.prank(receiver);
        streaming.withdrawFromStream(streamId);
        
        uint256 finalBalance = token.balanceOf(receiver);
        assertEq(finalBalance - initialBalance, expectedWithdraw);
        
        // Check that balance is now 0
        assertEq(streaming.balanceOf(streamId, receiver), 0);
    }
    
    function test_PauseStream() public {
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + DURATION;
        
        uint256 requiredDeposit = FLOW_RATE * DURATION;
        uint256 platformFee = (requiredDeposit * streaming.platformFeeRate()) / 10000;
        uint256 totalRequired = requiredDeposit + platformFee;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            totalRequired,
            FLOW_RATE,
            startTime,
            stopTime
        );
        
        // Fast forward 30 seconds
        vm.warp(startTime + 30);
        
        vm.prank(sender);
        streaming.pauseStream(streamId);
        
        (,,,,,,, uint256 remainingBalance, uint256 withdrawnBalance, bool isActive) = streaming.getStream(streamId);
        
        assertFalse(isActive);
        
        uint256 expectedRemaining = requiredDeposit - (FLOW_RATE * 30);
        assertEq(remainingBalance, expectedRemaining);
    }
    
    function test_CancelStream() public {
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + DURATION;
        
        uint256 requiredDeposit = FLOW_RATE * DURATION;
        uint256 platformFee = (requiredDeposit * streaming.platformFeeRate()) / 10000;
        uint256 totalRequired = requiredDeposit + platformFee;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            totalRequired,
            FLOW_RATE,
            startTime,
            stopTime
        );
        
        // Fast forward 30 seconds
        vm.warp(startTime + 30);
        
        uint256 senderInitialBalance = token.balanceOf(sender);
        uint256 receiverInitialBalance = token.balanceOf(receiver);
        
        vm.prank(sender);
        streaming.cancelStream(streamId);
        
        uint256 expectedReceived = FLOW_RATE * 30;
        uint256 expectedReturned = requiredDeposit - expectedReceived;
        
        assertEq(token.balanceOf(receiver) - receiverInitialBalance, expectedReceived);
        assertEq(token.balanceOf(sender) - senderInitialBalance, expectedReturned);
        
        (,,,,,,,,, bool isActive) = streaming.getStream(streamId);
        assertFalse(isActive);
    }
    
    function test_RevertWhen_CreateStreamInvalidFlowRate() public {
        uint256 startTime = block.timestamp + 10;
        uint256 stopTime = startTime + DURATION;
        
        // Set a deposit that would result in a different flow rate than provided
        uint256 deposit = 1000e18; // Some deposit amount
        uint256 wrongFlowRate = 2e18; // Wrong flow rate that doesn't match deposit/duration
        
        vm.prank(sender);
        vm.expectRevert(abi.encodeWithSelector(MoneyStreaming.InvalidFlowRate.selector));
        streaming.createStream(
            receiver,
            address(token),
            deposit,
            wrongFlowRate,
            startTime,
            stopTime
        );
    }
    
    function test_RevertWhen_CreateStreamInsufficientDeposit() public {
        uint256 startTime = block.timestamp + 10;
        uint256 stopTime = startTime + DURATION;
        
        // Test with zero deposit
        vm.prank(sender);
        vm.expectRevert(abi.encodeWithSelector(MoneyStreaming.InvalidStreamParams.selector));
        streaming.createStream(
            receiver,
            address(token),
            0, // Zero deposit
            FLOW_RATE,
            startTime,
            stopTime
        );
    }
    
    function test_RevertWhen_WithdrawUnauthorized() public {
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + DURATION;
        
        uint256 requiredDeposit = FLOW_RATE * DURATION;
        uint256 platformFee = (requiredDeposit * streaming.platformFeeRate()) / 10000;
        uint256 totalRequired = requiredDeposit + platformFee;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            totalRequired,
            FLOW_RATE,
            startTime,
            stopTime
        );
        
        // Try to withdraw as sender (not receiver)
        vm.prank(sender);
        vm.expectRevert(abi.encodeWithSelector(MoneyStreaming.NotAuthorized.selector));
        streaming.withdrawFromStream(streamId);
    }
    
    function test_GetSenderAndReceiverStreams() public {
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + DURATION;
        
        uint256 requiredDeposit = FLOW_RATE * DURATION;
        uint256 platformFee = (requiredDeposit * streaming.platformFeeRate()) / 10000;
        uint256 totalRequired = requiredDeposit + platformFee;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            totalRequired,
            FLOW_RATE,
            startTime,
            stopTime
        );
        
        uint256[] memory senderStreams = streaming.getSenderStreams(sender);
        uint256[] memory receiverStreams = streaming.getReceiverStreams(receiver);
        
        assertEq(senderStreams.length, 1);
        assertEq(receiverStreams.length, 1);
        assertEq(senderStreams[0], streamId);
        assertEq(receiverStreams[0], streamId);
    }
    
    function test_SetPlatformFeeRate() public {
        uint256 newFeeRate = 100; // 1%
        
        vm.prank(owner);
        streaming.setPlatformFeeRate(newFeeRate);
        
        assertEq(streaming.platformFeeRate(), newFeeRate);
    }
    
    function test_RevertWhen_SetPlatformFeeRateTooHigh() public {
        uint256 tooHighFeeRate = 1001; // 10.01%
        
        vm.prank(owner);
        vm.expectRevert("Fee rate cannot exceed 10%");
        streaming.setPlatformFeeRate(tooHighFeeRate);
    }
    
    function test_PlatformFeeCalculationAccuracy() public {
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + DURATION;
        
        // Test with different deposit amounts to verify fee calculation accuracy
        uint256[] memory testDeposits = new uint256[](3);
        testDeposits[0] = 1000e18;  // 1000 tokens
        testDeposits[1] = 5000e18;  // 5000 tokens  
        testDeposits[2] = 10000e18; // 10000 tokens
        
        for (uint256 i = 0; i < testDeposits.length; i++) {
            uint256 deposit = testDeposits[i];
            
            // Calculate expected platform fee: fee = (deposit * feeRate) / (10000 + feeRate)
            uint256 expectedPlatformFee = (deposit * streaming.platformFeeRate()) / (10000 + streaming.platformFeeRate());
            uint256 expectedNetAmount = deposit - expectedPlatformFee;
            uint256 expectedFlowRate = expectedNetAmount / DURATION;
            
            uint256 initialFeeCollectorBalance = token.balanceOf(feeCollector);
            
            vm.prank(sender);
            uint256 streamId = streaming.createStream(
                receiver,
                address(token),
                deposit,
                expectedFlowRate,
                startTime,
                stopTime
            );
            
            // Verify platform fee was collected correctly
            uint256 actualPlatformFee = token.balanceOf(feeCollector) - initialFeeCollectorBalance;
            assertEq(actualPlatformFee, expectedPlatformFee, "Platform fee calculation incorrect");
            
            // Verify stream was created with correct net amount
            (,,,uint256 streamDeposit,,,,,,) = streaming.getStream(streamId);
            assertEq(streamDeposit, expectedNetAmount, "Stream deposit should be net amount");
            
            console2.log("Test deposit:", deposit / 1e18, "tokens");
            console2.log("Platform fee:", actualPlatformFee / 1e18, "tokens");
            console2.log("Net amount:", expectedNetAmount / 1e18, "tokens");
            console2.log("---");
        }
    }
    
    function test_FlowRateValidation() public {
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + DURATION;
        uint256 deposit = 1000e18;
        
        // Calculate correct flow rate
        uint256 platformFee = (deposit * streaming.platformFeeRate()) / (10000 + streaming.platformFeeRate());
        uint256 netAmount = deposit - platformFee;
        uint256 correctFlowRate = netAmount / DURATION;
        
        // Test with correct flow rate - should succeed
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            deposit,
            correctFlowRate,
            startTime,
            stopTime
        );
        assertTrue(streamId > 0, "Stream should be created with correct flow rate");
        
        // Test with incorrect flow rate - should fail
        uint256 incorrectFlowRate = correctFlowRate + 1; // Off by 1 wei
        
        vm.prank(sender);
        vm.expectRevert(abi.encodeWithSelector(MoneyStreaming.InvalidFlowRate.selector));
        streaming.createStream(
            receiver,
            address(token),
            deposit,
            incorrectFlowRate,
            startTime,
            stopTime
        );
    }
}