"use client";

import React, { useMemo, useState, useEffect } from "react";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";

type NetworkOpt = { label: string; value: string };

const NETWORKS: NetworkOpt[] = [
  { label: "Ethereum Sepolia", value: "ETH-SEPOLIA" },
  { label: "Arbitrum Sepolia", value: "ARB-SEPOLIA" },
  { label: "Base Sepolia", value: "BASE-SEPOLIA" },
  { label: "Polygon Amoy", value: "MATIC-AMOY" },
  { label: "Avalanche Fuji", value: "AVAX-FUJI" },
  { label: "Optimism Sepolia (UNI)", value: "UNI-SEPOLIA" },
  { label: "Solana Devnet", value: "SOL-DEVNET" },
];

const Faucet = () => {
  const account = useActiveAccount();
  const chain = useActiveWalletChain();

  const [address, setAddress] = useState<string>(account?.address ?? "");
  const [network, setNetwork] = useState<string>("ETH-SEPOLIA");
  const [native, setNative] = useState(true);
  const [usdc, setUsdc] = useState(true);
  const [eurc, setEurc] = useState(false);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);

  const suggestFromChain = useMemo(() => {
    switch (chain?.id) {
      case 11155111:
        return "ETH-SEPOLIA";
      case 421614:
        return "ARB-SEPOLIA";
      case 84532:
        return "BASE-SEPOLIA";
      default:
        return undefined;
    }
  }, [chain?.id]);

  useEffect(() => {
    if (account?.address) setAddress(account.address);
  }, [account?.address]);

  useEffect(() => {
    if (suggestFromChain) setNetwork(suggestFromChain);
  }, [suggestFromChain]);

  async function requestDrip() {
    setLoading(true);
    setError(null);
    setResult(null);
    try {
      const res = await fetch("/api/faucet", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          address: address.trim(),
          blockchain: network,
          native,
          usdc,
          eurc,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.error ?? "Request failed");
      } else {
        setResult(data);
      }
    } catch (e: any) {
      setError(e?.message ?? "Network error");
    } finally {
      setLoading(false);
    }
  }

  return (
    <section className="px-10 mt-10 text-black ">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-semibold underline">Faucet</h1>
        <div className="text-sm text-white/70">
          Circle Faucet for test networks
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 border border-black/20 p-6 rounded-xl">
        <div className="lg:col-span-2 bg-white/10 backdrop-blur border border-white/20 rounded-xl p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-white/70 mb-1">
                Network
              </label>
              <select
                className="w-full bg-white/10 border border-black/20 rounded px-3 py-2"
                value={network}
                onChange={e => setNetwork(e.target.value)}
              >
                {NETWORKS.map(n => (
                  <option key={n.value} value={n.value}>
                    {n.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm text-white/70 mb-1">
                Address
              </label>
              <input
                className="w-full bg-white/10 border border-black/20 rounded px-3 py-2"
                value={address}
                onChange={e => setAddress(e.target.value)}
                placeholder="0x..."
              />
            </div>
            <div className="flex items-center gap-6 mt-2">
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={native}
                  onChange={e => setNative(e.target.checked)}
                />
                <span>Native gas</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={usdc}
                  onChange={e => setUsdc(e.target.checked)}
                />
                <span>USDC</span>
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={eurc}
                  onChange={e => setEurc(e.target.checked)}
                />
                <span>EURC</span>
              </label>
            </div>
          </div>

          <div className="mt-6">
            <button
              className="btn-primary px-6 py-3 disabled:opacity-50"
              onClick={requestDrip}
              disabled={loading || !address || !network}
            >
              {loading ? "Requesting…" : "Request Tokens"}
            </button>
          </div>
        </div>

        <div className="bg-white/10 backdrop-blur border border-white/20 rounded-xl p-6">
          <h2 className="text-lg font-semibold mb-3">Result</h2>
          {error && <div className="text-red-400">{error}</div>}
          {!error && result && (
            <pre className="text-xs whitespace-pre-wrap break-all">
              {JSON.stringify(result, null, 2)}
            </pre>
          )}
          {!error && !result && (
            <p className="text-white/60">No request yet.</p>
          )}
        </div>
      </div>
    </section>
  );
};

export default Faucet;
