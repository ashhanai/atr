// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Test } from "forge-std/Test.sol";

import { ATRToken } from "../src/ATRToken.sol";


contract ATRTokenTest is Test {

    ATRToken atr;

    address minter = makeAddr("minter");
    address addr1 = makeAddr("addr1");
    address addr2 = makeAddr("addr2");
    uint256 id = 42;
    uint256 amount = 100;

    function setUp() external {
        atr = new ATRToken("uri://", minter);
    }


    // constructor

    function test_setMinterAddress() external {
        address _minter = makeAddr("_minter");

        atr = new ATRToken("uri://", _minter);

        assertEq(atr.MINTER(), _minter);
    }


    // mint

    function test_shouldMintToken() external {
        vm.prank(minter);
        atr.mint(addr1, id, amount);

        assertEq(atr.balanceOf(addr1, id), amount);
        assertEq(atr.totalSupply(id), amount);

        vm.prank(minter);
        atr.mint(addr2, id, amount);

        assertEq(atr.balanceOf(addr1, id), amount);
        assertEq(atr.totalSupply(id), 2 * amount);
    }

    function test_shouldFailToMintToken_whenCallerNotMinter() external {
        address notMinter = makeAddr("notMinter");

        vm.expectRevert("Caller is not the minter address");
        vm.prank(notMinter);
        atr.mint(addr1, id, amount);
    }


    // burn

    function test_shouldBurnToken() external {
        // setup
        vm.prank(minter);
        atr.mint(addr1, id, amount);
        vm.prank(minter);
        atr.mint(addr2, id, amount);

        // test
        vm.prank(minter);
        atr.burn(addr1, id, amount);

        assertEq(atr.balanceOf(addr1, id), 0);
        assertEq(atr.totalSupply(id), amount);

        vm.prank(minter);
        atr.burn(addr2, id, amount);

        assertEq(atr.balanceOf(addr1, id), 0);
        assertEq(atr.totalSupply(id), 0);
    }

    function test_shouldFailToBurnToken_whenCallerNotMinter() external {
        address notMinter = makeAddr("notMinter");

        vm.expectRevert("Caller is not the minter address");
        vm.prank(notMinter);
        atr.burn(addr1, id, amount);
    }

    function test_shouldFailToBurnToken_whenInsufficientBalance() external {
        // setup
        vm.prank(minter);
        atr.mint(addr1, id, amount);

        // test
        vm.expectRevert("ERC1155: burn amount exceeds balance");
        vm.prank(minter);
        atr.burn(addr1, id, amount + 1);
    }


    // total supply

    function testFuzz_shouldReturnTotalSupply(uint256 totalSupply) external {
        bytes32 slot = keccak256(abi.encode(id, 3));
        vm.store(address(atr), slot, bytes32(totalSupply));

        assertEq(atr.totalSupply(id), totalSupply);
    }

}
