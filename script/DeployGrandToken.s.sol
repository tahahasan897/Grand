// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {GrandToken} from "../src/GrandToken.sol";

contract DeployGrandTokenScript is Script {

    function run() public {
        vm.startBroadcast();

        GrandToken grandToken = new GrandToken(0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1);

        vm.stopBroadcast();

        console.log("GrandToken deployed to:", address(grandToken));
    }
}