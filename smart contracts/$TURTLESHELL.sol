// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SignatureProver {
    function getMessageHash(
        address to,
        uint256 amount,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, amount, nonce));
    }

    function getEthSignedMessageHash(bytes32 messageHash)
        public
        pure
        returns (bytes32)
    {
        
        // Signature is produced by signing a keccak256 hash with the following format:
        // "\x19Ethereum Signed Message\n" + len(msg) + msg
        
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    function verify(
        address signer,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(to, amount, nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory signature)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "Invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
            // second 32 bytes
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }

        // implicitly return (r, s, v)
    }
}

contract $TURTLESHELL is ERC20, Ownable, SignatureProver {
    mapping(address => uint256) public nonceMap;
    mapping(address => uint256) public claimedTokens;

    constructor() ERC20("$TURTLESHELL", "TRTL") {
        _mint(msg.sender, 420690000000000000000);
    }

    function claimTokens(
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(
            verify(owner(), msg.sender, amount, nonce, signature),
            "Invalid signature"
        );

        // Current nonce has to match this one to avoid double-claiming
        require(nonceMap[msg.sender] == nonce, "Invalid nonce");

        _mint(msg.sender, amount);

        nonceMap[msg.sender]++;
        claimedTokens[msg.sender] += amount;
    }

    function sendTokens(uint256 amount, address[] calldata beneficiaries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            address beneficiary = beneficiaries[i];
            _mint(beneficiary, amount);
        }
    }
}
