// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Test } from "forge-std/Test.sol";

import { ATRToken } from "../src/ATRToken.sol";
import { ATREnabled721 } from "../src/ATREnabled721.sol";


contract ATREnabled721Harness is ATREnabled721 {

    function exposed_mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
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
        asset = new ATREnabled721Harness();
        atr = asset.atr();

        asset.exposed_mint(joey, tokenId);
    }


    // mint

    function test_shouldMintATRToken() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        assertEq(atr.balanceOf(joey, tokenId), 1);
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
        atr.safeTransferFrom(joey, chandler, tokenId, 1, "");

        vm.expectRevert("Insufficient tokenized balance");
        vm.prank(joey);
        asset.burnTransferRights(tokenId);
    }

    function test_shouldFailToBurn_whenNotMinted_whenInsufficientTokenizedBalance() external {
        vm.expectRevert("Insufficient tokenized balance");
        vm.prank(joey);
        asset.burnTransferRights(tokenId);
    }


    // transfer

    function test_shouldTransfer_whenNotMinted() external {
        vm.prank(joey);
        asset.transferFrom(joey, chandler, tokenId);

        assertEq(asset.ownerOf(tokenId), chandler);
    }

    function test_shouldFailToTransfer_whenMinted_whenNotHolder() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, tokenId, 1, "");

        vm.expectRevert("ERC721: caller is not token owner or approved");
        vm.prank(joey);
        asset.transferFrom(joey, chandler, tokenId);
    }

    function test_shouldTransfer_whenMinted_whenHolder() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, tokenId, 1, "");

        vm.prank(chandler);
        asset.transferFrom(joey, ross, tokenId);

        assertEq(asset.ownerOf(tokenId), ross);
    }

}
