// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC1155 } from "@openzeppelin/token/ERC1155/ERC1155.sol";
import { ATRToken } from "./ATRToken.sol";
import { IATREnabled } from "./IATREnabled.sol";


contract ATREnabled1155 is ERC1155, IATREnabled {

    // # Invariants
    // - address balance is >= total supply of user atr id (atr id = hash(user address, token id) )
    // - only owner can mint ATR tokens for assets

    ATRToken internal immutable _atr;


    constructor(string memory metadataUri_, string memory atrMetadataUri_) ERC1155(metadataUri_) {
        _atr = new ATRToken(atrMetadataUri_, address(this));
    }


    function atr() external view returns (address) {
        return address(_atr);
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
        // only owner can mint ATR tokens for assets
        uint256 atrId_ = _atrId(msg.sender, tokenId);

        uint256 balance = balanceOf(msg.sender, tokenId);
        uint256 atrTotalSupply = _atr.totalSupply(atrId_);

        // address balance is always greater or equal to the total supply of the atr id
        require(balance - atrTotalSupply >= amount, "Insufficient untokenized balance");

        _atr.mint(msg.sender, atrId_, amount);
    }

    function burnTransferRights(uint256 atrId_, uint256 amount) external {
        uint256 atrBalance = _atr.balanceOf(msg.sender, atrId_);

        require(atrBalance >= amount, "Insufficient ATR balance");

        _atr.burn(msg.sender, atrId_, amount);
    }


    // # transfer constraints

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        super.safeTransferFrom(from, to, id, amount, data);

        require(balanceOf(from, id) >= _atr.totalSupply(_atrId(from, id)), "Insufficient untokenized balance");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);

        uint256 idsLength = ids.length;
        for (uint256 i; i < idsLength; ++i) {
            require(balanceOf(from, ids[i]) >= _atr.totalSupply(_atrId(from, ids[i])), "Insufficient untokenized balance");
        }
    }


    // # transfer with ATR

    function safeTransferFromWithATR(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        _updateSpendersAtrTokens(msg.sender, from, to, id, amount);

        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFromWithATR(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        uint256 idsLength = ids.length;
        for (uint256 i; i < idsLength; ++i)
            _updateSpendersAtrTokens(msg.sender, from, to, ids[i], amounts[i]);

        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _updateSpendersAtrTokens(address spender, address from, address to, uint256 id, uint256 amount) private {
        _atr.burn(spender, _atrId(from, id), amount);
        _atr.mint(spender, _atrId(to, id), amount);
    }


    // # burn

    function _burn(address from, uint256 id, uint256 amount) override internal virtual {
        super._burn(from, id, amount);

        require(balanceOf(from, id) >= _atr.totalSupply(_atrId(from, id)), "Insufficient untokenized balance");
    }

    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) override internal virtual {
        super._burnBatch(from, ids, amounts);

        uint256 idsLength = ids.length;
        for (uint256 i; i < idsLength; ++i) {
            require(balanceOf(from, ids[i]) >= _atr.totalSupply(_atrId(from, ids[i])), "Insufficient untokenized balance");
        }
    }

}
