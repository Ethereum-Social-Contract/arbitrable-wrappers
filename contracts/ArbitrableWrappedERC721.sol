// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./deps/ERC721/ERC721.sol";
import "./deps/ERC165Checker.sol";
import "./Arbitrable.sol";
import "./IArbitrable.sol";

error CannotNestArbitrable();

contract ArbitrableWrappedERC721 is ERC721, Arbitrable {
  IERC721Metadata public baseCollection;

  constructor(
      IERC721Metadata baseCollection_,
      string memory name_,
      string memory symbol_
  ) ERC721(name_, symbol_) Arbitrable()
  {
    baseCollection = baseCollection_;

    if(ERC165Checker.supportsInterface(address(baseCollection), type(IArbitrable).interfaceId))
      revert CannotNestArbitrable();
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(Arbitrable, ERC721) returns (bool) {
      return
          interfaceId == type(IArbitrable).interfaceId ||
          interfaceId == type(IERC721).interfaceId ||
          interfaceId == type(IERC721Metadata).interfaceId ||
          super.supportsInterface(interfaceId);
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    return baseCollection.tokenURI(tokenId);
  }

  function wrapNFT(uint tokenId, address recipient) external {
    baseCollection.transferFrom(msg.sender, address(this), tokenId);
    _safeMint(recipient, tokenId);
  }

  function unwrapNFT(uint tokenId, address recipient) external onlyArbitratorIfAvailable {
    if(arbitrator == address(0))
      require(_ownerOf(tokenId) == msg.sender);

    baseCollection.safeTransferFrom(address(this), recipient, tokenId);
    _burn(tokenId);
  }

  function arbitratorTransfer(uint tokenId, address recipient, bytes memory data) external onlyArbitrator {
    _safeTransfer(_ownerOf(tokenId), recipient, tokenId, data);
  }
}
