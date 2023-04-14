// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";
import { ATRToken } from "./ATRToken.sol";


/**
 * - Owner or approved address can transfer only untokenized id
 * - Tokenized id can be transferred only by ATR token holder via `atrTransferFrom` function
 */
contract ATREnabled721 is ERC721 {

    // # Invariants
    // - max atr amount per id is 1

    ATRToken public immutable atr;


    constructor() ERC721("ATREnabled721", "ATR721") {
        atr = new ATRToken("metadata:uri", address(this));
    }


    // # mint / burn ATR token

    function mintTransferRights(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Insufficient untokenized balance");
        require(atr.totalSupply(tokenId) == 0, "Insufficient untokenized balance");

        // For ERC721, ATR id is token id
        atr.mint(msg.sender, tokenId, 1);
    }

    function burnTransferRights(uint256 tokenId) external {
        uint256 atrBalance = atr.balanceOf(msg.sender, tokenId);
        require(atrBalance == 1, "Insufficient tokenized balance");

        atr.burn(msg.sender, tokenId, 1);
    }


    // # use transfer rights

    function atrTransferFrom(address from, address to, uint256 tokenId, bool burnAtr) external {
        uint256 atrBalance = atr.balanceOf(msg.sender, tokenId);
        require(atrBalance == 1, "Insufficient atr balance");

        atr.burn(msg.sender, tokenId, 1);

        _transfer(from, to, tokenId);

        if (!burnAtr)
            atr.mint(msg.sender, tokenId, 1);
    }


    // # transfer constraints

    function _beforeTokenTransfer(address from, address /*to*/, uint256 firstTokenId, uint256 /*batchSize*/) override internal view {
        if (from == address(0))
            return; // mint ATREnabled721 tokens

        uint256 atrTotalSupply = atr.totalSupply(firstTokenId);
        require(atrTotalSupply == 0, "Insufficient untokenized balance");
    }


    // # helpers

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

}