// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {SmartAIWallet} from "../src/SmartAIWallet.sol";
import {GrandToken} from "../src/GrandToken.sol";

contract DeploySmartAIWalletScript is Script {
    address private grandTokenContractAddress = 0xA5d0146ac093e25D557c13D399060C99F04B75fB;
    address private priceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address private aiWallet = 0x911de651a68F64b446716F56AF59cE5a0A2Bf381;
    address private deployer = 0xF60303B51a4BC5917a72558ab2a468eD839262A2; 

    GrandToken token = GrandToken(grandTokenContractAddress);

    function run() public {
        vm.startBroadcast();
        SmartAIWallet smartAIWallet = new SmartAIWallet(grandTokenContractAddress, priceFeed, aiWallet, 0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1);
        token.initialize(address(smartAIWallet), deployer); 
        vm.stopBroadcast();

        console.log("SmartAIWallet deployed to:", address(smartAIWallet));
    }
}