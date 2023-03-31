// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC1155 } from "@openzeppelin/token/ERC1155/ERC1155.sol";


contract ATRToken is ERC1155 {

    // # Invariants
    // - totalSupply is sum of all minted tokens per id, independant of their owners

    address public immutable MINTER;

    // Tracks the number of minted tokens per id
    mapping (uint256 => uint256) private _totalSupply;

    modifier onlyMinter() {
        require(msg.sender == MINTER, "Caller is not the minter address");
        _;
    }


    constructor(string memory uri_, address _minter) ERC1155(uri_) {
        MINTER = _minter;
    }


    function mint(address to, uint256 id, uint256 amount) external onlyMinter {
        _mint(to, id, amount, "");
        _totalSupply[id] += amount;
    }

    function burn(address from, uint256 id, uint256 amount) external onlyMinter {
        _burn(from, id, amount);
        _totalSupply[id] -= amount;
    }


    function totalSupply(uint256 id) external view returns (uint256) {
        return _totalSupply[id];
    }

}
