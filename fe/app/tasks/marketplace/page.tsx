"use client";

import { useEffect, useState } from "react";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import { useBeanHeads } from "@/context/beanheads";
import { useBreeder } from "@/context/breeder";
import { type SVGParams, svgParamsToAvatarProps } from "@/utils/avatarMapping";
import { normalizeSvgParams } from "@/utils/normalizeSvgParams";
import { Avatar } from "@/components/Avatar";
import CollectionCard from "@/components/CollectionCard";
import Image from "next/image";
import { USDC_ADDRESS } from "@/constants/contract";

type CacheEntry = {
  params?: SVGParams;
  generation?: bigint;
  price?: bigint;
};

const USDC_DECIMALS = 18;

// ES2019-safe, tolerant formatter
function formatUsd(raw?: bigint | number | string | null): string {
  if (raw === null || raw === undefined) return "$–";
  const amount =
    typeof raw === "bigint"
      ? raw
      : typeof raw === "number"
      ? BigInt(Math.trunc(raw))
      : BigInt(raw);
  const neg = amount < BigInt(0);
  const abs = neg ? -amount : amount;
  const scale = BigInt(10) ** BigInt(USDC_DECIMALS);
  const intPart = abs / scale;
  const fracPart = abs % scale;
  const fracFull = fracPart.toString().padStart(USDC_DECIMALS, "0");
  const frac2 = fracFull.slice(0, 2);
  return `${neg ? "-" : ""}$${intPart.toString()}${
    Number(frac2) ? `.${frac2}` : ""
  }`;
}

