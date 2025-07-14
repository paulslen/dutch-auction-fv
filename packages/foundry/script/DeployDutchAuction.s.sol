// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../contracts/DutchAuctionNFT.sol";
import "../contracts/DutchAuction.sol";

contract DeployDutchAuction is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy NFT collection
        DutchAuctionNFT nft = new DutchAuctionNFT();
        console.log("DutchAuctionNFT deployed at:", address(nft));

        // Deploy Dutch Auction contract
        DutchAuction auction = new DutchAuction();
        console.log("DutchAuction deployed at:", address(auction));

        vm.stopBroadcast();
    }
} 