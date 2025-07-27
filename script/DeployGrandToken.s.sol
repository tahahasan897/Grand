// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {GrandToken} from "../src/GrandToken.sol";

contract DeployGrandTokenScript is Script {
    bytes32 private password = bytes32(0); // <-- Enter password address

    function run() public {
        vm.startBroadcast();

        GrandToken grandToken = new GrandToken(password);

        vm.stopBroadcast();

        console.log("GrandToken deployed to:", address(grandToken));
    }
}
