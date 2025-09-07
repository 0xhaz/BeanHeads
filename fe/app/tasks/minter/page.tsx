"use client";
import { useState, useEffect, use } from "react";
import CircularMenu from "@/components/CircularMenu";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import {
  Avatar,
  generateRandomAvatarAttributes as selectRandom,
} from "@/components/Avatar";
import { useBeanHeads } from "@/context/beanheads";
import { USDC_ADDRESS } from "@/constants/contract";

const pages = [
  ["Hair", "/icons/hair.svg"],
  ["Body", "/icons/body.svg"],
  ["Clothes", "/icons/clothing.svg"],
  ["Facial", "/icons/face.svg"],
  ["Accessories", "/icons/accessories.svg"],
  ["Misc", "/icons/utils.svg"],
];

const MintPage = () => {
  const [selectedAttributes, setSelectedAttributes] = useState<any | null>(
    null
  );
  const { mintGenesis } = useBeanHeads();
  const account = useActiveAccount();
  const chain = useActiveWalletChain();

  useEffect(() => {
    const randomAttributes = selectRandom();
    console.log("Random Attributes:", randomAttributes);
    setSelectedAttributes(randomAttributes);
  }, []);

  const handleRandomize = () => {
    const randomAttributes = selectRandom();
    console.log("Randomized Attributes:", randomAttributes);
    setSelectedAttributes(randomAttributes);
  };

  const handleMint = () => {
    if (!selectedAttributes) return;
    if (!account) {
      alert("Please connect your wallet to mint.");
      return;
    }
    if (!chain) {
      alert("Please select a network to mint.");
      return;
    }

    if (typeof mintGenesis === "function") {
      mintGenesis(
        account.address as `0x${string}`,
        selectedAttributes,
        BigInt(1),
        USDC_ADDRESS[chain.id]
      )
        .then(tx => {
          console.log("Minting transaction:", tx);
          alert("Minting successful!");
        })
        .catch(err => {
          console.error("Minting error:", err);
          alert("Minting failed. Please try again.");
        });
    } else {
      alert("Minting function is not available.");
    }
  };

  return (
    <div>
      <section>
        <div className="flex items-center justify-center h-[75vh] w-full">
          <CircularMenu
            pages={pages as [string, string][]}
            selectedAttributes={selectedAttributes}
            setSelectedAttributes={setSelectedAttributes}
          />
        </div>
      </section>
      <div className="flex justify-between gap-4 mb-10">
        <button
          className="btn-primary justify-center mx-auto px-8 py-4 text-2xl hover:bg-black/50"
          onClick={handleMint}
        >
          Mint Your NFT
        </button>
        <button
          className="btn-primary justify-center mx-auto px-8 py-4 text-2xl hover:bg-black/50"
          onClick={handleRandomize}
        >
          Randomize It!
        </button>
      </div>
    </div>
  );
};

export default MintPage;
