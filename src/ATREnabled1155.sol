// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC1155 } from "@openzeppelin/token/ERC1155/ERC1155.sol";
import { ATRToken } from "./ATRToken.sol";


/**
 * - Owner or approved address can transfer only untokenized amount
 * - Tokenized amount can be transferred only by ATR token holder via `atrTransferFrom` function
 */
contract ATREnabled1155 is ERC1155 {

    // # Invariants
    // - address balance is >= total supply of user atr id (atr id = hash(user address, token id) )

    ATRToken public immutable atr;


    constructor() ERC1155("metadata:uri") {
        atr = new ATRToken("metadata:uri", address(this));
    }

    // For ERC1155, ATR id is owner address hashed with token id
    // It enables fungibility of tokens locked in one address
    function atrId(address owner, uint256 tokenId) external pure returns (uint256) {
        return _atrId(owner, tokenId);
    }

    function _atrId(address owner, uint256 tokenId) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(owner, tokenId)));
    }


    // # mint / burn ATR token

    function mintTransferRights(uint256 tokenId, uint256 amount) external {
        uint256 atrId_ = _atrId(msg.sender, tokenId);

        uint256 balance = balanceOf(msg.sender, tokenId);
        uint256 atrBalance = atr.balanceOf(msg.sender, atrId_);
        require(balance - atrBalance >= amount, "Insufficient untokenized balance");

        atr.mint(msg.sender, atrId_, amount);
    }

    function burnTransferRights(uint256 tokenId, uint256 amount) external {
        uint256 atrId_ = _atrId(msg.sender, tokenId);

        uint256 atrBalance = atr.balanceOf(msg.sender, atrId_);
        require(atrBalance >= amount, "Insufficient tokenized balance");

        atr.burn(msg.sender, atrId_, amount);
    }


    // # transfer constraints

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
        address spender = msg.sender;
        uint256 atrId_ = _atrId(from, id);
        uint256 atrTotalSupply = atr.totalSupply(atrId_);
        uint256 spenderAtrBalance = atr.balanceOf(spender, atrId_);
        uint256 balance = balanceOf(from, id);

        if (spenderAtrBalance >= amount)
            _atrSafeTransferFrom(spender,from, to, id, amount, data);
        else if (balance - atrTotalSupply >= amount)
            super.safeTransferFrom(from, to, id, amount, data);
        else
            revert("Insufficient atr balance");
    }

    // batch transfer doesn't support ATR transfers
    // to use ATR transfers, use `safeTransferFrom` function
    // TODO: enabled ATR functionality for batch transfer
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            require(balanceOf(from, id) - atr.totalSupply(_atrId(from, id)) >= amount, "Insufficient untokenized balance");
        }

        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _atrSafeTransferFrom(address spender, address from, address to, uint256 id, uint256 amount, bytes memory data) private {
        atr.burn(spender, _atrId(from, id), amount);
        // need to mint new ATR tokens for spender
        atr.mint(spender, _atrId(to, id), amount);

        _safeTransferFrom(from, to, id, amount, data);
    }


    // # burn

    function _burn(address from, uint256 id, uint256 amount) override internal virtual {
        _checkSufficientTokenizedBalance(from, id, amount);
        super._burn(from, id, amount);
    }

    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) override internal virtual {
        for (uint256 i; i < ids.length; ++i)
            _checkSufficientTokenizedBalance(from, ids[i], amounts[i]);
        super._burnBatch(from, ids, amounts);
    }

    function _checkSufficientTokenizedBalance(address from, uint256 id, uint256 amount) private view {
        uint256 atrId_ = _atrId(from, id);
        uint256 balance = balanceOf(from, id);
        uint256 atrTotalSupply = atr.totalSupply(atrId_);
        require(balance - amount >= atrTotalSupply, "Insufficient tokenized balance");
    }

}
