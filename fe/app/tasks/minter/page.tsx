"use client";
import { useState, useEffect, use, useMemo } from "react";
import CircularMenu from "@/components/CircularMenu";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import {
  Avatar,
  generateRandomAvatarAttributes as selectRandom,
} from "@/components/Avatar";
import { useBeanHeads } from "@/context/beanheads";
import { useBridge } from "@/context/bridge";
import { BRIDGE_ADDRESS, USDC_ADDRESS } from "@/constants/contract";
import { toast } from "sonner";

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
  const [destChainId, setDestChainId] = useState<number | "">("");
  const [mode, setMode] = useState<"local" | "remote">("local");
  const [isMinting, setIsMinting] = useState(false);

  const { mintGenesis } = useBeanHeads();
  const account = useActiveAccount();
  const chain = useActiveWalletChain();
  const { sendMintTokenRequest } = useBridge();

  const destinationOptions = useMemo(() => {
    return Object.entries(BRIDGE_ADDRESS).map(([id, addr]) => ({
      id: Number(id),
      address: addr as `0x${string}`,
    }));
  }, []);

  useEffect(() => {
    setSelectedAttributes(selectRandom());
  }, []);

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
      toast("Please connect your wallet to mint.");
      return;
    }
    if (!chain) {
      toast("Please select a network to mint.");
      return;
    }

    const amount = BigInt(1); // Minting 1 NFT

    const effectiveDest =
      mode === "local"
        ? chain.id
        : typeof destChainId === "number"
        ? destChainId
        : undefined;

    if (!effectiveDest) {
      toast("Please select a valid destination chain.");
      return;
    }

    setIsMinting(true);

    const sourceUsdc = USDC_ADDRESS[chain.id];

    if (effectiveDest === chain.id) {
      if (typeof mintGenesis !== "function") {
        toast("Local minting function is not available.");
        return;
      }

      if (!sourceUsdc) {
        toast("USDC is not available on the source network.");
        return;
      }

      const tx = await mintGenesis(
        account.address as `0x${string}`,
        selectedAttributes,
        amount,
        sourceUsdc
      );

      toast("Local minting successful!");
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
          toast("Minting successful!");
        })
        .catch(err => {
          console.error("Minting error:", err);
          toast("Minting failed. Please try again.");
        });
    } else {
      toast("Minting function is not available.");
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
