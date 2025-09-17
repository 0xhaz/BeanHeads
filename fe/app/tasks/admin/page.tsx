"use client";

import { useState, useEffect } from "react";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import { useBeanHeads } from "@/context/beanheads";
import { USDC_ADDRESS } from "@/constants/contract";

function isAddress(addr: string): addr is `0x${string}` {
  return /^0x[a-fA-F0-9]{40}$/.test(addr);
}

function formatUnits(value: bigint, decimals: number): string {
  const neg = value < BigInt(0);
  const v = neg ? -value : value;
  const base = BigInt(10) ** BigInt(decimals);
  const i = v / base;
  const f = (v % base).toString().padStart(decimals, "0").replace(/0+$/, "");
  return `${neg ? "-" : ""}${i.toString()}${f ? "." + f : ""}`;
}

const Admin = () => {
  const account = useActiveAccount();
  const chain = useActiveWalletChain();

  const {
    setMintPrice,
    setAllowedToken,
    addPriceFeed,
    withdraw,
    authorizeBreeder,
    setRemoteBridge,
    balanceOfERC20,
  } = useBeanHeads();

  const [mintPriceUsd, setMintPriceUsd] = useState("");
  const [allowedTokenAddr, setAllowedTokenAddr] = useState("");
  const [allowedFlag, setAllowedFlag] = useState(true);
  const [pfTokenAddr, setPfTokenAddr] = useState("");
  const [pfFeedAddr, setPfFeedAddr] = useState("");

  const [withdrawToken, setWithdrawToken] = useState("");
  const [usdcAddr, setUsdcAddr] = useState<`0x${string}` | null>(null);
  const [usdcBal, setUsdcBal] = useState<bigint | null>(null);
  const [loadingBal, setLoadingBal] = useState(false);

  const [breederAddr, setBreederAddr] = useState("");
  const [remoteChainId, setRemoteChainId] = useState("");
  const [remoteBridgeAddr, setRemoteBridgeAddr] = useState("");

  const [balResult, setBalResult] = useState<string>("");

  // const USDC_DECIMALS = 18;
  const USDC_DECIMALS = 6;
  const parseUsdTo1e18 = (s: string): bigint => {
    const t = s.trim();
    if (!t) throw new Error("Empty amount");
    if (!/^\d+(\.\d+)?$/.test(t)) throw new Error("Invalid number format");
    const [i, f = ""] = t.split(".");
    const frac = f.padEnd(USDC_DECIMALS, "0").slice(0, USDC_DECIMALS);
    return (
      BigInt(i) * BigInt(10) ** BigInt(USDC_DECIMALS) + BigInt(frac || "0")
    );
  };

  const toast = (m: string) => alert(m);

  useEffect(() => {
    if (!chain?.id) {
      setUsdcAddr(null);
      setUsdcBal(null);
      return;
    }
    setUsdcAddr(USDC_ADDRESS[chain.id] || null);
    setUsdcBal(null);
  }, [chain?.id]);

  async function refreshUsdcBalance() {
    if (!chain || !usdcAddr) {
      alert("Select a network with USDC address");
      return;
    }

    try {
      setLoadingBal(true);
      const bal = await balanceOfERC20(usdcAddr, chain);
      setUsdcBal(bal);
    } catch (e: any) {
      setUsdcBal(null);
      alert(e?.message ?? "Failed to fetch USDC balance");
    } finally {
      setLoadingBal(false);
    }
  }

  async function withdrawUsdc() {
    if (!usdcAddr) {
      alert("No USDC address for this network");
      return;
    }
    try {
      await withdraw(usdcAddr);
      alert("Withdraw executed");
      refreshUsdcBalance();
    } catch (e: any) {
      alert(e?.message ?? "Failed to withdraw USDC");
    }
  }

  return (
    <div className="p-8 min-h-screen bg-gray-100 flex justify-around mx-auto">
      <h1 className="text-2xl font-bold underline">Admin Panel</h1>

      <div className="p-8 space-y-10 flex flex-col md:flex-row md:space-x-16 md:space-y-0">
        {/* Column A */}
        <div className="space-y-8">
          <section className="space-y-3">
            <h2 className="text-xl font-semibold">Set Mint Price (USD)</h2>
            <label className="flex flex-col gap-2">
              <input
                value={mintPriceUsd}
                onChange={e => setMintPriceUsd(e.target.value)}
                placeholder='e.g. "10.00"'
                className="border p-2 rounded w-64 bg-white"
              />
            </label>
            <button
              className="px-4 py-2 font-bold bg-blue-600 text-white rounded hover:bg-blue-700 cursor-pointer"
              onClick={async () => {
                try {
                  const v = parseUsdTo1e18(mintPriceUsd);
                  if (!setMintPrice)
                    throw new Error("setMintPrice is not available");
                  await setMintPrice(v);
                  toast(`Mint price set to $${mintPriceUsd}`);
                } catch (e: any) {
                  toast(e?.message ?? "Failed to set mint price");
                }
              }}
            >
              Set Mint Price
            </button>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-semibold">Set Allowed Token</h2>
            <input
              value={allowedTokenAddr}
              onChange={e => setAllowedTokenAddr(e.target.value)}
              placeholder="Token Address 0x..."
              className="border p-2 rounded w-80 bg-white"
            />
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={allowedFlag}
                onChange={e => setAllowedFlag(e.target.checked)}
              />
              <span>Allow</span>
            </label>
            <button
              className="px-4 py-2 font-bold bg-blue-600 text-white rounded hover:bg-blue-700 cursor-pointer"
              onClick={async () => {
                try {
                  if (!isAddress(allowedTokenAddr))
                    throw new Error("Invalid token address");
                  if (!setAllowedToken)
                    throw new Error("setAllowedToken is not available");
                  await setAllowedToken(
                    allowedTokenAddr as `0x${string}`,
                    allowedFlag
                  );
                  toast(`Allowed token ${allowedTokenAddr} = ${allowedFlag}`);
                } catch (e: any) {
                  toast(e?.message ?? "Failed to set allowed token");
                }
              }}
            >
              Save
            </button>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-semibold">Add Price Feed</h2>
            <label className="flex flex-col gap-2">
              <input
                value={pfTokenAddr}
                onChange={e => setPfTokenAddr(e.target.value)}
                placeholder="Token Address 0x..."
                className="border p-2 rounded w-80 bg-white"
              />
              <input
                value={pfFeedAddr}
                onChange={e => setPfFeedAddr(e.target.value)}
                placeholder="Aggregator Feed 0x..."
                className="border p-2 rounded w-80 bg-white"
              />
            </label>
            <button
              className="px-4 py-2 bg-blue-600 font-bold text-white rounded hover:bg-blue-700 cursor-pointer"
              onClick={async () => {
                try {
                  if (!isAddress(pfTokenAddr) || !isAddress(pfFeedAddr))
                    throw new Error("Invalid addresses");
                  if (!addPriceFeed)
                    throw new Error("addPriceFeed is not available");
                  await addPriceFeed(
                    pfTokenAddr as `0x${string}`,
                    pfFeedAddr as `0x${string}`
                  );
                  toast(`Added price feed ${pfFeedAddr} for ${pfTokenAddr}`);
                } catch (e: any) {
                  toast(e?.message ?? "Failed to add price feed");
                }
              }}
            >
              Add Price Feed
            </button>
          </section>
        </div>

        {/* Column B */}
        <div className="space-y-8">
          {/* Contract ERC20 Balance */}
          <section className="space-y-3">
            <h2 className="text-xl font-semibold">Contract ERC20 Balance</h2>

            <div className="text-sm">
              Network: {chain?.name || "-"}
              <br />
              Token Address: {usdcAddr ?? "not supported"}
            </div>

            <label className="flex flex-col gap-2">
              <button
                className="px-4 py-2 font-bold bg-blue-600 text-white rounded hover:bg-blue-700 cursor-pointer w-64"
                disabled={!usdcAddr || loadingBal || !chain}
                onClick={refreshUsdcBalance}
              >
                {loadingBal ? "Fetching..." : "Refresh Balance"}
              </button>

              {usdcBal !== null && (
                <div className="text-sm text-gray-800">
                  Balance: USDC {formatUnits(usdcBal, USDC_DECIMALS)}
                </div>
              )}
            </label>
          </section>

          {/* Withdraw (entire contract balance for token) */}
          <section className="space-y-3">
            <h2 className="text-xl font-semibold">Withdraw Funds</h2>
            <p className="text-sm text-gray-600">
              Calls <code>withdraw(token)</code> on the NFT contract (withdraws
              full contract balance for the token).
            </p>

            <button
              className="px-4 py-2 font-bold bg-slate-700 text-white rounded hover:bg-slate-600 cursor-pointer"
              disabled={!usdcAddr}
              onClick={withdrawUsdc}
            >
              Withdraw
            </button>
          </section>

          {/* Authorize Breeder */}
          <section className="space-y-3">
            <h2 className="text-xl font-semibold">Authorize Breeder</h2>
            <label className="flex flex-col gap-2">
              <input
                value={breederAddr}
                onChange={e => setBreederAddr(e.target.value)}
                placeholder="Breeder Address 0x..."
                className="border p-2 rounded w-80 bg-white"
              />
            </label>
            <button
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 cursor-pointer"
              onClick={async () => {
                try {
                  if (!isAddress(breederAddr))
                    throw new Error("Invalid breeder address");
                  await authorizeBreeder(breederAddr as `0x${string}`);
                  alert(`Authorized breeder: ${breederAddr}`);
                } catch (e: any) {
                  alert(e?.message ?? "Authorize failed");
                }
              }}
            >
              Authorize
            </button>
          </section>

          {/* Remote bridge */}
          <section className="space-y-3">
            <h2 className="text-xl font-semibold">Set Remote Bridge</h2>
            <label className="flex flex-col gap-2">
              <input
                value={remoteChainId}
                onChange={e => setRemoteChainId(e.target.value)}
                placeholder="Remote chainId (e.g. 11155111)"
                className="border p-2 rounded w-80 bg-white"
              />
              <input
                value={remoteBridgeAddr}
                onChange={e => setRemoteBridgeAddr(e.target.value)}
                placeholder="Bridge Address 0x..."
                className="border p-2 rounded w-80 bg-white"
              />
            </label>
            <button
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 cursor-pointer"
              onClick={async () => {
                try {
                  if (!/^\d+$/.test(remoteChainId))
                    throw new Error("Provide numeric chainId");
                  if (!isAddress(remoteBridgeAddr))
                    throw new Error("Invalid bridge address");
                  await setRemoteBridge(
                    BigInt(remoteChainId),
                    remoteBridgeAddr as `0x${string}`
                  );
                  alert(
                    `Remote bridge set: chainId=${remoteChainId}, bridge=${remoteBridgeAddr}`
                  );
                } catch (e: any) {
                  alert(e?.message ?? "Set remote bridge failed");
                }
              }}
            >
              Save
            </button>
          </section>
        </div>
      </div>
    </div>
  );
};

export default Admin;
