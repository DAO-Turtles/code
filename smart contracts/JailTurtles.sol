// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

pragma solidity ^0.8.9;

contract JailTurtles is ERC721, ERC721Enumerable, Ownable {
    uint256 public constant MAX_PER_TXN = 20;

    string private URI = "https://gateway.pinata.cloud/ipfs/QmUoFRDKdh7NxQ96hejoRhuiBeWLsnytFEy7BEkLH7HuGy/";
    
    // DAO Turtles contract
    IERC721Enumerable IBaseContract = IERC721Enumerable(0xc92d06C74A26AeAf4d1A1273FAC171f3B09FAC79);
    
    mapping (uint256 => bool) public claimedTurtles;

    constructor() ERC721("Jail Turtles", "#FreeTheTurtles") {}

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    function setURI(string memory _URI) external onlyOwner {
        URI = _URI;
    }
    
    function freeMint(uint256 tokenId) public {
        require(!claimedTurtles[tokenId], "Jail Turtle already claimed");
        require(IBaseContract.ownerOf(tokenId) == msg.sender, "DAO Turtle not owned");
        _safeMint(msg.sender, tokenId);
        claimedTurtles[tokenId] = true;
    }
    
    function freeMintMultiple(uint256 amount, uint256[] calldata tokenIds) external {
        require(amount <= MAX_PER_TXN, "20 max. per. txn");
        for (uint256 i=0; i<amount; i++) {
            freeMint(tokenIds[i]);
        }
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
