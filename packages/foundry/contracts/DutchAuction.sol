// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DutchAuction {
    using Counters for Counters.Counter;
    
    struct Auction {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 startBlock;
        uint256 duration;
        uint256 initialPrice;
        uint256 reservePrice;
        uint256 priceDecrement;
        bool ended;
        address winner;
    }
    
    // State variables
    mapping(uint256 => Auction) public auctions;
    Counters.Counter private _auctionIds;
    
    // Token locking: prevents multiple auctions on the same token
    mapping(bytes32 => bool) public tokenLocked;
    
    // Events
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 initialPrice,
        uint256 reservePrice,
        uint256 priceDecrement,
        uint256 duration
    );
    
    event AuctionBought(
        uint256 indexed auctionId,
        address indexed buyer,
        uint256 price
    );
    
    event AuctionCancelled(uint256 indexed auctionId);
    
    // Modifiers
    modifier auctionExists(uint256 auctionId) {
        require(auctionId < _auctionIds.current(), "Auction does not exist");
        _;
    }
    
    modifier auctionNotEnded(uint256 auctionId) {
        require(!auctions[auctionId].ended, "Auction already ended");
        _;
    }
    
    modifier onlySeller(uint256 auctionId) {
        require(auctions[auctionId].seller == msg.sender, "Only seller can call this");
        _;
    }
    
    // Helper function to create token hash
    function _getTokenHash(address nftAddress, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nftAddress, tokenId));
    }
    
    /**
     * @dev Creates a new Dutch auction
     * @param nftAddress The address of the NFT contract
     * @param tokenId The ID of the token to auction
     * @param initialPrice The starting price in wei
     * @param reservePrice The minimum price in wei
     * @param priceDecrement The amount to decrease price per block
     * @param duration The duration of the auction in blocks
     */
    function createAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 initialPrice,
        uint256 reservePrice,
        uint256 priceDecrement,
        uint256 duration
    ) external {
        require(initialPrice > reservePrice, "Initial price must be greater than reserve price");
        require(priceDecrement > 0, "Price decrement must be positive");
        require(duration > 0, "Duration must be positive");
        
        // Check if sender owns the token
        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "Not token owner");
        
        // Check if token is already locked
        bytes32 tokenHash = _getTokenHash(nftAddress, tokenId);
        require(!tokenLocked[tokenHash], "Token already in auction");
        
        // Check if contract is approved to transfer the token
        require(
            IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) ||
            IERC721(nftAddress).getApproved(tokenId) == address(this),
            "Contract not approved to transfer token"
        );
        
        // Transfer token to contract (escrow)
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);
        
        // Lock the token
        tokenLocked[tokenHash] = true;
        
        // Create auction
        uint256 auctionId = _auctionIds.current();
        auctions[auctionId] = Auction({
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            startBlock: block.number,
            duration: duration,
            initialPrice: initialPrice,
            reservePrice: reservePrice,
            priceDecrement: priceDecrement,
            ended: false,
            winner: address(0)
        });
        
        _auctionIds.increment();
        
        emit AuctionCreated(
            auctionId,
            msg.sender,
            nftAddress,
            tokenId,
            initialPrice,
            reservePrice,
            priceDecrement,
            duration
        );
    }
    
    /**
     * @dev Gets the current price of an auction
     * @param auctionId The ID of the auction
     * @return The current price in wei
     */
    function getCurrentPrice(uint256 auctionId) 
        external 
        view 
        auctionExists(auctionId) 
        returns (uint256) 
    {
        Auction storage auction = auctions[auctionId];
        
        if (auction.ended) {
            return 0;
        }
        
        uint256 blocksElapsed = block.number - auction.startBlock;
        uint256 priceDecrease = blocksElapsed * auction.priceDecrement;
        
        if (priceDecrease >= auction.initialPrice - auction.reservePrice) {
            return auction.reservePrice;
        }
        
        return auction.initialPrice - priceDecrease;
    }
    
    /**
     * @dev Buys an auction at the current price
     * @param auctionId The ID of the auction to buy
     */
    function buy(uint256 auctionId) 
        external 
        payable 
        auctionExists(auctionId) 
        auctionNotEnded(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        
        // Prevent seller from buying their own auction
        require(msg.sender != auction.seller, "Seller cannot buy their own auction");
        
        uint256 currentPrice = this.getCurrentPrice(auctionId);
        require(msg.value >= currentPrice, "Insufficient payment");
        
        // End the auction
        auction.ended = true;
        auction.winner = msg.sender;
        
        // Transfer NFT to buyer
        IERC721(auction.nftAddress).transferFrom(address(this), msg.sender, auction.tokenId);
        
        // Unlock the token
        bytes32 tokenHash = _getTokenHash(auction.nftAddress, auction.tokenId);
        tokenLocked[tokenHash] = false;
        
        // Transfer ETH to seller
        payable(auction.seller).transfer(currentPrice);
        
        // Refund excess ETH to buyer
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }
        
        emit AuctionBought(auctionId, msg.sender, currentPrice);
    }
    
    /**
     * @dev Cancels an auction (only by seller)
     * @param auctionId The ID of the auction to cancel
     */
    function cancelAuction(uint256 auctionId) 
        external 
        auctionExists(auctionId) 
        auctionNotEnded(auctionId) 
        onlySeller(auctionId) 
    {
        Auction storage auction = auctions[auctionId];
        
        // End the auction
        auction.ended = true;
        
        // Return NFT to seller
        IERC721(auction.nftAddress).transferFrom(address(this), auction.seller, auction.tokenId);
        
        // Unlock the token
        bytes32 tokenHash = _getTokenHash(auction.nftAddress, auction.tokenId);
        tokenLocked[tokenHash] = false;
        
        emit AuctionCancelled(auctionId);
    }
    
    /**
     * @dev Gets auction details
     * @param auctionId The ID of the auction
     * @return All auction details
     */
    function getAuction(uint256 auctionId) 
        external 
        view 
        auctionExists(auctionId) 
        returns (Auction memory) 
    {
        return auctions[auctionId];
    }
    
    /**
     * @dev Gets the total number of auctions created
     * @return The total number of auctions
     */
    function getAuctionCount() external view returns (uint256) {
        return _auctionIds.current();
    }
    
    /**
     * @dev Checks if a token is locked in an auction
     * @param nftAddress The address of the NFT contract
     * @param tokenId The ID of the token
     * @return True if the token is locked
     */
    function isTokenLocked(address nftAddress, uint256 tokenId) external view returns (bool) {
        return tokenLocked[_getTokenHash(nftAddress, tokenId)];
    }
    
    /**
     * @dev Gets the time remaining for an auction (in blocks)
     * @param auctionId The ID of the auction
     * @return The number of blocks remaining
     */
    function getTimeRemaining(uint256 auctionId) 
        external 
        view 
        auctionExists(auctionId) 
        returns (uint256) 
    {
        Auction storage auction = auctions[auctionId];
        
        if (auction.ended) {
            return 0;
        }
        
        uint256 blocksElapsed = block.number - auction.startBlock;
        if (blocksElapsed >= auction.duration) {
            return 0;
        }
        
        return auction.duration - blocksElapsed;
    }
} 