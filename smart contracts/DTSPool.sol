// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.9;


contract DTSPool is Ownable {
    event DepositNFT(address indexed from, address indexed tokenContract, uint256 indexed tokenID);
    event WithdrawNFT(address indexed from, address indexed tokenContract, uint256 indexed tokenID);
    
    // DAO Turtles Staking Pool
    address constant public DTS_VAULT = 0xA3ACd9eD1334b6c33E3b1D88394e1E2b771A5795;
    
    bool public canDepositNFT = true;
    bool public canWithdrawNFT = true;
    
    // map each NFT contract to map of tokenID: stakerAddress 
    mapping (address => mapping (uint256 => address)) public NFTStakers;
    
    function flipDepositNFT() external onlyOwner {
        canDepositNFT = !canDepositNFT;
    }
    
    function flipWithdrawNFT() external onlyOwner {
        canWithdrawNFT = !canWithdrawNFT;
    }
    
    function depositNFT(address tokenContract, uint256 tokenID) external {
        require(canDepositNFT, "Closed for deposits");
        IERC721Enumerable ITokenContract = IERC721Enumerable(tokenContract);
        require(ITokenContract.ownerOf(tokenID) == msg.sender, "Token not owned");
        ITokenContract.safeTransferFrom(msg.sender, DTS_VAULT, tokenID);
        NFTStakers[tokenContract][tokenID] = msg.sender;
        emit DepositNFT(msg.sender, tokenContract, tokenID);
    }
    
    function depositMultipleNFTs(address tokenContract, uint256 amount, uint256[] calldata tokenIDList) external {
        require(canDepositNFT, "Closed for deposits");
        require(amount <= 10, "Too many NFTs");
        IERC721Enumerable ITokenContract = IERC721Enumerable(tokenContract);
        uint256 tokenID;
        for (uint256 i=0; i<amount; i++) {
            tokenID = tokenIDList[i];
            require(ITokenContract.ownerOf(tokenID) == msg.sender, "Token not owned");
            ITokenContract.safeTransferFrom(msg.sender, DTS_VAULT, tokenID);
            NFTStakers[tokenContract][tokenID] = msg.sender;
            emit DepositNFT(msg.sender, tokenContract, tokenID);
        }
    }

    function withdrawNFT(address tokenContract, uint256 tokenID) external {
        require(canWithdrawNFT, "Closed for withdrawals");
        // Token staker must be the caller
        require(NFTStakers[tokenContract][tokenID] == msg.sender, "Token not owned");
        IERC721Enumerable(tokenContract).safeTransferFrom(DTS_VAULT, msg.sender, tokenID);
        delete NFTStakers[tokenContract][tokenID];
        emit WithdrawNFT(msg.sender, tokenContract, tokenID);
    }
    
    function withdrawMultipleNFT(address tokenContract, uint256 amount, uint256[] calldata tokenIDList) external {
        require(canWithdrawNFT, "Closed for withdrawals");
        require(amount <= 10, "Too many NFTs");
        IERC721Enumerable ITokenContract = IERC721Enumerable(tokenContract);
        uint256 tokenID;
        for (uint256 i=0; i<amount; i++) {
            tokenID = tokenIDList[i];
            require(NFTStakers[tokenContract][tokenID] == msg.sender, "Token not owned");
            ITokenContract.safeTransferFrom(DTS_VAULT, msg.sender, tokenID);
            delete NFTStakers[tokenContract][tokenID];
            emit WithdrawNFT(msg.sender, tokenContract, tokenID);
        }
    }

    function getNumberOfStakedTokens(address staker, address tokenContract) public view returns (uint256) {
        uint256 count;
        uint256 maxTokens = IERC721Enumerable(tokenContract).totalSupply();
        for (uint256 i=0; i < maxTokens; i++) {
            if (NFTStakers[tokenContract][i] == staker) {
                count++;
            }
        }
        return count;
        
    }

    function getStakedTokens(address staker, address tokenContract) external view returns (uint256[] memory) {
        uint256 count = getNumberOfStakedTokens(staker, tokenContract);
        uint256 maxTokens = IERC721Enumerable(tokenContract).totalSupply();
        uint256[] memory tokens = new uint256[](count);
        uint256 n;
        for (uint256 i=0; i < maxTokens; i++) {
            if (NFTStakers[tokenContract][i] == staker) {
                tokens[n] = i;
                n++;
            }
        }
        return tokens;
    }

    function getUnstakedTokens(address staker, address tokenContract) external view returns (uint256[] memory) {
        IERC721Enumerable ITokenContract = IERC721Enumerable(tokenContract);
        uint256 count = ITokenContract.balanceOf(staker);
        uint256 maxTokens = ITokenContract.totalSupply();
        uint256[] memory tokens = new uint256[](count);
        uint256 n;
        for (uint256 i=0; i < maxTokens; i++) {
            if (ITokenContract.ownerOf(i) == staker) {
                tokens[n] = i;
                n++;
            }
        }
        return tokens;
    }
    
    function isStakedByAddress(address staker, address tokenContract, uint256 tokenID) external view returns (bool){
        if (NFTStakers[tokenContract][tokenID] == staker) {
            return true;
        } else {
            return false;
        }
    }
}
