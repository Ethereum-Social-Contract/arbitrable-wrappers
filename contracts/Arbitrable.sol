// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error Unauthorized();

contract Arbitrable {
  address public arbitrator;

  event ArbitratorChanged(address indexed previousArbitrator, address indexed newArbitrator);

  constructor() {
    arbitrator = msg.sender;
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
