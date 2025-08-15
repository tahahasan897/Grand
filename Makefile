# Foundry AI Governance Makefile
# Terminal shortcuts for deployment and monitoring

# Deployment commands
scripting-grand:
	@forge script script/DeployGrandToken.s.sol:DeployGrandTokenScript --rpc-url $(SEPOLIA_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv

scripting-wallet:
	@forge script script/DeploySmartAIWallet.s.sol:DeploySmartAIWalletScript --rpc-url $(SEPOLIA_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv

# Balance checking commands
wallet-balance:
	@cast call 0x681899504e8ec6265E68071DCf8EA021BCC95931 "balanceOf(address)" 0x00c5CfA3C21989c885962f9e2e6949f1524C34f1 --rpc-url $(SEPOLIA_URL) | cast --to-dec 

deployer-balance:
	@cast call 0x681899504e8ec6265E68071DCf8EA021BCC95931 "balanceOf(address)" 0xF60303B51a4BC5917a72558ab2a468eD839262A2 --rpc-url $(SEPOLIA_URL) | cast --to-dec 

total-supply:
	@cast call 0x681899504e8ec6265E68071DCf8EA021BCC95931 "totalSupply()" --rpc-url $(SEPOLIA_URL) | cast --to-dec 

total-released:
	@cast call 0x681899504e8ec6265E68071DCf8EA021BCC95931 "totalReleased()" --rpc-url $(SEPOLIA_URL) | cast --to-dec 

# Convenience commands
all-balances: wallet-balance deployer-balance total-supply total-released

# Extract the abi's from the /out directory
get-abi-wallet:
	jq '.abi' out/SmartAIWallet.sol/SmartAIWallet.json > SmartAIWallet_abi.json

get-abi-grand:
	jq '.abi' out/GrandToken.sol/GrandToken.json > Grand_abi.json

.PHONY: deploy-grand deploy-wallet wallet-balance deployer-balance total-supply total-released all-balances get-abi-wallet get-abi-grand
