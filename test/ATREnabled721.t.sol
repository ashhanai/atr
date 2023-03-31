// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import { ATRToken } from "../src/ATRToken.sol";
import { ATREnabled721 } from "../src/ATREnabled721.sol";


contract ATREnabled721Test is Test {

    ATRToken atr;
    ATREnabled721 asset;

    address joey = makeAddr("joey");
    address chandler = makeAddr("chandler");
    address ross = makeAddr("ross");
    uint256 tokenId = 42;


    function setUp() external {
        asset = new ATREnabled721();
        atr = asset.atr();

        asset.mint(joey, tokenId);
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

    function test_shouldFailToTransfer_whenMinted() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.transferFrom(joey, chandler, tokenId);
    }


    // transfer via atr

    function test_shouldTransfer_whenSufficientTokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, tokenId, 1, "");

        vm.prank(chandler);
        asset.atrTransferFrom(joey, ross, tokenId, true);

        assertEq(asset.ownerOf(tokenId), ross);
    }

    function test_shouldFail_whenInsufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.expectRevert("Insufficient atr balance");
        vm.prank(chandler);
        asset.atrTransferFrom(joey, ross, tokenId, true);
    }

    function test_shouldBurnFromATRToken() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, tokenId, 1, "");

        vm.prank(chandler);
        asset.atrTransferFrom(joey, ross, tokenId, true);

        assertEq(atr.balanceOf(chandler, tokenId), 0);
    }

    function test_shouldMintToATRToken_whenNotBurnFlag() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, tokenId, 1, "");

        vm.prank(chandler);
        asset.atrTransferFrom(joey, ross, tokenId, false);

        assertEq(atr.balanceOf(chandler, tokenId), 1);
    }

}
