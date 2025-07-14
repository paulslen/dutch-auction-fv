"use client";

import { useEffect, useState } from "react";
import { formatEther } from "viem";
import { useAccount } from "wagmi";
import { Address } from "~~/components/scaffold-eth";
import { EtherInput } from "~~/components/scaffold-eth";

interface AuctionCardProps {
  auctionId: number;
  nftAddress: string;
  tokenId: number;
  seller: string;
  initialPrice: bigint;
  reservePrice: bigint;
  priceDecrement: bigint;
  duration: bigint;
  startBlock: bigint;
  ended: boolean;
  winner: string;
}

export const AuctionCard = ({
  auctionId,
  tokenId,
  seller,
  initialPrice,
  reservePrice,
  priceDecrement,
  duration,
  ended,
  winner,
}: AuctionCardProps) => {
  const { address } = useAccount();
  const [currentPrice, setCurrentPrice] = useState<bigint>(0n);
  const [timeRemaining, setTimeRemaining] = useState<bigint>(0n);
  const [buyAmount, setBuyAmount] = useState<string>("");

  // Read current price - temporarily disabled until contract is deployed
  // const { data: priceData } = useScaffoldReadContract({
  //   contractName: "DutchAuction" as any,
  //   functionName: "getCurrentPrice",
  //   args: [BigInt(auctionId)],
  // });

  // Read time remaining - temporarily disabled until contract is deployed
  // const { data: timeData } = useScaffoldReadContract({
  //   contractName: "DutchAuction" as any,
  //   functionName: "getTimeRemaining",
  //   args: [BigInt(auctionId)],
  // });

  // Read token URI for NFT display - temporarily disabled until contract is deployed
  // const { data: tokenURI } = useScaffoldReadContract({
  //   contractName: "DutchAuctionNFT" as any,
  //   functionName: "tokenURI",
  //   args: [BigInt(tokenId)],
  // });

  useEffect(() => {
    // Temporarily set current price to initial price
    setCurrentPrice(initialPrice);
    if (!buyAmount) {
      setBuyAmount(formatEther(initialPrice));
    }
  }, [initialPrice, buyAmount]);

  useEffect(() => {
    // Temporarily set time remaining to duration
    setTimeRemaining(duration);
  }, [duration]);

  const handleBuy = async () => {
    if (!address || ended) return;

    try {
      // Temporarily disabled until contract is deployed
      console.log("Buy functionality will be available after contract deployment");
      // await writeAuctionAsync({
      //   functionName: "buy",
      //   args: [BigInt(auctionId)],
      //   value: parseEther(buyAmount),
      // });
    } catch (error) {
      console.error("Error buying auction:", error);
    }
  };

  const handleCancel = async () => {
    if (!address || address !== seller || ended) return;

    try {
      // Temporarily disabled until contract is deployed
      console.log("Cancel functionality will be available after contract deployment");
      // await writeAuctionAsync({
      //   functionName: "cancelAuction",
      //   args: [BigInt(auctionId)],
      // });
    } catch (error) {
      console.error("Error cancelling auction:", error);
    }
  };

  const isSeller = address === seller;
  const canBuy = !ended && !isSeller && address;

  return (
    <div className="card bg-base-100 shadow-xl border border-base-300">
      <div className="card-body">
        <div className="flex justify-between items-start mb-4">
          <h2 className="card-title">Auction #{auctionId}</h2>
          <div className="badge badge-primary">Token #{tokenId}</div>
        </div>

        {/* NFT Display */}
        <div className="mb-4">
          <div className="w-full h-48 bg-base-200 rounded-lg flex items-center justify-center">
            <div className="text-center">
              <p className="text-lg font-semibold">NFT #{tokenId}</p>
              <p className="text-sm text-base-content/70">Image will load after deployment</p>
            </div>
          </div>
        </div>

        {/* Auction Details */}
        <div className="space-y-2 mb-4">
          <div className="flex justify-between">
            <span className="text-sm text-base-content/70">Seller:</span>
            <Address address={seller} />
          </div>
          {ended && winner !== "0x0000000000000000000000000000000000000000" && (
            <div className="flex justify-between">
              <span className="text-sm text-base-content/70">Winner:</span>
              <Address address={winner} />
            </div>
          )}
          <div className="flex justify-between">
            <span className="text-sm text-base-content/70">Initial Price:</span>
            <span className="font-mono">{formatEther(initialPrice)} ETH</span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm text-base-content/70">Reserve Price:</span>
            <span className="font-mono">{formatEther(reservePrice)} ETH</span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm text-base-content/70">Price Decrement:</span>
            <span className="font-mono">{formatEther(priceDecrement)} ETH/block</span>
          </div>
          <div className="flex justify-between">
            <span className="text-sm text-base-content/70">Duration:</span>
            <span className="font-mono">{duration.toString()} blocks</span>
          </div>
        </div>

        {/* Current Status */}
        {!ended ? (
          <div className="space-y-2 mb-4">
            <div className="flex justify-between">
              <span className="text-sm text-base-content/70">Current Price:</span>
              <span className="font-mono text-lg font-bold text-primary">{formatEther(currentPrice)} ETH</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-base-content/70">Time Remaining:</span>
              <span className="font-mono">{timeRemaining.toString()} blocks</span>
            </div>
          </div>
        ) : (
          <div className="alert alert-info mb-4">
            <span>Auction {winner !== "0x0000000000000000000000000000000000000000" ? "Sold" : "Cancelled"}</span>
          </div>
        )}

        {/* Action Buttons */}
        <div className="card-actions justify-end">
          {!ended && canBuy && (
            <div className="flex flex-col w-full space-y-2">
              <EtherInput value={buyAmount} onChange={setBuyAmount} placeholder="Amount to pay" disabled={ended} />
              <button className="btn btn-primary w-full" onClick={handleBuy} disabled={ended || !buyAmount}>
                Buy Now (Coming Soon)
              </button>
            </div>
          )}
          {!ended && isSeller && (
            <button className="btn btn-secondary" onClick={handleCancel} disabled={ended}>
              Cancel Auction (Coming Soon)
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
