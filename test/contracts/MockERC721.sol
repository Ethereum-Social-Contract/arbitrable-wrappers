// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../contracts/deps/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
  constructor(
      string memory name_,
      string memory symbol_
  ) ERC721(name_, symbol_) {}

  function _baseURI() internal view virtual override returns (string memory) {
      return "test/";
  }

  function mint(address to, uint tokenId) external {
    _safeMint(to, tokenId);
  }
}
