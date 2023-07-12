// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Test } from "forge-std/Test.sol";

import { ATRToken } from "../src/ATRToken.sol";
import { ATREnabled1155 } from "../src/ATREnabled1155.sol";


contract ATREnabled1155Harness is ATREnabled1155 {

    constructor(
        string memory metadataUri_,
        string memory atrMetadataUri_
    ) ATREnabled1155(metadataUri_, atrMetadataUri_) {}

    function exposed_burn(uint256 id, uint256 amount) external {
        _burn(msg.sender, id, amount);
    }

    function exposed_burnBatch(uint256[] memory ids, uint256[] memory amounts) external {
        _burnBatch(msg.sender, ids, amounts);
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
        asset = new ATREnabled1155Harness("uri://", "uri://");
        atr = ATRToken(asset.atr());

        dealERC1155({ token: address(asset), to: joey, id: tokenId, give: 100 });
    }

    function _atrId(address owner, uint256 _tokenId) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(owner, _tokenId)));
    }


    // atrId

    function testFuzz_shouldReturnATRId(address addr_, uint256 tokenId_) external {
        assertEq(asset.atrId(addr_, tokenId_), _atrId(addr_, tokenId_));
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
        asset.burnTransferRights(_atrId(joey, tokenId), 100);

        assertEq(atr.balanceOf(joey, _atrId(joey, tokenId)), 0);
    }

    function test_shouldFailToBurn_whenInsufficientTokenizedBalance_1() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey, tokenId), 50, "");

        assertEq(atr.balanceOf(joey, _atrId(joey, tokenId)), 50);
        assertEq(atr.balanceOf(chandler, _atrId(joey, tokenId)), 50);

        vm.expectRevert("Insufficient ATR balance");
        vm.prank(joey);
        asset.burnTransferRights(_atrId(joey, tokenId), 60);

        vm.expectRevert("Insufficient ATR balance");
        vm.prank(joey);
        asset.burnTransferRights(_atrId(joey, tokenId), 90);
    }

    function test_shouldFailToBurn_whenInsufficientTokenizedBalance_2() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 80);

        vm.expectRevert("Insufficient ATR balance");
        vm.prank(joey);
        asset.burnTransferRights( _atrId(joey, tokenId), 90);
    }


    // safeTransferFrom constraints

    function test_shouldSafeTransfer_whenSufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 80);

        vm.prank(joey);
        asset.safeTransferFrom(joey, chandler, tokenId, 20, "");

        assertEq(asset.balanceOf(joey, tokenId), 80);
        assertEq(asset.balanceOf(chandler, tokenId), 20);
    }

    function test_shouldFailToSafeTransfer_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 80);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.safeTransferFrom(joey, chandler, tokenId, 30, "");
    }


    // safeBatchTransferFrom constraints

    function test_shouldSafeBatchTransfer_whenSufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 50);

        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId;
        ids[1] = tokenId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 20;
        amounts[1] = 30;

        vm.prank(joey);
        asset.safeBatchTransferFrom(joey, chandler, ids, amounts, "");

        assertEq(asset.balanceOf(joey, tokenId), 50);
        assertEq(asset.balanceOf(chandler, tokenId), 50);
    }

    function test_shouldFailToSafeBatchTransfer_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 80);

        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId;
        ids[1] = tokenId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 20;
        amounts[1] = 30;

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.safeBatchTransferFrom(joey, chandler, ids, amounts, "");
    }


    // safeTransferFrom with ATR

    function test_shouldSafeTransfer_whenSufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey, tokenId), 50, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey, tokenId)), 50);

        vm.prank(chandler);
        asset.safeTransferFromWithATR(joey, ross, tokenId, 40, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey, tokenId)), 10);
        assertEq(atr.balanceOf(chandler, _atrId(ross, tokenId)), 40);
        assertEq(asset.balanceOf(joey, tokenId), 60);
        assertEq(asset.balanceOf(ross, tokenId), 40);
    }

    function test_shouldFailToSafeTransfer_whenInsufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey, tokenId), 50, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey, tokenId)), 50);

        vm.expectRevert("ERC1155: burn amount exceeds balance");
        vm.prank(chandler);
        asset.safeTransferFromWithATR(joey, ross, tokenId, 60, "");
    }


    // TODO: safeBatchTransferFrom with ATR

    function test_shouldSafeBatchTransfer_whenSufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 100);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey, tokenId), 50, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey, tokenId)), 50);

        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId;
        ids[1] = tokenId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10;
        amounts[1] = 30;

        vm.prank(chandler);
        asset.safeBatchTransferFromWithATR(joey, ross, ids, amounts, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey, tokenId)), 10);
        assertEq(atr.balanceOf(chandler, _atrId(ross, tokenId)), 40);
        assertEq(asset.balanceOf(joey, tokenId), 60);
        assertEq(asset.balanceOf(ross, tokenId), 40);
    }

    function test_shouldFailToSafeBatchTransfer_whenInsufficientATRBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 70);

        vm.prank(joey);
        atr.safeTransferFrom(joey, chandler, _atrId(joey, tokenId), 50, "");

        assertEq(atr.balanceOf(chandler, _atrId(joey, tokenId)), 50);

        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId;
        ids[1] = tokenId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 20;
        amounts[1] = 40;

        vm.expectRevert("ERC1155: burn amount exceeds balance");
        vm.prank(chandler);
        asset.safeBatchTransferFromWithATR(joey, ross, ids, amounts, "");
    }


    // burn asset

    function test_shouldBurnAsset_whenSufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 80);

        vm.prank(joey);
        asset.exposed_burn(tokenId, 20);

        assertEq(asset.balanceOf(joey, tokenId), 80);
    }

    function test_shouldFailToBurn_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 100);

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.exposed_burn(tokenId, 20);
    }


    // burnBatch asset

    function test_shouldBurnBatchAsset_whenSufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 50);

        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId;
        ids[1] = tokenId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 20;
        amounts[1] = 30;

        vm.prank(joey);
        asset.exposed_burnBatch(ids, amounts);

        assertEq(asset.balanceOf(joey, tokenId), 50);
    }

    function test_shouldFailToBurnBatch_whenInsufficientUntokenizedBalance() external {
        vm.prank(joey);
        asset.mintTransferRights(tokenId, 60);

        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId;
        ids[1] = tokenId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 20;
        amounts[1] = 30;

        vm.expectRevert("Insufficient untokenized balance");
        vm.prank(joey);
        asset.exposed_burnBatch(ids, amounts);
    }

}
