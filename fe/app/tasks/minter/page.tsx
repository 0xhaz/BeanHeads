"use client";
import { useState, useEffect, useMemo } from "react";
import CircularMenu from "@/components/CircularMenu";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import { generateRandomAvatarAttributes as selectRandom } from "@/components/Avatar";
import { useBeanHeads } from "@/context/beanheads";
import { useBridge } from "@/context/bridge";
import {
  BRIDGE_ADDRESS,
  USDC_ADDRESS,
  CHAIN_SELECTOR,
} from "@/constants/contract";
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
  const [mode, setMode] = useState<"local" | "remote">("local");
  const [destSelector, setDestSelector] = useState<bigint | "">("");
  const [isMinting, setIsMinting] = useState(false);

  const { mintGenesis } = useBeanHeads();
  const { sendMintTokenRequest } = useBridge();
  const account = useActiveAccount();
  const chain = useActiveWalletChain();

  const destinationOptions = useMemo(() => {
    return Object.entries(BRIDGE_ADDRESS)
      .map(([chainIdStr, addr]) => {
        const chainId = Number(chainIdStr);
        const selector = CHAIN_SELECTOR[chainId];
        if (!selector) return null;
        return { chainId, selector, address: addr as `0x${string}` };
      })
      .filter(Boolean) as {
      chainId: number;
      selector: bigint;
      address: `0x${string}`;
    }[];
  }, []);

  useEffect(() => {
    setSelectedAttributes(selectRandom());
  }, []);

  const handleRandomize = () => setSelectedAttributes(selectRandom());

  const handleMint = async () => {
    try {
      if (!selectedAttributes) return;
      if (!account) return toast("Please connect your wallet to mint.");
      if (!chain) return toast("Please select a network to mint.");

      setIsMinting(true);
      const amount = BigInt(1);
      const sourceUsdc = USDC_ADDRESS[chain.id];

      if (!sourceUsdc) {
        toast("USDC is not available on the source network.");
        return;
      }

      if (mode === "local") {
        if (typeof mintGenesis !== "function") {
          toast("Local minting function is not available.");
          return;
        }
        await mintGenesis(
          account.address as `0x${string}`,
          selectedAttributes,
          amount,
          sourceUsdc
        );
        toast("Local mint submitted.");
        return;
      }

      // Remote mode: must have a selector
      if (destSelector === "") {
        toast("Please select a valid destination chain.");
        return;
      }

      await sendMintTokenRequest(
        destSelector as bigint, // CCIP selector (uint64)
        account.address as `0x${string}`,
        selectedAttributes,
        amount,
        sourceUsdc // pay with USDC on source chain
      );

      toast("Remote mint request sent.");
    } catch (err) {
      console.error("Minting error:", err);
      toast("An error occurred during minting. Please try again.");
    } finally {
      setIsMinting(false);
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

      {/* Mode toggle */}
      <div className="flex items-center justify-center gap-6 mb-6">
        <div className="flex items-center gap-2">
          <input
            type="radio"
            id="mode-local"
            name="mint-mode"
            className="radio"
            checked={mode === "local"}
            onChange={() => setMode("local")}
          />
          <label htmlFor="mode-local" className="text-lg">
            Mint on current chain
          </label>
        </div>
        <div className="flex items-center gap-2">
          <input
            type="radio"
            id="mode-remote"
            name="mint-mode"
            className="radio"
            checked={mode === "remote"}
            onChange={() => setMode("remote")}
          />
          <label htmlFor="mode-remote" className="text-lg">
            Mint on another chain (pay USDC on source)
          </label>
        </div>
      </div>

      {/* Destination selector (remote only) */}
      {mode === "remote" && (
        <div className="flex items-center justify-center mb-6">
          <label className="mr-3 text-xl">Destination Chain:</label>
          <select
            className="select select-bordered bg-black/30 px-4 py-2 rounded"
            value={
              destSelector === "" ? "" : (destSelector as bigint).toString()
            }
            onChange={e =>
              setDestSelector(e.target.value ? BigInt(e.target.value) : "")
            }
          >
            <option value="">Select chain</option>
            {destinationOptions.map(opt => (
              <option key={opt.chainId} value={opt.selector.toString()}>
                {`Chain ${opt.chainId} — ${opt.address.slice(
                  0,
                  6
                )}…${opt.address.slice(-4)}`}
              </option>
            ))}
          </select>
        </div>
      )}

      <div className="flex justify-between gap-4 mb-10">
        <button
          className="btn-primary justify-center mx-auto px-8 py-4 text-2xl hover:bg-black/50"
          onClick={handleMint}
          disabled={
            !selectedAttributes ||
            !account ||
            !chain ||
            isMinting ||
            (mode === "remote" && destSelector === "")
          }
        >
          {isMinting ? "Minting..." : "Mint Your BeanHead!"}
        </button>
        <button
          className="btn-primary justify-center mx-auto px-8 py-4 text-2xl hover:bg-black/50"
          onClick={handleRandomize}
          disabled={isMinting}
        >
          Randomize It!
        </button>
      </div>
    </div>
  );
};

export default MintPage;
