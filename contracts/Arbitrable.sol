// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./deps/ERC165.sol";

error Unauthorized();

abstract contract Arbitrable is ERC165 {
  address public arbitrator;

  event ArbitratorChanged(address indexed previousArbitrator, address indexed newArbitrator);

  constructor() {
    arbitrator = msg.sender;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(Arbitrable).interfaceId || super.supportsInterface(interfaceId);
  }

  modifier onlyArbitrator() {
    if(msg.sender != arbitrator)
      revert Unauthorized();
    _;
  }

  function changeArbitrator(address newArbitrator) external onlyArbitrator {
    emit ArbitratorChanged(arbitrator, newArbitrator);
    arbitrator = newArbitrator;
  }
}
