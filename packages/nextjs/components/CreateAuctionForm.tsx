"use client";

import { useEffect, useState } from "react";
import { useAccount } from "wagmi";
import { AddressInput } from "~~/components/scaffold-eth";
import { EtherInput } from "~~/components/scaffold-eth";

export const CreateAuctionForm = () => {
  const { address } = useAccount();
  const [nftAddress, setNftAddress] = useState<string>("");
  const [tokenId, setTokenId] = useState<string>("");
  const [initialPrice, setInitialPrice] = useState<string>("");
  const [reservePrice, setReservePrice] = useState<string>("");
  const [priceDecrement, setPriceDecrement] = useState<string>("");
  const [duration, setDuration] = useState<string>("");
  const [isLoading, setIsLoading] = useState(false);

  // Read user's NFT balance - temporarily disabled until contract is deployed
  // const { data: balance } = useScaffoldReadContract({
  //   contractName: "DutchAuctionNFT" as any,
  //   functionName: "balanceOf",
  //   args: address ? [address] : undefined,
  // });

  // Read user's tokens
  useEffect(() => {
    const fetchUserTokens = async () => {
      // Temporarily disabled until contract is deployed
    };

    fetchUserTokens();
  }, [address]);

  const handleCreateAuction = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!address || !nftAddress || !tokenId || !initialPrice || !reservePrice || !priceDecrement || !duration) {
      return;
    }

    setIsLoading(true);
    try {
      // Temporarily disabled until contract is deployed
      console.log("Create auction functionality will be available after contract deployment");
      console.log("Auction details:", {
        nftAddress,
        tokenId,
        initialPrice,
        reservePrice,
        priceDecrement,
        duration,
      });

      // Reset form
      setNftAddress("");
      setTokenId("");
      setInitialPrice("");
      setReservePrice("");
      setPriceDecrement("");
      setDuration("");
    } catch (error) {
      console.error("Error creating auction:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleMintNFT = async () => {
    if (!address) return;

    setIsLoading(true);
    try {
      // Temporarily disabled until contract is deployed
      console.log("Mint NFT functionality will be available after contract deployment");
    } catch (error) {
      console.error("Error minting NFT:", error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="card bg-base-100 shadow-xl border border-base-300">
      <div className="card-body">
        <h2 className="card-title">Create New Auction</h2>

        {!address ? (
          <div className="alert alert-warning">
            <span>Please connect your wallet to create an auction</span>
          </div>
        ) : (
          <form onSubmit={handleCreateAuction} className="space-y-4">
            {/* Mint NFT Section */}
            <div className="bg-base-200 p-4 rounded-lg">
              <h3 className="text-lg font-semibold mb-2">Step 1: Get an NFT</h3>
              <p className="text-sm text-base-content/70 mb-3">
                You need an NFT to auction. Mint one for 0.01 ETH or use an existing one.
              </p>
              <button type="button" className="btn btn-primary" onClick={handleMintNFT} disabled={isLoading}>
                {isLoading ? "Minting..." : "Mint NFT (0.01 ETH) - Coming Soon"}
              </button>
              <p className="text-sm mt-2">Your NFT balance: Coming soon after deployment</p>
            </div>

            {/* Auction Form */}
            <div className="space-y-4">
              <h3 className="text-lg font-semibold">Step 2: Create Auction</h3>

              <div className="form-control">
                <label className="label">
                  <span className="label-text">NFT Contract Address</span>
                </label>
                <AddressInput value={nftAddress} onChange={setNftAddress} placeholder="0x..." />
              </div>

              <div className="form-control">
                <label className="label">
                  <span className="label-text">Token ID</span>
                </label>
                <input
                  type="number"
                  placeholder="1"
                  className="input input-bordered"
                  value={tokenId}
                  onChange={e => setTokenId(e.target.value)}
                  min="0"
                />
              </div>

              <div className="form-control">
                <label className="label">
                  <span className="label-text">Initial Price (ETH)</span>
                </label>
                <EtherInput value={initialPrice} onChange={setInitialPrice} placeholder="1.0" />
              </div>

              <div className="form-control">
                <label className="label">
                  <span className="label-text">Reserve Price (ETH)</span>
                </label>
                <EtherInput value={reservePrice} onChange={setReservePrice} placeholder="0.1" />
              </div>

              <div className="form-control">
                <label className="label">
                  <span className="label-text">Price Decrement per Block (ETH)</span>
                </label>
                <EtherInput value={priceDecrement} onChange={setPriceDecrement} placeholder="0.01" />
              </div>

              <div className="form-control">
                <label className="label">
                  <span className="label-text">Duration (blocks)</span>
                </label>
                <input
                  type="number"
                  placeholder="100"
                  className="input input-bordered"
                  value={duration}
                  onChange={e => setDuration(e.target.value)}
                  min="1"
                />
              </div>

              <button
                type="submit"
                className="btn btn-primary w-full"
                disabled={
                  isLoading || !nftAddress || !tokenId || !initialPrice || !reservePrice || !priceDecrement || !duration
                }
              >
                {isLoading ? "Creating Auction..." : "Create Auction (Coming Soon)"}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};
