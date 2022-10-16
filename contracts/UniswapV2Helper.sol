// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./deps/IERC20.sol";
import "./deps/SafeERC20.sol";
import "./Arbitrator.sol";

using SafeERC20 for IArbitrableWrappedERC20;
using SafeERC20 for IERC20;

interface IChainlinkFeed {
  function latestAnswer() external view returns(uint256);
  function decimals() external view returns(uint8);
}

interface IUniswapV2Pair {
  function token0() external view returns(address);
  function token1() external view returns(address);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IArbitrableWrappedERC20 is IERC20 {
  function baseToken() external view returns (address);
  function mintTo(address user, uint amount) external;
  function burnFrom(address user, address recipient, uint amount) external;
}

error InvalidSlippage();
error FeedMismatch();
error PoolMismatch();

// Allow special access to a protocol that is not within arbitrable jurisdiction
//  by creating a layer that can be utilized by an arbitrator.
// TODO support swap route through multiple pools at once
// TODO support this helper as a parentArbitrator instead of an intermediary layer?
contract UniswapV2Helper is Arbitrator {
  string public contactURI = "Refer to parent, this is only capability layer";
  IChainlinkFeed public inputPriceFeed;
  IChainlinkFeed public outputPriceFeed;
  IUniswapV2Pair public liquidityPool;
  IArbitrableWrappedERC20 public inputToken;
  IArbitrableWrappedERC20 public outputToken;
  bool public inputIsToken0;

  uint public slippageNumerator;
  uint public slippageDenominator;

  constructor(
    IChainlinkFeed _inputPriceFeed,
    IChainlinkFeed _outputPriceFeed,
    IUniswapV2Pair _liquidityPool,
    address _inputToken,
    address _outputToken,
    uint _slippageNumerator,
    uint _slippageDenominator
  ) {
    _addParent(msg.sender);
    slippageNumerator = _slippageNumerator;
    slippageDenominator = _slippageDenominator;
    if(slippageNumerator > slippageDenominator) revert InvalidSlippage();
    inputPriceFeed = _inputPriceFeed;
    outputPriceFeed = _outputPriceFeed;
    if(inputPriceFeed.decimals() != outputPriceFeed.decimals()) revert FeedMismatch();

    liquidityPool = _liquidityPool;
    inputToken = IArbitrableWrappedERC20(_inputToken);
    outputToken = IArbitrableWrappedERC20(_outputToken);
    address token0 = liquidityPool.token0();
    address token1 = liquidityPool.token1();
    address inputBase = inputToken.baseToken();
    address outputBase = outputToken.baseToken();
    if(!((token0 == inputBase && token1 == outputBase) ||
      (token1 == inputBase && token0 == outputBase)))
        revert PoolMismatch();

    if(token0 == _inputToken) {
      inputIsToken0 = true;
    }
  }

  function swap(address recipient, uint amountIn) external {
    uint minOut =
      (amountIn * inputPriceFeed.latestAnswer() * slippageNumerator)
      / (outputPriceFeed.latestAnswer() * slippageDenominator);

    uint8 inputDecimals = inputToken.decimals();
    uint8 outputDecimals = outputToken.decimals();
    if(inputDecimals > outputDecimals) {
      minOut /= 10**(inputDecimals - outputDecimals);
    } else if(inputDecimals < outputDecimals) {
      minOut *= 10**(inputDecimals - outputDecimals);
    }

    inputToken.burnFrom(msg.sender, address(liquidityPool), amountIn);
    if(inputIsToken0) {
      liquidityPool.swap(0, minOut, address(this), "");
    } else {
      liquidityPool.swap(minOut, 0, address(this), "");
    }
    IERC20 outputBaseToken = IERC20(outputToken.baseToken());
    uint outputBalance = outputBaseToken.balanceOf(address(this));
    require(outputBalance >= minOut);
    outputToken.mintTo(recipient, outputBalance);
  }

}
