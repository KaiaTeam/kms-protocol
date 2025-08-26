// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {MoneyStreaming} from "../src/MoneyStreaming.sol";

contract DeployMoneyStreamingScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        MoneyStreaming streaming = new MoneyStreaming();
        
        console2.log("MoneyStreaming deployed at:", address(streaming));

        vm.stopBroadcast();
    }
}