const Marketplace = () => {
  const {
    ready,
    getAllActiveSaleTokens,
    getTokenSalePrice,
    getAttributesByTokenId,
    getGeneration,
    buyToken,
    batchBuyTokens,
    cancelTokenSale,
  } = useBeanHeads();
  const { getRarityPoints } = useBreeder();

  const account = useActiveAccount();
  const chain = useActiveWalletChain();

  const [loadingList, setLoadingList] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [tokens, setTokens] = useState<bigint[]>([]);
  const [cache, setCache] = useState<Record<string, CacheEntry>>({});
  const [loadingMap, setLoadingMap] = useState<Record<string, boolean>>({});
  const [isOpen, setIsOpen] = useState<string | null>(null);
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [rarityPoints, setRarityPoints] = useState<Record<string, bigint>>({});

  const fetchRarityPoints = async (tokenId: bigint) => {
    const key = tokenId.toString();
    try {
      const points = await getRarityPoints(tokenId);
      setRarityPoints(prev => ({ ...prev, [key]: points }));
    } catch (e) {
      console.error(`Error fetching rarity points for token ${tokenId}:`, e);
    }
  };

  // Load active tokenIds
  useEffect(() => {
    if (!ready) return;
    let cancelled = false;
    (async () => {
      setLoadingList(true);
      try {
        const ids = await getAllActiveSaleTokens();
        if (!cancelled) setTokens(ids);
      } catch (e) {
        if (!cancelled) setError("Failed to load marketplace listings.");
        console.error(e);
      } finally {
        if (!cancelled) setLoadingList(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [ready, chain?.id, getAllActiveSaleTokens]);

  // Prefetch price for badges (no struct parsing)
  useEffect(() => {
    if (!ready || tokens.length === 0) return;
    let cancelled = false;
    (async () => {
      try {
        const entries = await Promise.all(
          tokens.map(async id => {
            try {
              const price = await getTokenSalePrice(id);
              return [id.toString(), price] as const;
            } catch {
              return null;
            }
          })
        );
        if (cancelled) return;
        setCache(prev => {
          const next = { ...prev };
          for (const ent of entries) {
            if (!ent) continue;
            const [k, price] = ent;
            next[k] = { ...(next[k] ?? {}), price };
          }
          return next;
        });
      } catch (e) {
        console.error("Prefetch prices failed:", e);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [ready, tokens, getTokenSalePrice]);

  // Fetch attributes + generation on demand (price already prefetched)
  const fetchDetails = async (tokenId: bigint) => {
    const key = tokenId.toString();
    try {
      setLoadingMap(m => ({ ...m, [key]: true }));
      const [raw, generation, points] = await Promise.all([
        getAttributesByTokenId(tokenId),
        getGeneration(tokenId),
        getRarityPoints(tokenId),
      ]);
      setCache(prev => {
        const curr = prev[key] ?? {};
        const next: CacheEntry = { ...curr, generation };
        if (raw) next.params = normalizeSvgParams(raw);
        return { ...prev, [key]: next };
      });

      setRarityPoints(prev => ({ ...prev, [key]: points }));
    } catch (e) {
      console.error(`fetchDetails #${key}:`, e);
    } finally {
      setLoadingMap(m => ({ ...m, [key]: false }));
    }
  };

  const refreshIds = async () => {
    const ids = await getAllActiveSaleTokens();
    setTokens(ids);
  };

  const toggleSelect = (id: bigint) => {
    const k = id.toString();
    setSelected(s => ({ ...s, [k]: !s[k] }));
  };

  const handleBuy = async (id: bigint) => {
    if (!account || !chain) return alert("Connect wallet first");
    try {
      await buyToken(
        account.address as `0x${string}`,
        id,
        USDC_ADDRESS[chain.id]
      );
      await refreshIds(); // card disappears -> badge gone
      setIsOpen(null);
    } catch (e) {
      console.error(e);
      alert("Purchase failed");
    }
  };

  const handleCancel = async (id: bigint) => {
    try {
      await cancelTokenSale(id);
      await refreshIds(); // card disappears
      setIsOpen(null);
    } catch (e) {
      console.error(e);
      alert("Cancel failed");
    }
  };

  const handleBulkBuy = async () => {
    if (!account || !chain) return alert("Connect wallet first");
    const toBuy = Object.keys(selected)
      .filter(k => selected[k])
      .map(k => BigInt(k));
    if (!toBuy.length) return;
    try {
      await batchBuyTokens(
        account.address as `0x${string}`,
        toBuy,
        USDC_ADDRESS[chain.id]
      );
      setSelected({});
      await refreshIds();
    } catch (e) {
      console.error(e);
      alert("Batch purchase failed");
    }
  };

  if (loadingList) return <div className="p-8">Loading marketplace…</div>;
  if (error) return <div className="p-8 text-red-400">{error}</div>;
  if (tokens.length === 0)
    return <div className="p-8">No active listings.</div>;

  return (
    <section>
      <div className="p-8 flex items-center justify-between">
        <div className="text-2xl font-bold underline">Marketplace</div>
        <button
          className="px-4 py-2 rounded-md bg-green-700 hover:bg-green-600 disabled:opacity-50 text-white cursor-pointer"
          disabled={!Object.values(selected).some(Boolean)}
          onClick={handleBulkBuy}
        >
          Buy Selected
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8 p-8">
        {tokens.map(tokenId => {
          const key = tokenId.toString();
          const entry = cache[key];
          const inFlight = !!loadingMap[key];
          const props = entry?.params
            ? svgParamsToAvatarProps(entry.params)
            : undefined;

          return (
            <div
              key={key}
              className="group relative h-[250px] w-[250px] rounded-3xl border-4 border-white shadow-lg overflow-hidden"
            >
              {/* Badge: every card here is an active listing */}
              <div className="absolute top-2 left-2 z-10 bg-gray-200 rounded-full px-2 py-1 text-xs flex items-center gap-1">
                <Image
                  src="/icons/sell.svg"
                  alt="On Sale"
                  width={16}
                  height={16}
                />
                <span>{formatUsd(entry?.price)}</span>
              </div>

              {/* Selection */}
              <label className="absolute top-2 right-2 z-10 flex items-center gap-2 bg-gray-300 px-2 py-1 rounded-md cursor-pointer">
                <input
                  type="checkbox"
                  checked={!!selected[key]}
                  onChange={e => {
                    e.stopPropagation();
                    toggleSelect(tokenId);
                  }}
                />
              </label>

              {/* Avatar */}
              {props ? (
                <Avatar {...props} />
              ) : (
                <div className="w-full h-full bg-white/5 flex items-center justify-center text-white/70">
                  BeanHead #{key}
                </div>
              )}

              {/* Hover overlay to open modal */}
              <div
                className="absolute inset-0 flex items-center justify-center bg-black/70 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-3xl cursor-pointer"
                onClick={e => {
                  e.stopPropagation();
                  setIsOpen(key);
                  if (!entry?.params || entry?.generation === undefined)
                    fetchDetails(tokenId);
                }}
              >
                <div className="flex flex-col items-center gap-2 text-white">
                  <div className="text-lg font-bold">
                    {entry?.params
                      ? "View Details"
                      : inFlight
                      ? "Loading…"
                      : "Load Details"}
                  </div>
                  <div className="text-lg text-white/80">
                    Listed: {formatUsd(entry?.price)}
                  </div>
                </div>
              </div>

              {/* Modal */}
              {isOpen === key &&
                entry?.params &&
                entry?.generation !== undefined && (
                  <div
                    className="fixed inset-0 z-50 bg-black/70"
                    onClick={() => setIsOpen(null)}
                  >
                    <div
                      className="pointer-events-auto"
                      onClick={e => e.stopPropagation()}
                    >
                      <CollectionCard
                        tokenId={tokenId}
                        params={entry.params}
                        generation={entry.generation}
                        rarityPoints={rarityPoints[key]}
                        loading={false}
                        onClose={() => setIsOpen(null)}
                      />
                      <div className="fixed bottom-6 mb-30 left-1/2 -translate-x-1/2 z-50 flex items-center gap-3 bg-black/80 px-4 py-3 rounded-xl border border-white/10">
                        <div className="text-sm text-white/80">
                          Listed at {formatUsd(entry?.price)}
                        </div>
                        {account?.address ? (
                          <button
                            className="px-4 py-2 rounded-md bg-green-700 hover:bg-green-600 text-white cursor-pointer"
                            onClick={() => handleBuy(tokenId)}
                          >
                            Buy
                          </button>
                        ) : null}
                        <button
                          className="px-4 py-2 rounded-md bg-red-700 hover:bg-red-600 text-white cursor-pointer"
                          onClick={() => handleCancel(tokenId)}
                        >
                          Cancel Listing
                        </button>
                      </div>
                    </div>
                  </div>
                )}
            </div>
          );
        })}
      </div>
    </section>
  );
};

export default Marketplace;
