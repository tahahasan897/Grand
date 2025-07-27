// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {SmartAIWallet} from "../src/SmartAIWallet.sol";
import {GrandToken} from "../src/GrandToken.sol";

contract DeploySmartAIWalletScript is Script {
    // ====== USER PARAMETERS ======
    // Fill in your own parameters below before running the script

    address private grandTokenContractAddress = address(0); // <-- Enter GrandToken contract address
    address private priceFeed = address(0); // <-- Enter Chainlink price feed address
    address private aiWallet = address(0); // <-- Enter AI wallet address
    address private deployer = address(0); // <-- Enter deployer address
    bytes32 private password = bytes32(0); // <-- Enter password address

    // ============================

    function run() public {
        require(grandTokenContractAddress != address(0), "Set grandTokenContractAddress");
        require(priceFeed != address(0), "Set priceFeed");
        require(aiWallet != address(0), "Set aiWallet");
        require(deployer != address(0), "Set deployer");

        vm.startBroadcast();
        SmartAIWallet smartAIWallet = new SmartAIWallet(grandTokenContractAddress, priceFeed, aiWallet, password);
        GrandToken token = GrandToken(grandTokenContractAddress);
        token.initialize(address(smartAIWallet), deployer);
        vm.stopBroadcast();

        console.log("SmartAIWallet deployed to:", address(smartAIWallet));
    }
}
