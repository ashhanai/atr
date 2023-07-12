// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// when ATR token is minted, only ATR token holder can transfer tokenized amount (don't have to use special function)
interface IATREnabled {
    // ATR contract address
    function atr() external view returns (address);
}


interface IATREnabled20 is IATREnabled {
    // ATR token id for given owner and token id
    function atrId(address owner) external pure returns (uint256);

    // mint / burn ATR token for given token id and amount
    function mintTransferRights(uint256 amount) external;
    function burnTransferRights(uint256 atrId, uint256 amount) external;

    // transfer with ATR
    function transferFromWithATR(address from, address to, uint256 amount) external;
}

interface IATREnabled721 is IATREnabled {
    // ATR token id for given owner and token id
    function atrId(uint256 tokenId) external pure returns (uint256);

    // mint / burn ATR token for given token id and amount
    function mintTransferRights(uint256 tokenId) external;
    function burnTransferRights(uint256 tokenId) external;

    // transfer with ATR
    function transferFromWithATR(address from, address to, uint256 tokenId) external;
    function safeTransferFromWithATR(address from, address to, uint256 tokenId) external;
    function safeTransferFromWithATR(address from, address to, uint256 tokenId, bytes memory data) external;
}

interface IATREnabled1155 is IATREnabled {
    // ATR token id for given owner and token id
    function atrId(address owner, uint256 tokenId) external pure returns (uint256);

    // mint / burn ATR token for given token id and amount
    function mintTransferRights(uint256 tokenId, uint256 amount) external;
    function burnTransferRights(uint256 tokenId, uint256 amount) external;

    // transfer with ATR
    function safeTransferFromWithATR(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function safeBatchTransferFromWithATR(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}
