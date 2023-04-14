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
    function _atrId(address owner, uint256 tokenId) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(owner, tokenId)));
    }


    // # mint / burn ATR token

    function mintTransferRights(uint256 tokenId, uint256 amount) external {
        uint256 atrId = _atrId(msg.sender, tokenId);

        uint256 balance = balanceOf(msg.sender, tokenId);
        uint256 atrBalance = atr.balanceOf(msg.sender, atrId);
        require(balance - atrBalance >= amount, "Insufficient untokenized balance");

        atr.mint(msg.sender, atrId, amount);
    }

    function burnTransferRights(uint256 tokenId, uint256 amount) external {
        uint256 atrId = _atrId(msg.sender, tokenId);

        uint256 atrBalance = atr.balanceOf(msg.sender, atrId);
        require(atrBalance >= amount, "Insufficient tokenized balance");

        atr.burn(msg.sender, atrId, amount);
    }


    // # use transfer rights

    function atrTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bool burnAtr) external {
        uint256 atrId = _atrId(from, tokenId);

        uint256 atrBalance = atr.balanceOf(msg.sender, atrId);
        require(atrBalance >= amount, "Insufficient atr balance");

        atr.burn(msg.sender, atrId, amount);
        if (!burnAtr)
            // need to mint a new atr tokens when owner changes
            atr.mint(msg.sender, _atrId(to, tokenId), amount);

        _safeTransferFrom(from, to, tokenId, amount, "");
    }


    // # transfer constraints

    function _beforeTokenTransfer(
        address /*operator*/,
        address from,
        address /*to*/,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory /*data*/
    ) override internal view {
        if (from == address(0))
            return; // mint ATREnabled1155 tokens

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 atrId = _atrId(from, id);
            // Number of all minted atr tokens with this id is equal to the number of tokenized assets in the address
            uint256 atrTotalSupply = atr.totalSupply(atrId);
            uint256 balance = balanceOf(from, id);
            require(balance - atrTotalSupply >= amount, "Insufficient untokenized balance");
        }
    }


    // # helpers

    function mint(address account, uint256 tokenId, uint256 amount) external {
        _mint(account, tokenId, amount, "");
    }

    function burn(address account, uint256 tokenId, uint256 amount) external {
        _burn(account, tokenId, amount);
    }

}
