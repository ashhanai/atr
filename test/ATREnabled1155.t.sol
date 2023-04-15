// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import { ATRToken } from "../src/ATRToken.sol";
import { ATREnabled1155 } from "../src/ATREnabled1155.sol";


contract ATREnabled1155Harness is ATREnabled1155 {

    function exposed_mint(address account, uint256 tokenId, uint256 amount) external {
        _mint(account, tokenId, amount, "");
    }

}


contract ATREnabled1155Test is Test {

    ATRToken atr;
    ATREnabled1155Harness asset;

    address joey = makeAddr("joey");
    address chandler = makeAddr("chandler");
    address ross = makeAddr("ross");
    uint256 tokenId = 42;

    function setUp() external {
        asset = new ATREnabled1155Harness();
        atr = asset.atr();

        asset.exposed_mint(joey, tokenId, 100);
    }

    function _atrId(address owner, uint256 _tokenId) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(owner, _tokenId)));
    }


    // mint

    function test_shouldMintATRToken() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 100);

        assertEq(atr.balanceOf(joey, _atrId(joey, tokenId)), 100);
    }

    function test_shouldFailToMintATRToken_whenInsufficientBalance() external {
        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 110);
    }

    function test_shouldFailToMintATRToken_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 60);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 60);
    }


    // burn

    function test_shouldBurnATRToken() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 100);

        vm.prank(joey);
        asset.burnTransferRights(tokenId, 100);

        assertEq(atr.balanceOf(joey, _atrId(joey, tokenId)), 0);
    }

    function test_shouldFailToBurn_whenInsufficientTokenizedBalance_1() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey, tokenId), 50, "");

        assertEq(atr.balanceOf(joey, _atrId(joey, tokenId)), 50);
        assertEq(atr.balanceOf(chandler, _atrId(joey, tokenId)), 50);

        vm.expectRevert("Insufficient tokenized balance");
        vm.prank(joey);
        asset.burnTransferRights(tokenId, 60);

        vm.expectRevert("Insufficient tokenized balance");
        vm.prank(joey);
        asset.burnTransferRights(tokenId, 90);
    }

    function test_shouldFailToBurn_whenInsufficientTokenizedBalance_2() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 80);

        vm.expectRevert("Insufficient tokenized balance");
        vm.prank(joey);
        asset.burnTransferRights(tokenId, 90);
    }


    // transfer

    function test_shouldTransfer_whenSufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 80);

        vm.prank(joey);
        asset.safeTransferFrom(joey, chandler, tokenId, 20, "");

        assertEq(asset.balanceOf(joey, tokenId), 80);
        assertEq(asset.balanceOf(chandler, tokenId), 20);
    }

    function test_shouldFailToTransfer_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 80);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey, tokenId), 80, "");

        vm.expectRevert("Insufficient atr balance");
        vm.prank(joey);
        asset.safeTransferFrom(joey, chandler, tokenId, 30, "");
    }

    function test_shouldTransfer_whenSufficientTokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey, tokenId), 50, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey, tokenId)), 50);

        vm.prank(chandler);
        asset.safeTransferFrom(joey, ross, tokenId, 50, "");

        assertEq(asset.balanceOf(joey, tokenId), 50);
        assertEq(asset.balanceOf(ross, tokenId), 50);
    }

    function test_shouldFail_whenInsufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey, tokenId), 50, "");

        vm.expectRevert("Insufficient atr balance");
        vm.prank(chandler);
        asset.safeTransferFrom(joey, ross, tokenId, 60, "");
    }

    function test_shouldMintToATRToken() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey, tokenId), 50, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey, tokenId)), 50);

        vm.prank(chandler);
        asset.safeTransferFrom(joey, ross, tokenId, 50, "");

        assertEq(atr.balanceOf(joey, _atrId(joey, tokenId)), 50);
        assertEq(atr.balanceOf(chandler, _atrId(joey, tokenId)), 0);
        assertEq(atr.balanceOf(chandler, _atrId(ross, tokenId)), 50);
    }

}
