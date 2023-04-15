// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { ATRToken } from "./ATRToken.sol";


/**
 * - Owner or approved address can transfer only untokenized amount
 * - Tokenized amount can be transferred only by ATR token holder via `atrTransferFrom` function
 */
contract ATREnabled20 is ERC20 {

    // # Invariants
    // - address balance is >= total supply of user atr id (atr id = user address)

    ATRToken public immutable atr;


    constructor() ERC20("ATREnabled20", "ATR20") {
        atr = new ATRToken("metadata:uri", address(this));
    }

    // For ERC20, ATR id is owner address
    // It enables fungibility of tokens locked in one address
    function atrId(address owner, uint256 /* tokenId */) external pure returns (uint256) {
        return _atrId(owner);
    }

    function _atrId(address owner) private pure returns (uint256) {
        return uint256(uint160(owner));
    }


    // # mint / burn ATR token

    function mintTransferRights(uint256 amount) external {
        uint256 atrId_ = _atrId(msg.sender);

        uint256 balance = balanceOf(msg.sender);
        uint256 atrBalance = atr.balanceOf(msg.sender, atrId_);
        require(balance - atrBalance >= amount, "Insufficient untokenized balance");

        atr.mint(msg.sender, atrId_, amount);
    }

    function burnTransferRights(uint256 amount) external {
        uint256 atrId_ = _atrId(msg.sender);

        uint256 atrBalance = atr.balanceOf(msg.sender, atrId_);
        require(atrBalance >= amount, "Insufficient tokenized balance");

        atr.burn(msg.sender, atrId_, amount);
    }


    // # transfer constraints

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        address from = msg.sender;
        uint256 atrId_ = _atrId(from);
        uint256 atrTotalSupply = atr.totalSupply(_atrId(from));
        uint256 spenderAtrBalance = atr.balanceOf(spender, atrId_);
        uint256 balance = balanceOf(from);

        if (spenderAtrBalance >= amount)
            return _atrTransferFrom(spender, from, to, amount);
        else if (balance - atrTotalSupply >= amount)
            return super.transfer(to, amount);
        else
            revert("Insufficient atr balance");
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        uint256 atrId_ = _atrId(from);
        uint256 atrTotalSupply = atr.totalSupply(atrId_);
        uint256 spenderAtrBalance = atr.balanceOf(spender, atrId_);
        uint256 balance = balanceOf(from);

        if (spenderAtrBalance >= amount)
            return _atrTransferFrom(spender, from, to, amount);
        else if (balance - atrTotalSupply >= amount)
            return super.transferFrom(from, to, amount);
        else
            revert("Insufficient atr balance");
    }

    function _atrTransferFrom(address spender, address from, address to, uint256 amount) private returns (bool) {
        atr.burn(spender, _atrId(from), amount);
        // need to mint new ATR tokens for spender
        atr.mint(spender, _atrId(to), amount);

        _transfer(from, to, amount);

        return true;
    }

    function _updateSpenderAtrTokens(address spender, address from, address to, uint256 amount) private {
        atr.burn(spender, _atrId(from), amount);
        atr.mint(spender, _atrId(to), amount);
    }


    // #burn

    function _burn(address account, uint256 amount) override internal virtual {
        uint256 atrId_ = _atrId(account);
        uint256 balance = balanceOf(account);
        uint256 atrTotalSupply = atr.totalSupply(atrId_);
        require(balance - amount >= atrTotalSupply, "Insufficient tokenized balance");

        super._burn(account, amount);
    }

}
