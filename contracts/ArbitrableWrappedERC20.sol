// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./deps/ERC20.sol";
import "./deps/IERC20.sol";
import "./deps/SafeERC20.sol";
import "./Arbitrable.sol";

using SafeERC20 for IERC20;

contract ArbitrableWrappedERC20 is ERC20, Arbitrable {
  string public name;
  string public symbol;
  uint8 public decimals;
  IERC20 public baseToken;

  constructor(IERC20 baseTokenAddr, string memory _name, string memory _symbol) Arbitrable() {
    baseToken = baseTokenAddr;
    name = _name;
    symbol = _symbol;
    decimals = baseToken.decimals();
  }
  function mintTo(address user, uint amount) external {
    _mint(user, amount);
    baseToken.safeTransferFrom(msg.sender, address(this), amount);
  }
  function burnFrom(address user, address recipient, uint amount) external onlyArbitrator {
    _burn(user, amount);
    baseToken.safeTransfer(recipient, amount);
  }
  function arbtratorTransfer(address from, address to, uint256 amount) external onlyArbitrator {
    _transfer(from, to, amount);
  }
}
