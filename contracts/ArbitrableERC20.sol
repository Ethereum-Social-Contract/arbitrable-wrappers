// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./deps/ERC20.sol";
import "./Arbitrable.sol";

contract ArbitrableERC20 is ERC20, Arbitrable {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string memory _name, string memory _symbol, uint8 _decimals) Arbitrable() {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  function mintTo(address user, uint amount) external onlyArbitrator {
    _mint(user, amount);
  }

  function burnFrom(address user, uint amount) external onlyArbitrator {
    _burn(user, amount);
  }

  function arbitratorTransfer(address from, address to, uint256 amount) external onlyArbitrator {
    _transfer(from, to, amount);
  }

}

