// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/DutchAuctionNFT.sol";

contract DutchAuctionNFTTest is Test {
    DutchAuctionNFT public nft;
    
    address public owner = vm.addr(1);
    address public user1 = vm.addr(2);
    address public user2 = vm.addr(3);
    
    function setUp() public {
        vm.startPrank(owner);
        nft = new DutchAuctionNFT();
        vm.stopPrank();
    }
    
    function testConstructor() public {
        assertEq(nft.owner(), owner);
        assertEq(nft.name(), "Dutch Auction NFT");
        assertEq(nft.symbol(), "DANFT");
        assertEq(nft.mintPrice(), 0.01 ether);
        assertEq(nft.MAX_SUPPLY(), 1000);
    }
    
    function testMint() public {
        vm.startPrank(user1);
        uint256 balanceBefore = user1.balance;
        
        nft.mint{value: 0.01 ether}();
        
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.totalSupply(), 1);
        assertEq(user1.balance, balanceBefore - 0.01 ether);
        vm.stopPrank();
    }
    
    function testMintTo() public {
        vm.startPrank(user1);
        uint256 balanceBefore = user1.balance;
        
        nft.mintTo{value: 0.01 ether}(user2);
        
        assertEq(nft.ownerOf(1), user2);
        assertEq(nft.totalSupply(), 1);
        assertEq(user1.balance, balanceBefore - 0.01 ether);
        vm.stopPrank();
    }
    
    function testMintInsufficientPayment() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Insufficient payment");
        nft.mint{value: 0.005 ether}();
        
        vm.stopPrank();
    }
    
    function testMintExactPayment() public {
        vm.startPrank(user1);
        
        nft.mint{value: 0.01 ether}();
        
        assertEq(nft.ownerOf(1), user1);
        vm.stopPrank();
    }
    
    function testMintExcessPayment() public {
        vm.startPrank(user1);
        uint256 balanceBefore = user1.balance;
        
        nft.mint{value: 0.02 ether}();
        
        assertEq(nft.ownerOf(1), user1);
        // Note: excess payment is kept by the contract
        assertEq(user1.balance, balanceBefore - 0.02 ether);
        vm.stopPrank();
    }
    
    function testMultipleMints() public {
        vm.startPrank(user1);
        
        nft.mint{value: 0.01 ether}();
        nft.mint{value: 0.01 ether}();
        nft.mint{value: 0.01 ether}();
        
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user1);
        assertEq(nft.ownerOf(3), user1);
        assertEq(nft.totalSupply(), 3);
        
        vm.stopPrank();
    }
    
    function testSetMintPrice() public {
        vm.startPrank(owner);
        
        nft.setMintPrice(0.05 ether);
        assertEq(nft.mintPrice(), 0.05 ether);
        
        vm.stopPrank();
    }
    
    function testSetMintPriceNotOwner() public {
        vm.startPrank(user1);
        
        vm.expectRevert();
        nft.setMintPrice(0.05 ether);
        
        vm.stopPrank();
    }
    
    function testSetBaseURI() public {
        vm.startPrank(owner);
        
        nft.setBaseURI("https://newapi.example.com/metadata/");
        
        vm.stopPrank();
    }
    
    function testSetBaseURINotOwner() public {
        vm.startPrank(user1);
        
        vm.expectRevert();
        nft.setBaseURI("https://newapi.example.com/metadata/");
        
        vm.stopPrank();
    }
    
    function testTokenURI() public {
        vm.startPrank(user1);
        
        nft.mint{value: 0.01 ether}();
        string memory uri = nft.tokenURI(1);
        assertEq(uri, "https://api.example.com/metadata/1");
        
        vm.stopPrank();
    }
    
    function testTokenURINonExistent() public {
        vm.expectRevert("Token does not exist");
        nft.tokenURI(999);
    }
    
    function testWithdraw() public {
        vm.startPrank(user1);
        nft.mint{value: 0.01 ether}();
        vm.stopPrank();
        
        vm.startPrank(owner);
        uint256 balanceBefore = owner.balance;
        nft.withdraw();
        assertGt(owner.balance, balanceBefore);
        vm.stopPrank();
    }
    
    function testWithdrawNotOwner() public {
        vm.startPrank(user1);
        
        vm.expectRevert();
        nft.withdraw();
        
        vm.stopPrank();
    }
    
    function testMaxSupply() public {
        vm.startPrank(user1);
        
        // Mint up to max supply
        for (uint256 i = 0; i < 1000; i++) {
            nft.mint{value: 0.01 ether}();
        }
        
        assertEq(nft.totalSupply(), 1000);
        
        // Try to mint one more
        vm.expectRevert("Max supply reached");
        nft.mint{value: 0.01 ether}();
        
        vm.stopPrank();
    }
    
    function testTransfer() public {
        vm.startPrank(user1);
        nft.mint{value: 0.01 ether}();
        vm.stopPrank();
        
        vm.startPrank(user1);
        nft.transferFrom(user1, user2, 1);
        assertEq(nft.ownerOf(1), user2);
        vm.stopPrank();
    }
    
    function testApprove() public {
        vm.startPrank(user1);
        nft.mint{value: 0.01 ether}();
        nft.approve(user2, 1);
        assertEq(nft.getApproved(1), user2);
        vm.stopPrank();
    }
    
    function testSetApprovalForAll() public {
        vm.startPrank(user1);
        nft.mint{value: 0.01 ether}();
        nft.setApprovalForAll(user2, true);
        assertTrue(nft.isApprovedForAll(user1, user2));
        vm.stopPrank();
    }
} 