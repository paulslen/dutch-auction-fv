// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DutchAuctionNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    
    // Base URI for token metadata
    string private _baseTokenURI;
    
    // Mint price (can be set by owner)
    uint256 public mintPrice = 0.01 ether;
    
    // Maximum supply
    uint256 public constant MAX_SUPPLY = 1000;
    
    constructor() ERC721("Dutch Auction NFT", "DANFT") Ownable(msg.sender) {
        _baseTokenURI = "https://api.example.com/metadata/";
    }
    
    function mint() external payable {
        require(msg.value >= mintPrice, "Insufficient payment");
        require(_tokenIds.current() < MAX_SUPPLY, "Max supply reached");
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        _safeMint(msg.sender, newTokenId);
    }
    
    function mintTo(address to) external payable {
        require(msg.value >= mintPrice, "Insufficient payment");
        require(_tokenIds.current() < MAX_SUPPLY, "Max supply reached");
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        _safeMint(to, newTokenId);
    }
    
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }
    
    // Function to get token URI for a specific token
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_baseURI(), _toString(tokenId)));
    }
    
    // Helper function to convert uint256 to string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    // Withdraw function for owner
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
} 