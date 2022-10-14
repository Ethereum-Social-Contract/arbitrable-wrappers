// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./deps/ERC20.sol";
import "./deps/IERC20.sol";
import "./deps/SafeERC20.sol";
import "./deps/ERC165Checker.sol";
import "./IArbitrable.sol";

using SafeERC20 for IERC20;

error MustBeArbitrable();
error DepositTooSmall();
error InsufficientBalance();

// Uniswap V2 style liquidity pool that always checks the balances
//  instead of maintaining reserve amounts in local state
// Both tokens are required to be Arbitrable in order to keep all value
//  within arbitrable jurisdiction
// Uses more gas but we got L2 now where execution is cheap
contract ArbitrableERC20LiquidityPool is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  IERC20[2] public tokens;
  // 0-0xffffffff: 0-100%
  uint32 public swapFee;

  uint public constant MINIMUM_DEPOSIT = 10**3;

  event NewSwapFee(uint32 oldFee, uint32 newFee);

  uint private unlocked = 1;
  modifier lock() {
    require(unlocked == 1, 'LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  constructor(
    address token0Addr,
    address token1Addr,
    uint32 _swapFee,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) {
    if(!ERC165Checker.supportsInterface(token0Addr, type(IArbitrable).interfaceId)
       || !ERC165Checker.supportsInterface(token1Addr, type(IArbitrable).interfaceId))
      revert MustBeArbitrable();

    tokens[0] = IERC20(token0Addr);
    tokens[1] = IERC20(token1Addr);
    swapFee = _swapFee;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  function getReserves() public view returns(uint[2] memory reserves) {
    reserves[0] = tokens[0].balanceOf(address(this));
    reserves[1] = tokens[1].balanceOf(address(this));
  }

  function deposit(uint amount0, uint amount1) external lock returns(uint liquidity) {
    if(amount0 < MINIMUM_DEPOSIT || amount1 < MINIMUM_DEPOSIT)
      revert DepositTooSmall();

    uint[2] memory reserves = getReserves();
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
    liquidity = sqrt(amount0ToTake * amount1ToTake);
    _mint(msg.sender, liquidity);
    tokens[0].safeTransferFrom(msg.sender, address(this), amount0ToTake);
    tokens[1].safeTransferFrom(msg.sender, address(this), amount1ToTake);
  }

  function withdraw(uint liquidity) external lock returns(uint amount0, uint amount1) {
    require(balanceOf[msg.sender] >= liquidity);
    uint[2] memory reserves = getReserves();

    amount0 = (liquidity * reserves[0]) / totalSupply;
    amount1 = (liquidity * reserves[1]) / totalSupply;

    balanceOf[msg.sender] -= liquidity;
    totalSupply -= liquidity;
    emit Transfer(msg.sender, address(0), liquidity);

    tokens[0].safeTransfer(msg.sender, amount0);
    tokens[1].safeTransfer(msg.sender, amount1);
  }

  // This function differs from Uniswap V2 style, requiring more gas
  //  since it must perform extra an extra transfer of the token
  //  due to not being able to calculate the amountIn from the difference
  //  between the stored reserve amount and the fromToken balance
  function swapRoute(uint8 fromToken, uint amountIn, address recipient) external lock returns(uint amountOut) {
    require(fromToken == 0 || fromToken == 1);
    require(amountIn > 0);

    uint8 toToken = fromToken == 0 ? 1 : 0;
    uint[2] memory reserves = getReserves();

    amountOut = (amountIn * reserves[toToken]) / reserves[fromToken];
    amountOut -= (amountOut * swapFee) / 0xffffffff;

    tokens[fromToken].safeTransferFrom(msg.sender, address(this), amountIn);
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
