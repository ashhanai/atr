// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Test } from "forge-std/Test.sol";

import { ATRToken } from "../src/ATRToken.sol";
import { ATREnabled721 } from "../src/ATREnabled721.sol";


contract ATREnabled721Harness is ATREnabled721 {

    constructor(
        string memory name_,
        string memory symbol_,
        string memory atrMetadataUri_
    ) ATREnabled721(name_, symbol_, atrMetadataUri_) {}

    function exposed_mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function exposed_burn(uint256 tokenId) external {
        _burn(tokenId);
    }

}


contract ATREnabled721Test is Test {

    ATRToken atr;
    ATREnabled721Harness asset;

    address joey = makeAddr("joey");
    address chandler = makeAddr("chandler");
    address ross = makeAddr("ross");
    uint256 tokenId = 42;


    function setUp() external {
        asset = new ATREnabled721Harness("ATREnabled721", "ATR721", "uri://");
        atr = ATRToken(asset.atr());

        asset.exposed_mint(joey, tokenId);
    }

    function _atrId(uint256 tokenId_) private pure returns (uint256) {
        return tokenId_;
    }


    // atrId

    function testFuzz_shouldReturnATRId(uint256 tokenId_) external {
        assertEq(asset.atrId(tokenId_), _atrId(tokenId_));
    }


    // mint

    function test_shouldMintATRToken() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        assertEq(atr.balanceOf(joey, _atrId(tokenId)), 1);
    }

    function test_shouldFailToMintATRToken_whenInsufficientBalance() external {
        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(chandler);
        asset.mintTransferRights(tokenId);
    }

    function test_shouldFailToMintATRToken_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.mintTransferRights(tokenId);
    }


    // burn

    function test_shouldBurnATRToken() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.prank(joey);
        asset.burnTransferRights(tokenId);

        assertEq(atr.balanceOf(joey, tokenId), 0);
    }

    function test_shouldFailToBurn_whenMinted_whenInsufficientTokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(tokenId), 1, "");

        vm.expectRevert("Insufficient ATR balance");
        vm.prank(joey);
        asset.burnTransferRights(tokenId);
    }

    function test_shouldFailToBurn_whenNotMinted_whenInsufficientTokenizedBalance() external {
        vm.expectRevert("Insufficient ATR balance");
        vm.prank(joey);
        asset.burnTransferRights(tokenId);
    }


    // transferFrom constraints

    function test_shouldTransfer_whenNotMinted() external {
        vm.prank(joey);
        asset.transferFrom(joey, chandler, tokenId);

        assertEq(asset.ownerOf(tokenId), chandler);
    }

    function test_shouldFailToTransfer_whenMinted_whenOwner() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.transferFrom(joey, chandler, tokenId);
    }

    function test_shouldFailToTransfer_whenMinted_whenApproved() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(tokenId), 1, "");

        vm.prank(joey);
        asset.approve(chandler, tokenId);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(chandler);
        asset.transferFrom(joey, ross, tokenId);
    }

    // safeTransferFrom constraints

    function test_shouldSafeTransfer_whenNotMinted() external {
        vm.prank(joey);
        asset.safeTransferFrom(joey, chandler, tokenId);

        assertEq(asset.ownerOf(tokenId), chandler);
    }

    function test_shouldFailToSafeTransfer_whenMinted_whenOwner() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.safeTransferFrom(joey, chandler, tokenId);
    }

    function test_shouldFailToSafeTransfer_whenMinted_whenApproved() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(tokenId), 1, "");

        vm.prank(joey);
        asset.approve(chandler, tokenId);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(chandler);
        asset.safeTransferFrom(joey, ross, tokenId);
    }


    // transferFrom with ATR

    function test_shouldTransfer_whenSufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(tokenId), 1, "");

        vm.prank(chandler);
        asset.transferFromWithATR(joey, ross, tokenId);

        assertEq(asset.ownerOf(tokenId), ross);
    }

    function test_shouldFailToTransfer_whenInsufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.expectRevert("Insufficient ATR balance");
        vm.prank(chandler);
        asset.transferFromWithATR(joey, ross, tokenId);
    }


    // safeTransferFrom with ATR

    function test_shouldSafeTransfer_whenSufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(tokenId), 1, "");

        vm.prank(chandler);
        asset.safeTransferFromWithATR(joey, ross, tokenId);

        assertEq(asset.ownerOf(tokenId), ross);
    }

    function test_shouldFailToSafeTransfer_whenInsufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.expectRevert("Insufficient ATR balance");
        vm.prank(chandler);
        asset.safeTransferFromWithATR(joey, ross, tokenId);
    }


    // burn asset

    function test_shouldBurnAsset_whenSufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.exposed_burn(tokenId);

        vm.expectRevert("ERC721: invalid token ID");
        asset.ownerOf(tokenId);
    }

    function test_shouldFailToBurn_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.exposed_burn(tokenId);
    }

}
