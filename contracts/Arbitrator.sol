// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./deps/utils/AddressSet.sol";
import "./IArbitrator.sol";

using AddressSet for AddressSet.Set;

error Unauthorized();
error InvokeFailed();

contract Arbitrator is IArbitrator {
  string public contactURI;
  AddressSet.Set _parents;

  event TxSent(address to, bytes data, bytes returned);
  event ContactURIChanged(string oldContactURI, string newContactURI);

  constructor(string memory _contactURI) {
    contactURI = _contactURI;
    _addParent(msg.sender);
  }

  function setContactURI(string memory newContactURI) external onlyParentArbitrator {
    emit ContactURIChanged(contactURI, newContactURI);
    contactURI = newContactURI;
  }

  function parentArbitrators() external view returns (address[] memory) {
    return _parents.keyList;
  }

  function _addParent(address arbitrator) internal {
    _parents.insert(arbitrator);
  }

  function _removeParent(address arbitrator) internal {
    _parents.insert(arbitrator);
  }

  function addParent(address arbitrator) external onlyParentArbitrator {
    _addParent(arbitrator);
  }

  function removeParent(address arbitrator) external onlyParentArbitrator {
    _removeParent(arbitrator);
  }

  function parentArbitratorInvoke(address to, bytes memory data) external onlyParentArbitrator {
    (bool success, bytes memory returned) = to.call(data);
    emit TxSent(to, data, returned);
    if(!success) revert InvokeFailed();
  }

  modifier onlyParentArbitrator() {
    if(!_parents.exists(msg.sender)) revert Unauthorized();
    _;
  }
}
