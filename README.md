# Arbitrable Wrapped ERC20/721 tokens

Contract | Description
---------|----------------------------
[`Arbitrable`](contracts/Arbitrable.sol) | Basic arbitrable functionality. Constructor initializes arbitrator as contract creator. Provides function for arbitrator to select succeeding arbitrator.
[`IArbitrable`](contracts/IArbitrable.sol) | Interface specification for arbitrable contracts
[`Arbitrator`](contracts/Arbitrator.sol) | Basic arbitrator functionality. Provides functions to add/remove parent arbitrators and for them to invoke on behalf of the contract.
[`IArbitrator`](contracts/IArbitrator.sol) | Interface specification for arbitrator contracts.
[`ArbitrableWrappedERC20`](contracts/ArbitrableWrappedERC20.sol) | ERC20 wrapper into which anybody can deposit.<ul><li>Only the specified arbitrator can withdraw tokens from the wrapper (i.e. holders must make a case to the arbitrator to leave)</li><li>The arbitrator may move tokens between accounts as they decide.</li>
[`UniswapV2Helper`](contracts/UniswapV2Helper.sol) | Intermediary arbitrator layer that allows token holders access to liquidity outside the arbitrable jurisdiction
[`ArbitrableERC20LiquidityPool`](contracts/ArbitrableERC20LiquidityPool.sol) | Alternatively, arbitable ERC20 tokens could be swapped using a modified UniswapV2-style liquidity pool which always checks the token balances instead of maintaining reserve amounts in local state. This allows liquidity providers to keep their tokens inside the arbitrable jurisdiction while earning swap fees.

## Installation

```
$ git clone https://github.com/Ethereum-Social-Contract/arbitrable-wrappers.git
$ cd arbitrable-wrappers
$ yarn install
```

Download the `solc` compiler. This is used instead of `solc-js` because it is much faster. Binaries for other systems can be found in the [Ethereum foundation repository](https://github.com/ethereum/solc-bin/).
```
$ curl -o solc https://binaries.soliditylang.org/linux-amd64/solc-linux-amd64-v0.8.13+commit.abaa5c0e
$ chmod +x solc
```

## Testing Contracts

```
# Build contracts before running tests
$ yarn run build-test
$ yarn run build-dev

$ yarn test
```
