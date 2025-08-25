import MainCard from "@/components/MainCard";
import TransactionList from "@/components/TransactionList";
import React from "react";

const Page = () => {
  return (
    <div className="p-6">
      <h1 className="text-2xl underline">
        BeanHeads Fully On-Chain NFT Collections
      </h1>
      <section className="home-section mb-5 grid grid-cols-4 gap-4">
        <MainCard
          id="minter"
          title="Mint"
          image="/images/mint.svg"
          description="Create your own custom NFT like a true artist"
          color="#ffda6e"
        />
        <MainCard
          id="breeder"
          title="Breeder"
          image="/images/breeder.svg"
          description="Breed your BeanHeads and gain unique traits"
          color="#e5d0ff"
        />
        <MainCard
          id="bridge"
          title="Bridge"
          image="/images/bridge.svg"
          description="Bridge your NFTs to your preferred network"
          color="#bde7ff"
        />
        <MainCard
          id="marketplace"
          title="Marketplace"
          image="/images/marketplace.svg"
          description="Trade your NFTs with your peers"
          color="#ffcccb"
        />
        <MainCard
          id="my-collections"
          title="My Collections"
          image="/images/wallet.svg"
          description="View and manage your NFT collections"
          color="#f4c6c2"
        />
        <MainCard
          id="transactions"
          title="Transactions"
          image="/icons/coding.svg"
          description="View transaction history and details"
          color="#c8ffdf"
        />
        <MainCard
          id="admin"
          title="Admin"
          image="/images/admin.svg"
          description="Manage the platform and its users"
          color="#f6c2f8"
        />
      </section>
      <section className="home-section">
        <TransactionList
          title="Recent Transactions"
          transactions={[]}
          classNames="w-full"
        />
      </section>
    </div>
  );
};

export default Page;
