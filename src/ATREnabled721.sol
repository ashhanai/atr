// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";
import { ATRToken } from "./ATRToken.sol";
import { IATREnabled } from "./IATREnabled.sol";


contract ATREnabled721 is ERC721, IATREnabled {

    // # Invariants
    // - max atr amount per id is 1
    // - only owner can mint ATR tokens for assets

    ATRToken internal immutable _atr;


    constructor(string memory name_, string memory symbol_, string memory atrMetadataUri_) ERC721(name_, symbol_) {
        _atr = new ATRToken(atrMetadataUri_, address(this));
    }


    function atr() external view returns (address) {
        return address(_atr);
    }

    // For ERC721, ATR id is token id
    function atrId(uint256 tokenId) external pure returns (uint256) {
        return _atrId(tokenId);
    }

    function _atrId(uint256 tokenId) private pure returns (uint256) {
        return tokenId;
    }


    // # mint / burn ATR token

    function mintTransferRights(uint256 tokenId) external {
        uint256 atrId_ = _atrId(tokenId);
        require(ownerOf(tokenId) == msg.sender, "Insufficient untokenized balance");
        require(_atr.totalSupply(atrId_) == 0, "Insufficient untokenized balance");

        _atr.mint(msg.sender, atrId_, 1);
    }

    function burnTransferRights(uint256 tokenId) external {
        uint256 atrId_ = _atrId(tokenId);
        require(_atr.balanceOf(msg.sender, atrId_) == 1, "Insufficient ATR balance");

        _atr.burn(msg.sender, atrId_, 1);
    }


    // # transfer constraits

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_atr.totalSupply(_atrId(tokenId)) == 0, "Insufficient untokenized balance");

        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_atr.totalSupply(_atrId(tokenId)) == 0, "Insufficient untokenized balance");

        super.safeTransferFrom(from, to, tokenId, data);
    }


    // # transfer with ATR

    function transferFromWithATR(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        require(_atr.balanceOf(msg.sender, _atrId(tokenId)) == 1, "Insufficient ATR balance");

        _transfer(from, to, tokenId);
    }

    function safeTransferFromWithATR(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFromWithATR(from, to, tokenId, "");
    }

    function safeTransferFromWithATR(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        require(_atr.balanceOf(msg.sender, _atrId(tokenId)) == 1, "Insufficient ATR balance");

        _safeTransfer(from, to, tokenId, data);
    }


    // # burn

    function _burn(uint256 tokenId) override internal virtual {
        require(_atr.totalSupply(_atrId(tokenId)) == 0, "Insufficient untokenized balance");

        super._burn(tokenId);
    }

}
