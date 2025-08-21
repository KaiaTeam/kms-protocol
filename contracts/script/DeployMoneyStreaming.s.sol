// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {MoneyStreaming} from "../src/MoneyStreaming.sol";

contract DeployMoneyStreamingScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address feeCollector = vm.envAddress("FEE_COLLECTOR");
        
        vm.startBroadcast(deployerPrivateKey);

        MoneyStreaming streaming = new MoneyStreaming(feeCollector);
        
        console2.log("MoneyStreaming deployed at:", address(streaming));
        console2.log("Fee collector set to:", feeCollector);
        console2.log("Platform fee rate:", streaming.platformFeeRate(), "/ 10000 (0.5%)");

        vm.stopBroadcast();
    }
}