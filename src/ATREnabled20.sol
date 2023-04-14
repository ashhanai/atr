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
    function _atrId(address owner) private pure returns (uint256) {
        return uint256(uint160(owner));
    }


    // # mint / burn ATR token

    function mintTransferRights(uint256 amount) external {
        uint256 atrId = _atrId(msg.sender);

        uint256 balance = balanceOf(msg.sender);
        uint256 atrBalance = atr.balanceOf(msg.sender, atrId);
        require(balance - atrBalance >= amount, "Insufficient untokenized balance");

        atr.mint(msg.sender, atrId, amount);
    }

    function burnTransferRights(uint256 amount) external {
        uint256 atrId = _atrId(msg.sender);

        uint256 atrBalance = atr.balanceOf(msg.sender, atrId);
        require(atrBalance >= amount, "Insufficient tokenized balance");

        atr.burn(msg.sender, atrId, amount);
    }


    // # use transfer rights

    function atrTransferFrom(address from, address to, uint256 amount, bool burnAtr) external {
        uint256 atrId = _atrId(from);

        uint256 atrBalance = atr.balanceOf(msg.sender, atrId);
        require(atrBalance >= amount, "Insufficient atr balance");

        atr.burn(msg.sender, atrId, amount);
        if (!burnAtr)
            // need to mint a new atr tokens when owner changes
            atr.mint(msg.sender, _atrId(to), amount);

        _transfer(from, to, amount);
    }


    // # transfer constraints

    function _beforeTokenTransfer(address from, address /*to*/, uint256 amount) override internal view {
        if (from == address(0))
            return; // mint ATREnabled20 tokens

        uint256 atrId = _atrId(from);
        // Number of all minted atr tokens with this id is equal to the number of tokenized assets in the address
        uint256 atrTotalSupply = atr.totalSupply(atrId);
        uint256 balance = balanceOf(from);
        require(balance - atrTotalSupply >= amount, "Insufficient untokenized balance");
    }


    // # helpers

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

}
