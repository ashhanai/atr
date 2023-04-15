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

    // For ERC721, ATR id is token id
    // Owner can be basically ignored
    function atrId(address /* owner */, uint256 tokenId) external pure returns (uint256) {
        return _atrId(tokenId);
    }

    function _atrId(uint256 tokenId) private pure returns (uint256) {
        return tokenId;
    }


    // # mint / burn ATR token

    function mintTransferRights(uint256 tokenId) external {
        uint256 atrId_ = _atrId(tokenId);
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Insufficient untokenized balance");
        require(atr.totalSupply(atrId_) == 0, "Insufficient untokenized balance");

        atr.mint(msg.sender, atrId_, 1);
    }

    function burnTransferRights(uint256 tokenId) external {
        uint256 atrId_ = _atrId(tokenId);
        uint256 atrBalance = atr.balanceOf(msg.sender, atrId_);
        require(atrBalance == 1, "Insufficient tokenized balance");

        atr.burn(msg.sender, atrId_, 1);
    }


    // # transfer constraints

    function _isApprovedOrOwner(address spender, uint256 tokenId) override internal view virtual returns (bool) {
        uint256 atrId_ = _atrId(tokenId);
        // if tokenized, only ATR token holder can transfer
        if (atr.totalSupply(atrId_) > 0)
            return atr.balanceOf(spender, atrId_) == 1;
        else
            return super._isApprovedOrOwner(spender, tokenId);
    }

}
