"use client";

import { useEffect, useState } from "react";
import { AuctionCard } from "~~/components/AuctionCard";
import { CreateAuctionForm } from "~~/components/CreateAuctionForm";

interface Auction {
  seller: string;
  nftAddress: string;
  tokenId: bigint;
  startBlock: bigint;
  duration: bigint;
  initialPrice: bigint;
  reservePrice: bigint;
  priceDecrement: bigint;
  ended: boolean;
  winner: string;
}

export default function Home() {
  const [auctions, setAuctions] = useState<Array<{ id: number; data: Auction }>>([]);
  const [showCreateForm, setShowCreateForm] = useState(false);

  // Temporarily disabled until contract is deployed
  // const { data: auctionCount } = useScaffoldReadContract({
  //   contractName: "DutchAuction" as any,
  //   functionName: "getAuctionCount",
  // });

  // Fetch all auctions
  useEffect(() => {
    const fetchAuctions = async () => {
      // Temporarily disabled until contract is deployed
      setAuctions([]);
    };

    fetchAuctions();
  }, []);

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Welcome to</span>
            <span className="block text-4xl font-bold">Dutch Auction dApp</span>
          </h1>
          <p className="text-center text-lg">Create and participate in Dutch auctions for ERC721 tokens</p>
        </div>

        <div className="flex-grow bg-base-300 w-full mt-16 px-8 py-12">
          <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <h3 className="text-xl font-bold">Create Auction</h3>
              <p className="text-base-content/70">List your NFT for sale with a decreasing price over time</p>
              <button className="btn btn-primary mt-4" onClick={() => setShowCreateForm(true)}>
                Start Auction
              </button>
            </div>

            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <h3 className="text-xl font-bold">Buy NFTs</h3>
              <p className="text-base-content/70">Browse active auctions and buy NFTs at the current price</p>
            </div>

            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <h3 className="text-xl font-bold">Mint NFTs</h3>
              <p className="text-base-content/70">Create your own NFTs to auction or collect</p>
            </div>
          </div>
        </div>

        {/* Create Auction Form Modal */}
        {showCreateForm && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-base-100 p-6 rounded-lg max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-2xl font-bold">Create New Auction</h2>
                <button className="btn btn-ghost btn-sm" onClick={() => setShowCreateForm(false)}>
                  ✕
                </button>
              </div>
              <CreateAuctionForm />
            </div>
          </div>
        )}

        {/* Active Auctions Section */}
        <div className="flex-grow bg-base-300 w-full mt-16 px-8 py-12">
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold mb-4">Active Auctions</h2>
            <p className="text-lg">Total auctions created: Coming soon after deployment</p>
          </div>

          {auctions.length === 0 ? (
            <div className="text-center">
              <div className="bg-base-100 p-8 rounded-lg max-w-md mx-auto">
                <h3 className="text-xl font-semibold mb-2">No Active Auctions</h3>
                <p className="text-base-content/70 mb-4">
                  Be the first to create an auction! (Available after contract deployment)
                </p>
                <button className="btn btn-primary" onClick={() => setShowCreateForm(true)}>
                  Create First Auction
                </button>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {auctions.map(({ id, data }) => (
                <AuctionCard
                  key={id}
                  auctionId={id}
                  nftAddress={data.nftAddress}
                  tokenId={Number(data.tokenId)}
                  seller={data.seller}
                  initialPrice={data.initialPrice}
                  reservePrice={data.reservePrice}
                  priceDecrement={data.priceDecrement}
                  duration={data.duration}
                  startBlock={data.startBlock}
                  ended={data.ended}
                  winner={data.winner}
                />
              ))}
            </div>
          )}
        </div>

        {/* How It Works Section */}
        <div className="flex-grow bg-base-300 w-full mt-16 px-8 py-12">
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold mb-4">How Dutch Auctions Work</h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
            <div className="bg-base-100 p-6 rounded-lg text-center">
              <div className="text-4xl mb-4">1</div>
              <h3 className="text-xl font-semibold mb-2">Set Starting Price</h3>
              <p className="text-base-content/70">
                Sellers set an initial price and a reserve price. The auction starts at the initial price.
              </p>
            </div>

            <div className="bg-base-100 p-6 rounded-lg text-center">
              <div className="text-4xl mb-4">2</div>
              <h3 className="text-xl font-semibold mb-2">Price Decreases</h3>
              <p className="text-base-content/70">
                The price automatically decreases over time until someone buys or the reserve price is reached.
              </p>
            </div>

            <div className="bg-base-100 p-6 rounded-lg text-center">
              <div className="text-4xl mb-4">3</div>
              <h3 className="text-xl font-semibold mb-2">First to Buy Wins</h3>
              <p className="text-base-content/70">
                The first person to accept the current price gets the NFT, and the auction ends immediately.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
