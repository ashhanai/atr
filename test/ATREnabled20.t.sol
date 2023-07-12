// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Test } from "forge-std/Test.sol";

import { ATRToken } from "../src/ATRToken.sol";
import { ATREnabled20 } from "../src/ATREnabled20.sol";


contract ATREnabled20Harness is ATREnabled20 {

    constructor(
        string memory name_,
        string memory symbol_,
        string memory atrMetadataUri_
    ) ATREnabled20(name_, symbol_, atrMetadataUri_) {}

    function exposed_burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

}


contract ATREnabled20Test is Test {

    ATRToken atr;
    ATREnabled20Harness asset;

    address joey = makeAddr("joey");
    address chandler = makeAddr("chandler");
    address ross = makeAddr("ross");


    function setUp() external {
        asset = new ATREnabled20Harness("ATREnabled20", "ATR20", "uri://");
        atr = ATRToken(asset.atr());

        deal({ token: address(asset), to: joey, give: 100 });
    }

    function _atrId(address owner) private pure returns (uint256) {
        return uint256(uint160(owner));
    }


    // atrId

    function testFuzz_shouldReturnATRId(address addr_) external {
        assertEq(asset.atrId(addr_), _atrId(addr_));
    }


    // mint ATR

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


    // burn ATR

    function test_shouldBurnATRToken_whenOwnedTokenizedAsset() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        vm.prank(joey);
        asset.burnTransferRights(_atrId(joey), 100);

        assertEq(atr.balanceOf(joey, _atrId(joey)), 0);
    }

    function test_shouldBurnATRToken_whenNotOwnedTokenizedAsset() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey), 100, "");

        vm.prank(chandler);
        asset.burnTransferRights(_atrId(joey), 100);

        assertEq(atr.balanceOf(joey, _atrId(joey)), 0);
    }

    function test_shouldFailToBurn_whenInsufficientTokenizedBalance_1() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey), 50, "");

        assertEq(atr.balanceOf(joey, _atrId(joey)), 50);
        assertEq(atr.balanceOf(chandler, _atrId(joey)), 50);

        vm.expectRevert("Insufficient ATR balance");
        vm.prank(joey);
        asset.burnTransferRights(_atrId(joey), 60);

        vm.expectRevert("Insufficient ATR balance");
        vm.prank(joey);
        asset.burnTransferRights(_atrId(joey), 90);
    }

    function test_shouldFailToBurn_whenInsufficientTokenizedBalance_2() external {
        vm.prank(joey);
        asset.mintTransferRights(80);

        vm.expectRevert("Insufficient ATR balance");
        vm.prank(joey);
        asset.burnTransferRights(_atrId(joey), 90);
    }


    // transfer constraints

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

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.transfer(chandler, 30);
    }


    // transferFrom constraints

    function test_shouldTransferFrom_whenSufficientTokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(80);

        vm.prank(joey);
        asset.approve(chandler, 20);

        vm.prank(chandler);
        asset.transferFrom(joey, ross, 20);

        assertEq(asset.balanceOf(joey), 80);
        assertEq(asset.balanceOf(ross), 20);
    }

    function test_shouldFailToTransferFrom_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(80);

        vm.prank(joey);
        asset.approve(chandler, 30);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(chandler);
        asset.transferFrom(joey, ross, 30);
    }


    // transfer with ATR

    function test_shouldTransfer_whenSufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey), 50, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey)), 50);

        vm.prank(chandler);
        asset.transferFromWithATR(joey, ross, 40);

        assertEq(atr.balanceOf(chandler, _atrId(joey)), 10);
        assertEq(atr.balanceOf(chandler, _atrId(ross)), 40);
        assertEq(asset.balanceOf(joey), 60);
        assertEq(asset.balanceOf(ross), 40);
    }

    function test_shouldFailToTransfer_whenInsufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey), 50, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey)), 50);

        vm.expectRevert("ERC1155: burn amount exceeds balance");
        vm.prank(chandler);
        asset.transferFromWithATR(joey, ross, 60);
    }


    // burn asset

    function test_shouldBurnAsset_whenSufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(80);

        vm.prank(joey);
        asset.exposed_burn(20);

        assertEq(asset.balanceOf(joey), 80);
    }

    function test_shouldFailToBurn_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(100);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.exposed_burn(20);
    }

}
