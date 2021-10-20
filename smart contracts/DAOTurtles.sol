// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


pragma solidity ^0.8.2;

contract DAOTurtles is ERC721, ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant AVAILABLE_FOR_PUBLIC = 9800;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant MAX_PER_TXN = 20;
    uint256 private tokenCounter;
    bool public saleActive;

    string private URI = "https://gateway.pinata.cloud/ipfs/QmRcEveDugLLwktAV2F7KdxBvxRDx3BgvLM97wGopehV9E/";

    constructor() ERC721("DAO Turtles", "DTS") {}

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    function setURI(string memory _URI) external onlyOwner {
        URI = _URI;
    }

    function flipSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function mint(address to, uint256 amount) external payable {
        require(saleActive, "Sale inactive");
        require(amount <= MAX_PER_TXN, "Exceeds max. per txn.");
        require(amount + tokenCounter <= AVAILABLE_FOR_PUBLIC, "Supply limit");
        require(msg.value >= amount * PRICE, "Incorrect ETH");

        uint256 _tokenCounter = tokenCounter;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenCounter);
            _tokenCounter++;
        }
        tokenCounter = _tokenCounter;
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function forge(address to, uint256 amount) external onlyOwner {
        require(amount <= MAX_PER_TXN, "Exceeds max. per txn.");
        require(amount + tokenCounter <= MAX_SUPPLY, "Supply limit!");

        uint256 _tokenCounter = tokenCounter;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenCounter);
            _tokenCounter++;
        }
        tokenCounter = _tokenCounter;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
