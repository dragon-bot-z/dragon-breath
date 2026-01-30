// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DragonsBreath.sol";

contract DragonsBreathTest is Test {
    DragonsBreath public breath;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    function setUp() public {
        breath = new DragonsBreath();
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
    }

    function test_Mint() public {
        vm.prank(alice);
        uint256 tokenId = breath.mint{value: 0.001 ether}();
        
        assertEq(tokenId, 1);
        assertEq(breath.totalSupply(), 1);
        assertEq(breath.ownerOf(1), alice);
    }

    function test_MintSetsCorrectData() public {
        vm.prank(alice);
        breath.mint{value: 0.001 ether}();
        
        (address minter, , , uint256 mintBlock) = breath.breathData(1);
        assertEq(minter, alice);
        assertEq(mintBlock, block.number);
    }

    function test_TokenURIReturnsValidJSON() public {
        vm.prank(alice);
        breath.mint{value: 0.001 ether}();
        
        string memory uri = breath.tokenURI(1);
        assertTrue(bytes(uri).length > 0);
        // URI should start with data:application/json;base64,
        assertTrue(_startsWith(uri, "data:application/json;base64,"));
    }

    function test_PreviewBreath() public view {
        string memory svg = breath.previewBreath(alice, 12345);
        assertTrue(bytes(svg).length > 0);
        assertTrue(_startsWith(svg, "<svg"));
    }

    function test_DifferentAddressesDifferentElements() public {
        // Generate many addresses and verify distribution
        uint256[5] memory counts;
        
        for (uint256 i = 0; i < 100; i++) {
            address testAddr = address(uint160(i + 1000));
            vm.deal(testAddr, 0.01 ether);
            vm.prank(testAddr);
            breath.mint{value: 0.001 ether}();
            
            (, , DragonsBreath.Element element, ) = breath.breathData(i + 1);
            counts[uint256(element)]++;
        }
        
        // Each element should appear at least once in 100 mints
        for (uint256 i = 0; i < 5; i++) {
            assertTrue(counts[i] > 0, "Element not represented");
        }
    }

    function test_RevertInsufficientPayment() public {
        vm.prank(alice);
        vm.expectRevert(DragonsBreath.InsufficientPayment.selector);
        breath.mint{value: 0.0001 ether}();
    }

    function test_RevertMaxSupply() public {
        // Mint all 1111
        for (uint256 i = 0; i < 1111; i++) {
            address minter = address(uint160(i + 1));
            vm.deal(minter, 0.01 ether);
            vm.prank(minter);
            breath.mint{value: 0.001 ether}();
        }
        
        vm.prank(alice);
        vm.expectRevert(DragonsBreath.MaxSupplyReached.selector);
        breath.mint{value: 0.001 ether}();
    }

    function test_MultipleMintsSameAddress() public {
        vm.startPrank(alice);
        
        uint256 token1 = breath.mint{value: 0.001 ether}();
        vm.roll(block.number + 1); // Different block for different entropy
        uint256 token2 = breath.mint{value: 0.001 ether}();
        
        vm.stopPrank();
        
        assertEq(token1, 1);
        assertEq(token2, 2);
        assertEq(breath.balanceOf(alice), 2);
        
        // Both should have same element (determined by address)
        (, , DragonsBreath.Element e1, ) = breath.breathData(1);
        (, , DragonsBreath.Element e2, ) = breath.breathData(2);
        assertEq(uint256(e1), uint256(e2));
    }

    function test_EventEmitted() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        
        // Get expected element
        DragonsBreath.Element expectedElement = DragonsBreath.Element(
            uint256(keccak256(abi.encodePacked(alice))) % 5
        );
        
        emit DragonsBreath.BreathMinted(1, alice, expectedElement);
        breath.mint{value: 0.001 ether}();
    }

    // Helper to check string prefix
    function _startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);
        
        if (strBytes.length < prefixBytes.length) return false;
        
        for (uint256 i = 0; i < prefixBytes.length; i++) {
            if (strBytes[i] != prefixBytes[i]) return false;
        }
        return true;
    }
}
