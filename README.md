## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

Create a ```.env``` file and store:

```shell
SEPOLIA_URL=
PRIVATE_KEY=
```

Fill in the ```password``` variable in ```DeployGrandToken.s.sol```. And run in the terminal:

```shell
$ forge script script/DeployGrandToken.s.sol:DeployGrandTokenScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

Copy the address of the contract, and fill in the parameters in ```DeploySmartAIWallet.s.sol```. And run:

```shell
$ forge script script/DeployGrandToken.s.sol:DeployGrandTokenScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
