// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoneyStreaming is ReentrancyGuard, Ownable {
    struct Stream {
        address sender;
        address receiver;
        address token;
        uint256 deposit;
        uint256 flowRate; // wei per second
        uint256 startTime;
        uint256 stopTime;
        uint256 remainingBalance;
        uint256 withdrawnBalance;
        bool isActive;
    }
    
    mapping(uint256 => Stream) public streams;
    mapping(address => uint256[]) public senderStreams;
    mapping(address => uint256[]) public receiverStreams;
    
    uint256 public nextStreamId = 1;
    uint256 public platformFeeRate = 50; // 0.5% = 50/10000
    uint256 private constant FEE_DENOMINATOR = 10000;
    
    address public feeCollector;
    
    event StreamCreated(
        uint256 indexed streamId,
        address indexed sender,
        address indexed receiver,
        address token,
        uint256 deposit,
        uint256 flowRate,
        uint256 startTime,
        uint256 stopTime
    );
    
    event StreamPaused(uint256 indexed streamId, address indexed sender);
    event StreamResumed(uint256 indexed streamId, address indexed sender);
    event StreamCanceled(uint256 indexed streamId, address indexed sender, uint256 senderBalance, uint256 receiverBalance);
    event Withdrawal(uint256 indexed streamId, address indexed receiver, uint256 amount);
    
    error StreamNotFound();
    error NotAuthorized();
    error StreamNotActive();
    error InvalidStreamParams();
    error InsufficientDeposit();
    error WithdrawFailed();
    error InvalidFlowRate();
    
    constructor(address _feeCollector) Ownable(msg.sender) {
        feeCollector = _feeCollector;
    }
    
    function createStream(
        address receiver,
        address token,
        uint256 deposit,
        uint256 flowRate,
        uint256 startTime,
        uint256 stopTime
    ) external returns (uint256) {
        if (receiver == address(0) || token == address(0)) revert InvalidStreamParams();
        if (deposit == 0 || flowRate == 0) revert InvalidStreamParams();
        if (startTime >= stopTime || startTime < block.timestamp) revert InvalidStreamParams();
        
        uint256 duration = stopTime - startTime;
        
        // Calculate platform fee from deposit amount
        uint256 platformFee = (deposit * platformFeeRate) / FEE_DENOMINATOR;
        uint256 netAmount = deposit - platformFee;
        
        // Verify that the provided flowRate matches the net amount and duration
        uint256 expectedFlowRate = netAmount / duration;
        if (flowRate != expectedFlowRate) revert InvalidFlowRate();
        
        // Basic deposit validation
        if (deposit == 0 || netAmount == 0) revert InsufficientDeposit();
        
        // Transfer deposit from sender
        IERC20(token).transferFrom(msg.sender, address(this), deposit);
        
        // Transfer platform fee to fee collector
        IERC20(token).transfer(feeCollector, platformFee);
        
        uint256 streamId = nextStreamId++;
        
        streams[streamId] = Stream({
            sender: msg.sender,
            receiver: receiver,
            token: token,
            deposit: netAmount, // Store the net streaming amount
            flowRate: flowRate,
            startTime: startTime,
            stopTime: stopTime,
            remainingBalance: netAmount,
            withdrawnBalance: 0,
            isActive: true
        });
        
        senderStreams[msg.sender].push(streamId);
        receiverStreams[receiver].push(streamId);
        
        emit StreamCreated(streamId, msg.sender, receiver, token, deposit, flowRate, startTime, stopTime);
        
        return streamId;
    }
    
    function pauseStream(uint256 streamId) external {
        Stream storage stream = streams[streamId];
        if (stream.sender == address(0)) revert StreamNotFound();
        if (msg.sender != stream.sender) revert NotAuthorized();
        if (!stream.isActive) revert StreamNotActive();
        
        // Update remaining balance to current point
        uint256 elapsed = _calculateElapsedTime(streamId);
        uint256 streamed = elapsed * stream.flowRate;
        
        if (streamed > stream.remainingBalance) {
            streamed = stream.remainingBalance;
        }
        
        stream.remainingBalance -= streamed;
        stream.stopTime = block.timestamp;
        stream.isActive = false;
        
        emit StreamPaused(streamId, msg.sender);
    }
    
    function resumeStream(uint256 streamId, uint256 newStopTime) external {
        Stream storage stream = streams[streamId];
        if (stream.sender == address(0)) revert StreamNotFound();
        if (msg.sender != stream.sender) revert NotAuthorized();
        if (stream.isActive) revert StreamNotActive();
        if (newStopTime <= block.timestamp) revert InvalidStreamParams();
        
        stream.stopTime = newStopTime;
        stream.isActive = true;
        
        emit StreamResumed(streamId, msg.sender);
    }
    
    function cancelStream(uint256 streamId) external nonReentrant {
        Stream storage stream = streams[streamId];
        if (stream.sender == address(0)) revert StreamNotFound();
        if (msg.sender != stream.sender && msg.sender != stream.receiver) revert NotAuthorized();
        
        uint256 senderBalance;
        uint256 receiverBalance;
        
        if (stream.isActive && block.timestamp < stream.stopTime) {
            uint256 elapsed = _calculateElapsedTime(streamId);
            uint256 streamed = elapsed * stream.flowRate;
            
            if (streamed > stream.remainingBalance) {
                streamed = stream.remainingBalance;
            }
            
            receiverBalance = streamed;
            senderBalance = stream.remainingBalance - streamed;
        } else {
            // Stream ended naturally or was already paused
            receiverBalance = stream.deposit - stream.remainingBalance;
            senderBalance = stream.remainingBalance;
        }
        
        // Transfer balances
        if (receiverBalance > 0) {
            IERC20(stream.token).transfer(stream.receiver, receiverBalance);
        }
        if (senderBalance > 0) {
            IERC20(stream.token).transfer(stream.sender, senderBalance);
        }
        
        // Mark stream as inactive
        stream.isActive = false;
        stream.remainingBalance = 0;
        
        emit StreamCanceled(streamId, stream.sender, senderBalance, receiverBalance);
    }
    
    function withdrawFromStream(uint256 streamId) external nonReentrant {
        Stream storage stream = streams[streamId];
        if (stream.sender == address(0)) revert StreamNotFound();
        if (msg.sender != stream.receiver) revert NotAuthorized();
        
        uint256 withdrawable = balanceOf(streamId, stream.receiver);
        if (withdrawable == 0) revert WithdrawFailed();
        
        // Update withdrawn balance
        stream.withdrawnBalance += withdrawable;
        
        // Transfer to receiver
        IERC20(stream.token).transfer(stream.receiver, withdrawable);
        
        emit Withdrawal(streamId, stream.receiver, withdrawable);
    }
    
    function balanceOf(uint256 streamId, address account) public view returns (uint256) {
        Stream storage stream = streams[streamId];
        if (stream.sender == address(0)) return 0;
        
        if (account == stream.receiver) {
            if (!stream.isActive || block.timestamp <= stream.startTime) {
                return 0;
            }
            
            uint256 elapsed = _calculateElapsedTime(streamId);
            uint256 streamed = elapsed * stream.flowRate;
            
            if (streamed > stream.deposit) {
                streamed = stream.deposit;
            }
            
            // Return available amount minus what has already been withdrawn
            if (streamed > stream.withdrawnBalance) {
                return streamed - stream.withdrawnBalance;
            }
            
            return 0;
        }
        
        if (account == stream.sender) {
            uint256 elapsed = _calculateElapsedTime(streamId);
            uint256 streamed = elapsed * stream.flowRate;
            
            if (streamed > stream.deposit) {
                streamed = stream.deposit;
            }
            
            return stream.deposit - streamed;
        }
        
        return 0;
    }
    
    function getStream(uint256 streamId) external view returns (
        address sender,
        address receiver,
        address token,
        uint256 deposit,
        uint256 flowRate,
        uint256 startTime,
        uint256 stopTime,
        uint256 remainingBalance,
        uint256 withdrawnBalance,
        bool isActive
    ) {
        Stream storage stream = streams[streamId];
        return (
            stream.sender,
            stream.receiver,
            stream.token,
            stream.deposit,
            stream.flowRate,
            stream.startTime,
            stream.stopTime,
            stream.remainingBalance,
            stream.withdrawnBalance,
            stream.isActive
        );
    }
    
    function getSenderStreams(address sender) external view returns (uint256[] memory) {
        return senderStreams[sender];
    }
    
    function getReceiverStreams(address receiver) external view returns (uint256[] memory) {
        return receiverStreams[receiver];
    }
    
    function _calculateElapsedTime(uint256 streamId) internal view returns (uint256) {
        Stream storage stream = streams[streamId];
        
        if (block.timestamp <= stream.startTime) {
            return 0;
        }
        
        uint256 endTime = stream.isActive ? 
            (block.timestamp > stream.stopTime ? stream.stopTime : block.timestamp) : 
            stream.stopTime;
        
        return endTime - stream.startTime;
    }
    
    function setPlatformFeeRate(uint256 newFeeRate) external onlyOwner {
        require(newFeeRate <= 1000, "Fee rate cannot exceed 10%"); // Max 10%
        platformFeeRate = newFeeRate;
    }
    
    function setFeeCollector(address newFeeCollector) external onlyOwner {
        require(newFeeCollector != address(0), "Invalid fee collector");
        feeCollector = newFeeCollector;
    }
    
    // USDT specific utility functions
    function createStreamUSDT(
        address receiver,
        address usdtToken,
        uint256 totalUSDTAmount,    // Amount in USDT (e.g., 1000 for $1000)
        uint256 durationInSeconds
    ) external returns (uint256) {
        require(IERC20Metadata(usdtToken).decimals() == 6, "Token must have 6 decimals (USDT)");
        
        uint256 netAmount = totalUSDTAmount * 10**6; // Convert to 6 decimal places (this is what user wants to stream)
        uint256 platformFee = (netAmount * platformFeeRate) / FEE_DENOMINATOR;
        uint256 deposit = netAmount + platformFee; // Total amount user needs to deposit
        uint256 flowRate = netAmount / durationInSeconds; // Flow rate based on net amount
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + durationInSeconds;
        
        // Transfer deposit from sender
        IERC20(usdtToken).transferFrom(msg.sender, address(this), deposit);
        
        // Transfer platform fee to fee collector
        IERC20(usdtToken).transfer(feeCollector, platformFee);
        
        uint256 streamId = nextStreamId++;
        
        streams[streamId] = Stream({
            sender: msg.sender,
            receiver: receiver,
            token: usdtToken,
            deposit: netAmount, // Store net amount (without platform fee)
            flowRate: flowRate,
            startTime: startTime,
            stopTime: stopTime,
            remainingBalance: netAmount,
            withdrawnBalance: 0,
            isActive: true
        });
        
        senderStreams[msg.sender].push(streamId);
        receiverStreams[receiver].push(streamId);
        
        emit StreamCreated(streamId, msg.sender, receiver, usdtToken, deposit, flowRate, startTime, stopTime);
        
        return streamId;
    }
    
    function createStreamUSDTWithDetails(
        address receiver,
        address usdtToken,
        uint256 totalUSDTAmount,    // Amount in USDT (e.g., 1000 for $1000)
        uint256 startTime,
        uint256 stopTime
    ) external returns (uint256) {
        require(IERC20Metadata(usdtToken).decimals() == 6, "Token must have 6 decimals (USDT)");
        require(stopTime > startTime, "Invalid time range");
        
        uint256 netAmount = totalUSDTAmount * 10**6; // Convert to 6 decimal places (this is what user wants to stream)
        uint256 platformFee = (netAmount * platformFeeRate) / FEE_DENOMINATOR;
        uint256 deposit = netAmount + platformFee; // Total amount user needs to deposit
        uint256 duration = stopTime - startTime;
        uint256 flowRate = netAmount / duration; // Flow rate based on net amount
        
        // Transfer deposit from sender
        IERC20(usdtToken).transferFrom(msg.sender, address(this), deposit);
        
        // Transfer platform fee to fee collector
        IERC20(usdtToken).transfer(feeCollector, platformFee);
        
        uint256 streamId = nextStreamId++;
        
        streams[streamId] = Stream({
            sender: msg.sender,
            receiver: receiver,
            token: usdtToken,
            deposit: netAmount, // Store net amount (without platform fee)
            flowRate: flowRate,
            startTime: startTime,
            stopTime: stopTime,
            remainingBalance: netAmount,
            withdrawnBalance: 0,
            isActive: true
        });
        
        senderStreams[msg.sender].push(streamId);
        receiverStreams[receiver].push(streamId);
        
        emit StreamCreated(streamId, msg.sender, receiver, usdtToken, deposit, flowRate, startTime, stopTime);
        
        return streamId;
    }
    
    // Get human-readable USDT balance (e.g., returns 1500 for $1500)
    function getUSDTBalance(uint256 streamId, address account) external view returns (uint256) {
        uint256 balance = balanceOf(streamId, account);
        return balance / 10**6; // Convert from 6 decimal places to human readable
    }
    
    // Get detailed USDT stream info with human-readable amounts
    function getUSDTStreamInfo(uint256 streamId) external view returns (
        address sender,
        address receiver,
        address token,
        uint256 totalUSDTAmount,      // Human readable total amount
        uint256 usdtPerSecond,        // Human readable flow rate per second
        uint256 startTime,
        uint256 stopTime,
        uint256 remainingUSDT,        // Human readable remaining amount
        uint256 withdrawnUSDT,        // Human readable withdrawn amount
        bool isActive
    ) {
        (
            address streamSender,
            address streamReceiver,
            address streamToken,
            uint256 deposit,
            uint256 flowRate,
            uint256 streamStartTime,
            uint256 streamStopTime,
            uint256 remainingBalance,
            uint256 withdrawnBalance,
            bool streamIsActive
        ) = (
            streams[streamId].sender,
            streams[streamId].receiver,
            streams[streamId].token,
            streams[streamId].deposit,
            streams[streamId].flowRate,
            streams[streamId].startTime,
            streams[streamId].stopTime,
            streams[streamId].remainingBalance,
            streams[streamId].withdrawnBalance,
            streams[streamId].isActive
        );
        
        return (
            streamSender,
            streamReceiver,
            streamToken,
            deposit / 10**6,          // Convert to human readable
            flowRate / 10**6,         // Convert to human readable (USDT per second)
            streamStartTime,
            streamStopTime,
            remainingBalance / 10**6, // Convert to human readable
            withdrawnBalance / 10**6, // Convert to human readable
            streamIsActive
        );
    }
}