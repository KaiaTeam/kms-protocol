// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {MoneyStreaming} from "../src/MoneyStreaming.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MoneyStreamingTest is Test {
    MoneyStreaming public streaming;
    ERC20Mock public token;
    
    address public sender = address(0x3);
    address public receiver = address(0x4);
    
    uint256 public constant DEPOSIT = 1000e18; // Amount to be streamed
    uint256 public constant FLOW_RATE = 10e18; // 10 tokens per second  
    uint256 public constant DURATION = 100; // 100 seconds
    
    
    function setUp() public {
        // Deploy mock ERC20 token
        token = new ERC20Mock();
        
        // Deploy MoneyStreaming contract
        streaming = new MoneyStreaming();
        
        // Mint tokens to sender (more for multiple tests)
        token.mint(sender, 100000e18); // 100,000 tokens for various tests
        
        // Approve streaming contract to spend tokens
        vm.prank(sender);
        token.approve(address(streaming), type(uint256).max);
    }
    
    function test_CreateStream() public {
        uint256 startTime = block.timestamp + 10;
        uint256 stopTime = startTime + DURATION;
        uint256 expectedFlowRate = DEPOSIT / DURATION;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            DEPOSIT,
            expectedFlowRate,
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
        assertEq(streamDeposit, DEPOSIT);
        assertEq(streamFlowRate, expectedFlowRate);
        assertEq(streamStartTime, startTime);
        assertEq(streamStopTime, stopTime);
        assertEq(remainingBalance, DEPOSIT);
        assertEq(withdrawnBalance, 0);
        assertTrue(isActive);
    }
    
    function test_StreamBalance() public {
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + DURATION;
        uint256 expectedFlowRate = DEPOSIT / DURATION;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            DEPOSIT,
            expectedFlowRate,
            startTime,
            stopTime
        );
        
        // Fast forward 50 seconds
        vm.warp(startTime + 50);
        
        uint256 expectedStreamed = expectedFlowRate * 50;
        uint256 receiverBalance = streaming.balanceOf(streamId, receiver);
        
        assertEq(receiverBalance, expectedStreamed);
    }
    
    function test_WithdrawFromStream() public {
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + DURATION;
        uint256 expectedFlowRate = DEPOSIT / DURATION;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            DEPOSIT,
            expectedFlowRate,
            startTime,
            stopTime
        );
        
        // Fast forward 50 seconds
        vm.warp(startTime + 50);
        
        uint256 initialBalance = token.balanceOf(receiver);
        uint256 expectedWithdraw = expectedFlowRate * 50;
        
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
        uint256 expectedFlowRate = DEPOSIT / DURATION;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            DEPOSIT,
            expectedFlowRate,
            startTime,
            stopTime
        );
        
        // Fast forward 30 seconds
        vm.warp(startTime + 30);
        
        vm.prank(sender);
        streaming.pauseStream(streamId);
        
        (,,,,,,, uint256 remainingBalance,, bool isActive) = streaming.getStream(streamId);
        
        assertFalse(isActive);
        
        uint256 expectedRemaining = DEPOSIT - (expectedFlowRate * 30);
        assertEq(remainingBalance, expectedRemaining);
    }
    
    function test_CancelStream() public {
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + DURATION;
        uint256 expectedFlowRate = DEPOSIT / DURATION;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            DEPOSIT,
            expectedFlowRate,
            startTime,
            stopTime
        );
        
        // Fast forward 30 seconds
        vm.warp(startTime + 30);
        
        uint256 senderInitialBalance = token.balanceOf(sender);
        uint256 receiverInitialBalance = token.balanceOf(receiver);
        
        vm.prank(sender);
        streaming.cancelStream(streamId);
        
        uint256 expectedReceived = expectedFlowRate * 30;
        uint256 expectedReturned = DEPOSIT - expectedReceived;
        
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
        uint256 expectedFlowRate = DEPOSIT / DURATION;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            DEPOSIT,
            expectedFlowRate,
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
        uint256 expectedFlowRate = DEPOSIT / DURATION;
        
        vm.prank(sender);
        uint256 streamId = streaming.createStream(
            receiver,
            address(token),
            DEPOSIT,
            expectedFlowRate,
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
    
}