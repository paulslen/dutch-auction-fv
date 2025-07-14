// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/DutchAuction.sol";
import "../contracts/DutchAuctionNFT.sol";

contract DutchAuctionTest is Test {
    DutchAuction public auction;
    DutchAuctionNFT public nft;
    
    address public owner = vm.addr(1);
    address public seller = vm.addr(2);
    address public buyer1 = vm.addr(3);
    address public buyer2 = vm.addr(4);
    
    uint256 public tokenId = 1;
    uint256 public initialPrice = 1 ether;
    uint256 public reservePrice = 0.1 ether;
    uint256 public priceDecrement = 0.01 ether;
    uint256 public duration = 100;
    
    function setUp() public {
        vm.startPrank(owner);
        nft = new DutchAuctionNFT();
        auction = new DutchAuction();
        vm.stopPrank();
        
        // Mint NFT to seller
        vm.startPrank(seller);
        nft.mint{value: 0.01 ether}();
        nft.setApprovalForAll(address(auction), true);
        vm.stopPrank();
    }
    
    function testCreateAuction() public {
        vm.startPrank(seller);
        
        uint256 balanceBefore = seller.balance;
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        // Check auction was created
        assertEq(auction.getAuctionCount(), 1);
        
        // Check auction details
        DutchAuction.Auction memory auctionData = auction.getAuction(0);
        assertEq(auctionData.seller, seller);
        assertEq(auctionData.nftAddress, address(nft));
        assertEq(auctionData.tokenId, tokenId);
        assertEq(auctionData.initialPrice, initialPrice);
        assertEq(auctionData.reservePrice, reservePrice);
        assertEq(auctionData.priceDecrement, priceDecrement);
        assertEq(auctionData.duration, duration);
        assertEq(auctionData.ended, false);
        assertEq(auctionData.winner, address(0));
        
        // Check NFT was transferred to auction contract
        assertEq(nft.ownerOf(tokenId), address(auction));
        
        // Check token is locked
        assertTrue(auction.isTokenLocked(address(nft), tokenId));
        
        vm.stopPrank();
    }
    
    function testCreateAuctionInvalidPrice() public {
        vm.startPrank(seller);
        
        vm.expectRevert("Initial price must be greater than reserve price");
        auction.createAuction(
            address(nft),
            tokenId,
            reservePrice, // initial price <= reserve price
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
    }
    
    function testCreateAuctionInvalidDecrement() public {
        vm.startPrank(seller);
        
        vm.expectRevert("Price decrement must be positive");
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            0, // invalid decrement
            duration
        );
        
        vm.stopPrank();
    }
    
    function testCreateAuctionInvalidDuration() public {
        vm.startPrank(seller);
        
        vm.expectRevert("Duration must be positive");
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            0 // invalid duration
        );
        
        vm.stopPrank();
    }
    
    function testCreateAuctionNotOwner() public {
        vm.startPrank(buyer1);
        
        vm.expectRevert("Not token owner");
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
    }
    
    function testCreateAuctionNotApproved() public {
        vm.startPrank(seller);
        nft.setApprovalForAll(address(auction), false);
        
        vm.expectRevert("Contract not approved to transfer token");
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
    }
    
    function testCreateAuctionTokenAlreadyLocked() public {
        vm.startPrank(seller);
        
        // Create first auction
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        // Try to create another auction with same token
        vm.expectRevert("Token already in auction");
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
    }
    
    function testGetCurrentPrice() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        // Price should start at initial price
        assertEq(auction.getCurrentPrice(0), initialPrice);
        
        vm.stopPrank();
    }
    
    function testGetCurrentPriceAfterBlocks() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        // Advance 10 blocks
        vm.roll(block.number + 10);
        
        uint256 expectedPrice = initialPrice - (10 * priceDecrement);
        assertEq(auction.getCurrentPrice(0), expectedPrice);
        
        vm.stopPrank();
    }
    
    function testGetCurrentPriceAtReserve() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        // Advance enough blocks to reach reserve price
        uint256 blocksToReserve = (initialPrice - reservePrice) / priceDecrement;
        vm.roll(block.number + blocksToReserve);
        
        assertEq(auction.getCurrentPrice(0), reservePrice);
        
        // Advance more blocks - should stay at reserve price
        vm.roll(block.number + 10);
        assertEq(auction.getCurrentPrice(0), reservePrice);
        
        vm.stopPrank();
    }
    
    function testBuyAuction() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        uint256 balanceBefore = buyer1.balance;
        
        auction.buy{value: initialPrice}(0);
        
        // Check auction ended
        DutchAuction.Auction memory auctionData = auction.getAuction(0);
        assertEq(auctionData.ended, true);
        assertEq(auctionData.winner, buyer1);
        
        // Check NFT transferred to buyer
        assertEq(nft.ownerOf(tokenId), buyer1);
        
        // Check token unlocked
        assertFalse(auction.isTokenLocked(address(nft), tokenId));
        
        // Check buyer balance decreased
        assertEq(buyer1.balance, balanceBefore - initialPrice);
        
        vm.stopPrank();
    }
    
    function testBuyAuctionWithExcessPayment() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        uint256 balanceBefore = buyer1.balance;
        uint256 excessPayment = 0.5 ether;
        
        auction.buy{value: initialPrice + excessPayment}(0);
        
        // Check buyer received refund
        assertEq(buyer1.balance, balanceBefore - initialPrice);
        
        vm.stopPrank();
    }
    
    function testBuyAuctionInsufficientPayment() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        
        vm.expectRevert("Insufficient payment");
        auction.buy{value: initialPrice - 0.1 ether}(0);
        
        vm.stopPrank();
    }
    
    function testBuyAuctionSellerCannotBuy() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.expectRevert("Seller cannot buy their own auction");
        auction.buy{value: initialPrice}(0);
        
        vm.stopPrank();
    }
    
    function testBuyAuctionAlreadyEnded() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        auction.buy{value: initialPrice}(0);
        
        // Try to buy again
        vm.expectRevert("Auction already ended");
        auction.buy{value: initialPrice}(0);
        
        vm.stopPrank();
    }
    
    function testCancelAuction() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        auction.cancelAuction(0);
        
        // Check auction ended
        DutchAuction.Auction memory auctionData = auction.getAuction(0);
        assertEq(auctionData.ended, true);
        assertEq(auctionData.winner, address(0));
        
        // Check NFT returned to seller
        assertEq(nft.ownerOf(tokenId), seller);
        
        // Check token unlocked
        assertFalse(auction.isTokenLocked(address(nft), tokenId));
        
        vm.stopPrank();
    }
    
    function testCancelAuctionNotSeller() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        
        vm.expectRevert("Only seller can call this");
        auction.cancelAuction(0);
        
        vm.stopPrank();
    }
    
    function testCancelAuctionAlreadyEnded() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        auction.buy{value: initialPrice}(0);
        vm.stopPrank();
        
        vm.startPrank(seller);
        
        vm.expectRevert("Auction already ended");
        auction.cancelAuction(0);
        
        vm.stopPrank();
    }
    
    function testGetTimeRemaining() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        // Should have full duration remaining
        assertEq(auction.getTimeRemaining(0), duration);
        
        // Advance 10 blocks
        vm.roll(block.number + 10);
        assertEq(auction.getTimeRemaining(0), duration - 10);
        
        vm.stopPrank();
    }
    
    function testGetTimeRemainingAfterEnd() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        auction.buy{value: initialPrice}(0);
        vm.stopPrank();
        
        // Should be 0 after auction ends
        assertEq(auction.getTimeRemaining(0), 0);
    }
    
    function testMultipleAuctions() public {
        // Mint another NFT
        vm.startPrank(buyer1);
        nft.mint{value: 0.01 ether}();
        nft.setApprovalForAll(address(auction), true);
        vm.stopPrank();
        
        vm.startPrank(seller);
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        vm.stopPrank();
        
        vm.startPrank(buyer1);
        auction.createAuction(
            address(nft),
            2, // second token
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        vm.stopPrank();
        
        assertEq(auction.getAuctionCount(), 2);
        
        // Both tokens should be locked
        assertTrue(auction.isTokenLocked(address(nft), tokenId));
        assertTrue(auction.isTokenLocked(address(nft), 2));
    }
    
    function testAuctionInvariants() public {
        vm.startPrank(seller);
        
        auction.createAuction(
            address(nft),
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
        
        vm.stopPrank();
        
        // Invariant 1: NFT is locked during active auction
        assertTrue(auction.isTokenLocked(address(nft), tokenId));
        assertEq(nft.ownerOf(tokenId), address(auction));
        
        // Invariant 2: Price is always >= reserve price
        uint256 currentPrice = auction.getCurrentPrice(0);
        assertGe(currentPrice, reservePrice);
        
        vm.startPrank(buyer1);
        auction.buy{value: currentPrice}(0);
        vm.stopPrank();
        
        // Invariant 3: After buy, NFT is unlocked and transferred
        assertFalse(auction.isTokenLocked(address(nft), tokenId));
        assertEq(nft.ownerOf(tokenId), buyer1);
        
        // Invariant 4: Auction is ended
        DutchAuction.Auction memory auctionData = auction.getAuction(0);
        assertEq(auctionData.ended, true);
        assertEq(auctionData.winner, buyer1);
    }
} 