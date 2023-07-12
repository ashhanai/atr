// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { ATRToken } from "./ATRToken.sol";
import { IATREnabled20 } from "./IATREnabled.sol";


contract ATREnabled20 is ERC20, IATREnabled20 {

    // # Invariants
    // - address balance is >= total supply of user atr id (atr id = user address)
    // - only owner can mint ATR tokens for assets

    ATRToken internal immutable _atr;


    constructor(string memory name_, string memory symbol_, string memory atrMetadataUri_) ERC20(name_, symbol_) {
        _atr = new ATRToken(atrMetadataUri_, address(this));
    }


    function atr() external view returns (address) {
        return address(_atr);
    }

    // For ERC20, ATR id is owners address
    // It enables fungibility of tokens locked in one address
    function atrId(address owner) external pure returns (uint256) {
        return _atrId(owner);
    }

    function _atrId(address owner) private pure returns (uint256) {
        return uint256(uint160(owner));
    }


    // # mint / burn ATR token

    function mintTransferRights(uint256 amount) public virtual {
        // only owner can mint ATR tokens for assets
        uint256 atrId_ = _atrId(msg.sender);

        uint256 balance = balanceOf(msg.sender);
        uint256 atrTotalSupply = _atr.totalSupply(atrId_);

        // address balance is always greater or equal to the total supply of the atr id
        require(balance - atrTotalSupply >= amount, "Insufficient untokenized balance");

        _atr.mint(msg.sender, atrId_, amount);
    }

    function burnTransferRights(uint256 atrId_, uint256 amount) public virtual {
        uint256 atrBalance = _atr.balanceOf(msg.sender, atrId_);

        require(atrBalance >= amount, "Insufficient ATR balance");

        _atr.burn(msg.sender, atrId_, amount);
    }


    // # transfer constraits

    function transfer(address to, uint256 amount) public virtual override returns (bool success) {
        success = super.transfer(to, amount);

        require(balanceOf(msg.sender) >= _atr.totalSupply(_atrId(msg.sender)), "Insufficient untokenized balance");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool success) {
        success = super.transferFrom(from, to, amount);

        require(balanceOf(from) >= _atr.totalSupply(_atrId(from)), "Insufficient untokenized balance");
    }


    // # transfer with ATR

    function transferFromWithATR(
        address from,
        address to,
        uint256 amount
    ) public virtual {
        _atr.burn(msg.sender, _atrId(from), amount);
        _atr.mint(msg.sender, _atrId(to), amount);

        _transfer(from, to, amount);
    }


    // # burn

    function _burn(address from, uint256 amount) override internal virtual {
        super._burn(from, amount);

        require(balanceOf(from) >= _atr.totalSupply(_atrId(from)), "Insufficient untokenized balance");
    }

}
