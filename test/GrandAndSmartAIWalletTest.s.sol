// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {GrandToken} from "../src/GrandToken.sol";
import {SmartAIWallet} from "../src/SmartAIWallet.sol";
import {MockV3Aggregator} from "./mocks/mockAggregatorV3Interface.sol";

contract GrandAndSmartAIWalletTest is Test {
    event MintingHappened(uint256 amount);
    event BurningHappened(uint256 amount);
    event CirculationMigrated(address indexed from, address indexed to, uint256 amount);

    GrandToken grandToken;
    SmartAIWallet smartAIWallet;
    MockV3Aggregator mockFeed;

    address private aiWallet = address(0); // Required to input a MetaMask wallet address
    address private myWallet = address(0); // Required to input a MetaMask wallet address
    bytes32 private password = bytes32(0); // Required to input a hashed keccak256 password

    // Deploying contracts in this setUp function
    function setUp() external {
        require(aiWallet != address(0), "Please, input a MetaMask wallet"); 
        require(myWallet != address(0), "Please, input a MetaMask wallet");
        require(password != bytes32(0), "Please, input a password");

        // Creates a mock for a pricefeed. 
        mockFeed = new MockV3Aggregator(123e8);
        grandToken = new GrandToken(password);
        vm.prank(myWallet);
        smartAIWallet = new SmartAIWallet(
            address(grandToken),
            address(mockFeed),
            aiWallet,
            password
        );

        grandToken.initialize(address(smartAIWallet), myWallet);
    }

    // Testing the setUp function by assertEq(), etc..
    function testFromGrandTokenOfAiControllerIsAiWallet() public view {
        assertEq(grandToken.aiController(), address(smartAIWallet));
    }

    function testFromGrandTokenOfDeployerIsMyWallet() public view {
        assertEq(grandToken.deployer(), myWallet);
    }

    function testFromGrandTokenOfInitialSupply() public view {
        // Check that the initial supply is assigned to the deployer
        assertEq(grandToken.INITIAL_SUPPLY(), 1_000_000 * 1e18);
    }

    function testFromGrandTokenOfCirculatingCap() public view {
        // Check that the circulating cap is set correctly
        assertEq(grandToken.CIRCULATING_CAP(), 250000000000000000000000);
    }

    function testFromGrandTokenOfTotalReleased() public view {
        // Check that total released equals initial supply at deployment
        assertEq(grandToken.totalReleased(), grandToken.INITIAL_SUPPLY() / 4);
    }

    function testFromGrandTokenOfAdjustSupplyThatIsNotAI() public {
        // Try to adjust supply from a non-AI address, should revert
        vm.prank(myWallet);
        vm.expectRevert();
        grandToken.adjustSupply(1);
    }

    function testFromGrandTokenOfAdjustSupplyWithAI() public {
        // Adjust supply as AI controller, should succeed
        uint256 treasury = grandToken.balanceOf(address(smartAIWallet));
        uint256 deployerBalance = grandToken.balanceOf(myWallet);

        uint256 supplySubtractedFromAIWallet = treasury - 10000 * 1e18;
        uint256 supplyAddedToDeployerWallet = deployerBalance + 10000 * 1e18;

        int256 additional = 10000000000000000;

        vm.prank(address(smartAIWallet));
        grandToken.adjustSupply(additional);
        assertEq(grandToken.balanceOf(address(smartAIWallet)), supplySubtractedFromAIWallet);
        assertEq(grandToken.balanceOf(myWallet), supplyAddedToDeployerWallet);
        assertEq(grandToken.totalReleased(), supplyAddedToDeployerWallet);
    }

    function testFromGrandTokenOfAdjustSupplyByNotAI() public {
        vm.prank(myWallet);
        vm.expectRevert();
        grandToken.adjustSupply(int256(1));
    }

    function testFromGrandTokenOfAdjustSupplyByAIButWhenTreasuryDoesNotHaveEnoughFundsToTransferTowardsDeployerSoItMints(
    ) public {
        // Make the treasury balance low by inserting into the AdjustSupply functinon a factor that is close enough to send most of the treasury balance towards the deployer
        uint256 treasury = grandToken.balanceOf(address(smartAIWallet));
        uint256 deployerBalance = grandToken.balanceOf(myWallet);
        assertEq(treasury, 750000 * 1e18);
        assertEq(deployerBalance, 250000 * 1e18);

        // The treasury is around 250 000 tokens
        vm.prank(address(smartAIWallet));
        grandToken.adjustSupply(int256(0.5e18));
        assertEq(grandToken.balanceOf(address(smartAIWallet)), 250000 * 1e18);

        // the factor is now set greater than the treasury balance
        vm.prank(address(smartAIWallet));
        vm.expectEmit(false, false, false, true);
        grandToken.adjustSupply(int256(0.5e18));
        // Transfer the rest of the treasury balance to the deployer
        emit MintingHappened(250000 * 1e18);

        assertEq(grandToken.balanceOf(myWallet), 1125000 * 1e18);
        assertEq(grandToken.balanceOf(address(smartAIWallet)), 125000 * 1e18);
    }

    function testFromGrandTokenOfAdjustSupplyByAIWhenItsBurning() public {
        uint256 treasury = grandToken.balanceOf(address(smartAIWallet));
        uint256 deployerBalance = grandToken.balanceOf(myWallet);
        assertEq(treasury, 750000 * 1e18);
        assertEq(deployerBalance, 250000 * 1e18);

        vm.prank(address(smartAIWallet));
        vm.expectEmit(false, false, false, true);
        emit BurningHappened(10000 * 1e18);
        grandToken.adjustSupply(int256(-0.01e18)); // Burn 1% of the total supply

        assertEq(grandToken.balanceOf(address(smartAIWallet)), 742500 * 1e18);
        assertEq(grandToken.balanceOf(myWallet), 247500 * 1e18);
    }

    function testFromGrandTokenOfAdjustSupplyByAIWhenTreasuryDoNotHaveEnoughFundsToBurn() public {
        uint256 treasury = grandToken.balanceOf(address(smartAIWallet));
        uint256 deployerBalance = grandToken.balanceOf(myWallet);
        assertEq(treasury, 750000 * 1e18);
        assertEq(deployerBalance, 250000 * 1e18);

        vm.prank(address(smartAIWallet));
        vm.expectEmit(false, false, false, true);
        emit BurningHappened(750000 * 1e18);
        grandToken.adjustSupply(int256(-0.75e18)); // Burn 75% of the total supply
        assertEq(grandToken.balanceOf(address(smartAIWallet)), 187500 * 1e18);
        assertEq(grandToken.balanceOf(address(myWallet)), 62500 * 1e18); 

        vm.prank(address(smartAIWallet));
        vm.expectEmit(false, false, false, true);
        emit BurningHappened(187500 * 1e18);
        grandToken.adjustSupply(int256(-0.75e18)); // Try to burn
        assertEq(grandToken.balanceOf(address(smartAIWallet)), 46875 * 1e18); 
        assertEq(grandToken.balanceOf(address(myWallet)), 15625 * 1e18); 
    }

    function testFromGrandTokenInitializeFunction() public {
        // Create new GrandToken and SmartAIWallet contracts
        GrandToken newGrandToken = new GrandToken(0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1);
        SmartAIWallet newSmartAIWallet = new SmartAIWallet(
            address(newGrandToken),
            address(mockFeed),
            aiWallet,
            0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1
        );

        newGrandToken.initialize(address(newSmartAIWallet), myWallet);

        vm.expectRevert("Already initialized");
        newGrandToken.initialize(address(newSmartAIWallet), myWallet);
        assertEq(newGrandToken.aiController(), address(newSmartAIWallet));
        assertEq(newGrandToken.deployer(), myWallet);
    }

    function testFromGrandTokenMigrationFunction() public {
        // Create new GrandToken and SmartAIWallet contracts
        GrandToken newGrandToken = new GrandToken(0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1);
        SmartAIWallet newSmartAIWallet = new SmartAIWallet(
            address(newGrandToken),
            address(mockFeed),
            aiWallet,
            0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1
        );
        newGrandToken.initialize(address(newSmartAIWallet), myWallet);
        uint256 amount = newGrandToken.balanceOf(myWallet);

        // Create a dummy address for migration
        address dummyAddress = address(0x1234567890AbcdEF1234567890aBcdef12345678);

        vm.expectEmit(true, true, false, true);
        emit CirculationMigrated(dummyAddress, dummyAddress, amount);
        newGrandToken.migrateCirculation(dummyAddress, "jel");
        assertEq(newGrandToken.balanceOf(dummyAddress), newGrandToken.INITIAL_SUPPLY() / 4);
        assertEq(newGrandToken.deployer(), dummyAddress);
    }

    function testFromGrandTokenMigrationFunctionWithRevert() public {
        // Create new GrandToken and SmartAIWallet contracts
        GrandToken newGrandToken = new GrandToken(0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1);
        SmartAIWallet newSmartAIWallet = new SmartAIWallet(
            address(newGrandToken),
            address(mockFeed),
            aiWallet,
            0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1
        );
        newGrandToken.initialize(address(newSmartAIWallet), myWallet);

        // Create a dummy address for migration
        address dummyAddress = address(0x1234567890AbcdEF1234567890aBcdef12345678);

        vm.expectRevert("Incorrect password");
        newGrandToken.migrateCirculation(dummyAddress, "melon");
    }

    function testFromSmartAIWalletOfDeployerIsIncludedInOwnersArray() public view {
        address[] memory owners = smartAIWallet.getOwners();
        bool found = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == myWallet) {
                found = true;
                break;
            }
        }
        assertTrue(found);
    }

    function testFromSmartAIWalletOfIGrandTokenAddress() public view {
        assertEq(address(smartAIWallet.getGrandToken()), address(grandToken));
    }

    function testFromSmartAIWalletOfMINIMUM_USDIsFiveDollars() public view {
        assertEq(smartAIWallet.MINIMUM_USD(), 5 * 1e18);
    }

    function testFromSmartAIWalletOfPriceFeedIsWorking() public view {
        // Just check that price feed returns a nonzero value
        int256 price = smartAIWallet.getLatestPrice();
        console.log(price);
        assertGt(price, 0);
    }

    function testFromSmartAIWalletOfAddOwnerIsWorkingFromBothScenarios() public {
        address newOwner = address(0x1234);
        // Only owner can add
        vm.prank(myWallet);
        smartAIWallet.addOwner(newOwner);
        assertTrue(smartAIWallet.isOwner(newOwner));

        // Non-owner cannot add
        address attacker = address(0x5678);
        vm.prank(attacker);
        vm.expectRevert();
        smartAIWallet.addOwner(address(0x9999));
    }

    function testFromSmartAIWalletOfRemoveOwnerIsWorkingFromBothScenarios() public {
        address newOwner = address(0x1234);
        vm.prank(myWallet);
        smartAIWallet.addOwner(newOwner);

        // Only owner can remove
        vm.prank(myWallet);
        smartAIWallet.removeOwner(newOwner);
        assertFalse(smartAIWallet.isOwner(newOwner));

        // Non-owner cannot remove
        address attacker = address(0x5678);
        vm.prank(attacker);
        vm.expectRevert();
        smartAIWallet.removeOwner(address(this));
    }

    function testFromSmartAIWalletOfReadSupply() public view {
        assertEq(smartAIWallet.readSupply(), grandToken.totalSupply());
    }

    function testFromSmartAIWalletOfAdjustSupplyFromSmartAIWalletThatWillRevert() public {
        // Only AI controller can call adjustSupply
        int256 additional = 1;

        vm.prank(aiWallet);
        vm.warp(block.timestamp + 1 weeks);
        vm.expectRevert();
        smartAIWallet.adjustSupply(additional);
    }

    function testFromSmartAIWalletMigrateTreasury() public {
        // Create new GrandToken and SmartAIWallet contracts
        GrandToken newGrandToken = new GrandToken(0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1);
        SmartAIWallet newSmartAIWallet = new SmartAIWallet(
            address(newGrandToken),
            address(mockFeed),
            aiWallet,
            0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1
        );
        newGrandToken.initialize(address(newSmartAIWallet), myWallet);

        // Create a dummy address for migration
        address dummyAddress = address(0x1234567890AbcdEF1234567890aBcdef12345678);
        newSmartAIWallet.migrateTreasury(dummyAddress, "jel");

        assertEq(newGrandToken.balanceOf(address(newSmartAIWallet)), 0);
        assertEq(newGrandToken.balanceOf(dummyAddress), 250000 * 1e18 * 3);
    }

    function testFromSmartAIWalletMigrateOnlyAI() public {
        // Create new GrandToken and SmartAIWallet contracts
        GrandToken newGrandToken = new GrandToken(0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1);
        SmartAIWallet newSmartAIWallet = new SmartAIWallet(
            address(newGrandToken),
            address(mockFeed),
            aiWallet,
            0xeaae0a8c82976772c4b292bceb8f77e4f94a1ef178895cebb27e3d5d4edfe5a1
        );
        newGrandToken.initialize(address(newSmartAIWallet), myWallet);

        // Create a dummy address for migration
        address dummyAddress = address(0x1234567890AbcdEF1234567890aBcdef12345678);
        newSmartAIWallet.migrateOnlyAI(dummyAddress, "jel");

        assertEq(newSmartAIWallet.aiController(), dummyAddress);
    }

    function testFromSmartAIWalletFund() public {
        // Fund the SmartAIWallet
        address dummyAddress = address(0x1234567890AbcdEF1234567890aBcdef12345678);
        vm.deal(dummyAddress, 10 ether);

        vm.prank(dummyAddress);
        smartAIWallet.fund{value: 0.1 ether}();

        assertEq(address(smartAIWallet).balance, 0.1 ether);
    }

    function testFromSmartAIWalletWithdraw() public {
        // Fund the SmartAIWallet
        address dummyAddress = address(0x1234567890AbcdEF1234567890aBcdef12345678);
        vm.deal(dummyAddress, 10 ether);

        vm.prank(dummyAddress);
        smartAIWallet.fund{value: 0.1 ether}();
        assertEq(address(smartAIWallet).balance, 0.1 ether);

        vm.prank(myWallet);
        smartAIWallet.withdraw();
        assertEq(address(smartAIWallet).balance, 0);
    }
}
