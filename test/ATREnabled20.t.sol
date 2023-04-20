// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Test } from "forge-std/Test.sol";

import { ATRToken } from "../src/ATRToken.sol";
import { ATREnabled20 } from "../src/ATREnabled20.sol";


contract ATREnabled20Test is Test {

    ATRToken atr;
    ATREnabled20 asset;

    address joey = makeAddr("joey");
    address chandler = makeAddr("chandler");
    address ross = makeAddr("ross");


    function setUp() external {
        asset = new ATREnabled20();
        atr = asset.atr();

        deal({ token: address(asset), to: joey, give: 100 });
    }

    function _atrId(address owner) private pure returns (uint256) {
        return uint256(uint160(owner));
    }


    // mint

    function test_shouldMintATRToken() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        assertEq(atr.balanceOf(joey, _atrId(joey)), 100);
    }

    function test_shouldFailToMintATRToken_whenInsufficientBalance() external {
        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.mintTransferRights(110);
    }

    function test_shouldFailToMintATRToken_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(60);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.mintTransferRights(60);
    }


    // burn

    function test_shouldBurnATRToken() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        vm.prank(joey);
        asset.burnTransferRights(100);

        assertEq(atr.balanceOf(joey, _atrId(joey)), 0);
    }

    function test_shouldFailToBurn_whenInsufficientTokenizedBalance_1() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey), 50, "");

        assertEq(atr.balanceOf(joey, _atrId(joey)), 50);
        assertEq(atr.balanceOf(chandler, _atrId(joey)), 50);

        vm.expectRevert("Insufficient tokenized balance");
        vm.prank(joey);
        asset.burnTransferRights(60);

        vm.expectRevert("Insufficient tokenized balance");
        vm.prank(joey);
        asset.burnTransferRights(90);
    }

    function test_shouldFailToBurn_whenInsufficientTokenizedBalance_2() external {
        vm.prank(joey);
        asset.mintTransferRights(80);

        vm.expectRevert("Insufficient tokenized balance");
        vm.prank(joey);
        asset.burnTransferRights(90);
    }


    // transfer

    function test_shouldTransfer_whenSufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(80);

        vm.prank(joey);
        asset.transfer(chandler, 20);

        assertEq(asset.balanceOf(joey), 80);
        assertEq(asset.balanceOf(chandler), 20);
    }

    function test_shouldFailToTransfer_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(80);

        vm.prank(joey);
        asset.approve(chandler, 30);

        vm.expectRevert("Insufficient atr balance");
        vm.prank(chandler);
        asset.transferFrom(joey, chandler, 30);
    }

    function test_shouldTransfer_whenSufficientTokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey), 50, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey)), 50);

        vm.prank(chandler);
        asset.transferFrom(joey, ross, 50);

        assertEq(asset.balanceOf(joey), 50);
        assertEq(asset.balanceOf(ross), 50);
    }

    function test_shouldFail_whenInsufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey), 50, "");

        vm.expectRevert("Insufficient atr balance");
        vm.prank(chandler);
        asset.transferFrom(joey, ross, 60);
    }

    function test_shouldMintToATRToken() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey), 50, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey)), 50);
        assertEq(atr.balanceOf(chandler, _atrId(ross)), 0);

        vm.prank(chandler);
        asset.transferFrom(joey, ross, 50);

        assertEq(atr.balanceOf(joey, _atrId(joey)), 50);
        assertEq(atr.balanceOf(chandler, _atrId(joey)), 0);
        assertEq(atr.balanceOf(chandler, _atrId(ross)), 50);
    }

}
