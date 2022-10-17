// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../contracts/deps/ERC20.sol";
import "../../contracts/deps/IERC20.sol";
import "../../contracts/deps/SafeERC20.sol";

using SafeERC20 for IERC20;

error DepositTooSmall();
error InsufficientBalance();

// Same as contracts/ArbitrableERC20LiquidityPool.sol but
//  it doesn't care that the tokens are arbitrable
//   and it keeps the reserve amounts in local state
contract UniswapV2StyleLiquidityPool is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  IERC20[2] public tokens;
  uint[2] public reserves;
  // 0-0xffffffff: 0-100%
  uint32 public swapFee;

  uint public constant MINIMUM_DEPOSIT = 10**3;

  uint private unlocked = 1;
  modifier lock() {
    require(unlocked == 1, 'LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  event Swap(uint amount0Out, uint amount1Out, address to, bytes data);

  constructor(
    address token0Addr,
    address token1Addr,
    uint32 _swapFee,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) {
    tokens[0] = IERC20(token0Addr);
    tokens[1] = IERC20(token1Addr);
    swapFee = _swapFee;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  function token0() external view returns(address) {
    return address(tokens[0]);
  }

  function token1() external view returns(address) {
    return address(tokens[1]);
  }

  function getReserves() public view returns(uint[2] memory) {
    return reserves;
  }

  function deposit(uint amount0, uint amount1) external lock returns(uint liquidity) {
    if(amount0 < MINIMUM_DEPOSIT || amount1 < MINIMUM_DEPOSIT)
      revert DepositTooSmall();

    uint amount0ToTake;
    uint amount1ToTake;
    if(reserves[0] == 0 || reserves[1] == 0) {
      // First deposit, allow any ratio
      amount0ToTake = amount0;
      amount1ToTake = amount1;
    } else {
      // Use input amounts as maximum in current reserve ratio
      amount0ToTake = (amount1 * reserves[0]) / reserves[1];
      amount1ToTake = amount1;
      if(amount0ToTake > amount0) {
        amount0ToTake = amount0;
        amount1ToTake = (amount0 * reserves[1]) / reserves[0];
      }
    }
    reserves[0] += amount0ToTake;
    reserves[1] += amount1ToTake;
    liquidity = sqrt(amount0ToTake * amount1ToTake);
    _mint(msg.sender, liquidity);
    tokens[0].safeTransferFrom(msg.sender, address(this), amount0ToTake);
    tokens[1].safeTransferFrom(msg.sender, address(this), amount1ToTake);
  }

  function withdraw(uint liquidity) external lock returns(uint amount0, uint amount1) {
    require(balanceOf[msg.sender] >= liquidity);

    amount0 = (liquidity * reserves[0]) / totalSupply;
    amount1 = (liquidity * reserves[1]) / totalSupply;
    reserves[0] -= amount0;
    reserves[1] -= amount1;

    balanceOf[msg.sender] -= liquidity;
    totalSupply -= liquidity;
    emit Transfer(msg.sender, address(0), liquidity);

    tokens[0].safeTransfer(msg.sender, amount0);
    tokens[1].safeTransfer(msg.sender, amount1);
  }

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external {
    emit Swap(amount0Out, amount1Out, to, data);
    swapRoute(amount0Out > 0 ? 0 : 1, to);
  }

  function swapRoute(uint8 fromToken, address recipient) public lock returns(uint amountOut) {
    require(fromToken == 0 || fromToken == 1);
    uint8 toToken = fromToken == 0 ? 1 : 0;

    uint diff = IERC20(tokens[fromToken]).balanceOf(address(this)) - reserves[fromToken];
    require(diff > 0, 'Input Too Low');

    reserves[fromToken] += diff;
    amountOut = (diff * reserves[toToken]) / reserves[fromToken];
    amountOut -= (amountOut * swapFee) / 0xffffffff;
    reserves[toToken] -= amountOut;

    tokens[toToken].safeTransfer(recipient, amountOut);
  }


  // From: https://github.com/Uniswap/v2-core/blob/v1.0.1/contracts/libraries/Math.sol
  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

}
