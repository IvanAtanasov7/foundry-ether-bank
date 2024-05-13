// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {EtherBank} from "../src/EtherBank.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployEtherBank is Script {
    function run() external returns (EtherBank) {
        // Before startBroadcast -> Not a "real" tx
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        // After startBroadcast -> Real tx!
        vm.startBroadcast();
        EtherBank etherBank = new EtherBank(ethUsdPriceFeed);
        vm.stopBroadcast();
        return etherBank;
    }
}
