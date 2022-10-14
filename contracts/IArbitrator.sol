// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Hierarchical arbitrator interface
interface IArbitrator {
  // Returns the URI for contacting the arbitrator to request a case
  // e.g. mailto, tel, https
  function contactURI() external view returns (string memory);
  // Returns the addresses of the arbitrators that have power over this one 
  function parentArbitrators() external view returns (address[] memory);
  // Allows a parent arbitrator to call other contracts on behalf of this
  //   arbitrator
  function parentArbitratorInvoke(address to, bytes memory data) external;
}
