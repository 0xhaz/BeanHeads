"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import { useBeanHeads } from "@/context/beanheads";
import { useBreeder } from "@/context/breeder";
import { svgParamsToAvatarProps, type SVGParams } from "@/utils/avatarMapping";
import { normalizeSvgParams } from "@/utils/normalizeSvgParams";
import { Avatar } from "@/components/Avatar";
import Link from "next/link";
import CollectionCard from "@/components/CollectionCard";

import Image from "next/image";

type OwnedNFT = {
  tokenId: bigint;
};
type SaleInfo = {
  seller: `0x${string}`;
  price: bigint;
  isActive: boolean;
} | null;

const USDC_DECIMALS = 18;
const MAX_BREEDS = 5;

function parseToUsd(usd: string): bigint {
  const s = usd.trim();
  if (!s) throw new Error("Empty price");
  if (!/^\d+(\.\d+)?$/.test(s)) throw new Error("Invalid price format");
  const [intPart, fracRaw = ""] = s.split(".");
  const frac = fracRaw
    .padEnd(Number(USDC_DECIMALS), "0")
    .slice(0, Number(USDC_DECIMALS));
  const base = BigInt(intPart) * BigInt(10) ** BigInt(USDC_DECIMALS);
  const fracVal = frac ? BigInt(frac) : BigInt(0);
  return base + fracVal;
}

function formatUsd(amount: bigint): string {
  const neg = amount < BigInt(0);
  const abs = neg ? -amount : amount;
  const intPart = abs / BigInt(10) ** BigInt(USDC_DECIMALS);
  const fracFull = (abs % BigInt(10) ** BigInt(USDC_DECIMALS))
    .toString()
    .padStart(Number(USDC_DECIMALS), "0");
  const frac2 = fracFull.slice(0, 2);
  return `${neg ? "-" : ""}$${intPart.toString()}${
    Number(frac2) ? `.${frac2}` : ""
  }`;
}

const CollectionsPage = () => {
  const {
    getOwnerTokens,
    getAttributesByOwner,
    getGeneration,
    getTokenSaleInfo,
    sellToken,
    batchSellTokens,
    cancelTokenSale,
  } = useBeanHeads();
  const { getRarityPoints, getParentBreedingCount } = useBreeder();
  const account = useActiveAccount();
  const chain = useActiveWalletChain();
  const [loadingList, setLoadingList] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isOpen, setIsOpen] = useState<string | null>(null);
  const [tokens, setTokens] = useState<OwnedNFT[]>([]);
  const [detailsCache, setDetailsCache] = useState<
    Record<string, { params: SVGParams; generation: bigint; sale?: SaleInfo }>
  >({});
  const [loadingMap, setLoadingMap] = useState<Record<string, boolean>>({});
  const [selectMode, setSelectMode] = useState(false);
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [bulkPriceUSD, setBulkPriceUSD] = useState<string>("");
  const [listPriceUSD, setListPriceUSD] = useState<string>("");
  const [rarityPoints, setRarityPoints] = useState<Record<string, bigint>>({});
  const [breedCounts, setBreedCounts] = useState<Record<string, bigint>>({});

  useEffect(() => {
    if (!account?.address) return;
    (async () => {
      setLoadingList(true);
      setError(null);
      try {
        const owner = account.address as `0x${string}`;
        const ids = await getOwnerTokens(owner);
        setTokens(ids.map(id => ({ tokenId: id })));
      } catch (e) {
        console.error("Error fetching owned tokens:", e);
        setError("Failed to load your collections.");
      } finally {
        setLoadingList(false);
      }
    })();
  }, [account?.address, getOwnerTokens]);

  const fetchSaleInfo = async (tokenId: bigint) => {
    const key = tokenId.toString();
    try {
      const info = await getTokenSaleInfo(tokenId);
      setDetailsCache(prev => {
        const curr = prev[key] ?? ({} as any);
        return { ...prev, [key]: { ...curr, sale: info } };
      });
    } catch (e) {
      console.error(`Error fetching sale info for token ${tokenId}:`, e);
    }
  };

  const fetchRarityPoints = async (tokenId: bigint) => {
    const key = tokenId.toString();
    try {
      const points = await getRarityPoints(tokenId);
      setRarityPoints(prev => ({ ...prev, [key]: points }));
    } catch (e) {
      console.error(`Error fetching rarity points for token ${tokenId}:`, e);
    }
  };

  const fetchBreedCount = async (tokenId: bigint) => {
    const key = tokenId.toString();
    try {
      if (getParentBreedingCount) {
        const count = await getParentBreedingCount(tokenId);
        setBreedCounts(prev => ({ ...prev, [key]: count }));
      } else {
        console.warn("getParentBreedingCount is undefined");
      }
    } catch (e) {
      console.error(`Error fetching breed count for token ${tokenId}:`, e);
    }
  };

  const handleOpen = async (tokenId: bigint) => {
    const key = tokenId.toString();
    setIsOpen(key);

    if (detailsCache[key] || loadingMap[key]) {
      if (!detailsCache[key]?.sale) fetchSaleInfo(tokenId);
      if (!rarityPoints[key]) fetchRarityPoints(tokenId);
      if (!breedCounts[key]) fetchBreedCount(tokenId);
      return;
    }

    try {
      setLoadingMap(m => ({ ...m, [key]: true }));
      const owner = account!.address as `0x${string}`;
      const [raw, generation] = await Promise.all([
        getAttributesByOwner(owner, tokenId),
        getGeneration(tokenId),
      ]);

      if (raw) {
        const params = normalizeSvgParams(raw);
        setDetailsCache(prev => ({
          ...prev,
          [key]: { ...(prev[key] ?? {}), params, generation },
        }));
      }
      await Promise.all([
        fetchSaleInfo(tokenId),
        fetchRarityPoints(tokenId),
        fetchBreedCount(tokenId),
      ]);
    } catch (e) {
      console.error("Error fetching NFT details:", e);
    } finally {
      setLoadingMap(m => ({ ...m, [key]: false }));
    }
  };

  const toggleSelect = (tokenId: bigint) => {
    const key = tokenId.toString();
    setSelected(s => ({ ...s, [key]: !s[key] }));
  };

  const clearSelection = () => {
    setSelected({});
    setBulkPriceUSD("");
  };

  const doBulkList = async () => {
    const tokenIds = Object.keys(selected)
      .filter(k => selected[k])
      .map(k => BigInt(k));
    if (tokenIds.length === 0) return;

    try {
      const price1e18 = parseToUsd(bulkPriceUSD);
      const prices = tokenIds.map(() => price1e18);
      await batchSellTokens(tokenIds, prices);
      await Promise.all(tokenIds.map(fetchSaleInfo));
      clearSelection();
      setSelectMode(false);
    } catch (e) {
      console.error("Error during bulk listing:", e);
    }
  };

  const doSingleList = async (tokenId: bigint) => {
    try {
      const price1e18 = parseToUsd(listPriceUSD);
      const tx = await sellToken(tokenId, price1e18);
      console.log("Single listing transaction:", tx);
      await fetchSaleInfo(tokenId);

      const owner = account!.address as `0x${string}`;
      const owned = await getOwnerTokens(owner);
      setTokens(owned.map(id => ({ tokenId: id })));

      setListPriceUSD("");
      setIsOpen(null);
    } catch (e) {
      console.error("Error during single listing:", e);
    }
  };

  const doCancelListing = async (tokenId: bigint) => {
    try {
      await cancelTokenSale(tokenId);
      await fetchSaleInfo(tokenId);
    } catch (e) {
      console.error("Error during cancel listing:", e);
    }
  };

  if (!account?.address) {
    return (
      <div className="p-8 text-center text-lg">
        Please connect your wallet to view your collections.
      </div>
    );
  }

  if (loadingList) {
    return <div className="p-8 text-center text-lg">Loading your tokens…</div>;
  }

  if (error) {
    return <div className="p-8 text-center text-red-400">{error}</div>;
  }

  if (tokens.length === 0) {
    return (
      <div className="p-8 text-center text-lg">
        You do not own any BeanHeads NFTs yet.{" "}
        <Link href="/tasks/minter" className="text-blue-500 underline">
          Mint one now!
        </Link>
      </div>
    );
  }

  return (
    <section>
      <div className="p-8 flex items-center justify-between">
        <div className="text-2xl font-bold underline">My Collections</div>
        <div className="flex items-center p-4 gap-4">
          <button
            className={`px-4 py-2 rounded-md border cursor-pointer ${
              selectMode
                ? "bg-yellow-600 border-yellow-400 text-white"
                : "bg-zinc-800 border-zinc-600 text-white"
            }`}
            onClick={() => {
              setSelectMode(!selectMode);
              if (selectMode) clearSelection();
            }}
          >
            {selectMode ? "Exit Selection Mode" : "Select for Bulk Sell"}
          </button>

          {selectMode && (
            <div className="flex items-center gap-2">
              <input
                placeholder="Price (USD)"
                className="px-3 py-2 rounded-md bg-gray-200 border border-zinc-700 w-48 "
                value={bulkPriceUSD}
                onChange={e => setBulkPriceUSD(e.target.value)}
                inputMode="decimal"
              />
              <button
                className="px-4 py-2 rounded-md bg-green-700 hover:bg-green-600 text-white cursor-pointer"
                onClick={doBulkList}
                disabled={
                  !bulkPriceUSD ||
                  Object.values(selected).filter(Boolean).length === 0
                }
              >
                List Selected
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="flex flex-col p-4 gap-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8 p-8 ">
          {tokens.map(({ tokenId }) => {
            const key = tokenId.toString();
            const cached = detailsCache[key];
            const inFlight = !!loadingMap[key];
            const props = cached?.params
              ? svgParamsToAvatarProps(cached.params)
              : undefined;
            const onSale = cached?.sale?.isActive === true;
            const price1e18 = cached?.sale?.price;

            return (
              <div
                key={key}
                className="group relative h-[250px] w-[250px] rounded-3xl  border-4 border-white shadow-lg overflow-hidden"
              >
                {onSale && (
                  <div className="absolute top-2 left-2 z-10 bg-black/70 rounded-full px-2 py-1 text-xs">
                    <div className="flex items-center gap-1">
                      <Image
                        src="/icons/sell.svg"
                        alt="On Sale"
                        width={16}
                        height={16}
                      />
                      <span>
                        {price1e18 !== undefined
                          ? formatUsd(price1e18)
                          : "On Sale"}
                      </span>
                    </div>
                  </div>
                )}

                {selectMode && (
                  <label className="absolute top-2 right-2 z-10 flex items-center gap-2 bg-gray-300 px-2 py-1 rounded-md cursor-pointer">
                    <input
                      type="checkbox"
                      checked={!!selected[key]}
                      onChange={() => toggleSelect(tokenId)}
                    />
                    <span className="text-xs">Select</span>
                  </label>
                )}

                {props ? (
                  <Avatar {...props} />
                ) : (
                  <div className="w-full h-full bg-white/5 flex items-center justify-center text-white/70">
                    BeanHead #{key}
                  </div>
                )}
                <div
                  className="absolute inset-0 flex items-center justify-center bg-black/70 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-3xl cursor-pointer"
                  onClick={() => handleOpen(tokenId)}
                >
                  <div className="flex flex-col items-center gap-2">
                    <div className="text-white text-lg font-bold">
                      {cached
                        ? "View Details"
                        : inFlight
                        ? "Loading…"
                        : "Load Details"}
                    </div>
                    {onSale && price1e18 !== undefined && (
                      <div className="text-xs text-white/80">
                        Listed: {formatUsd(price1e18)}
                      </div>
                    )}
                  </div>
                </div>

                {isOpen === key && cached && (
                  <div className="fixed inset-0 z-50">
                    <CollectionCard
                      tokenId={tokenId}
                      params={cached.params}
                      generation={cached.generation}
                      rarityPoints={rarityPoints[key]}
                      breedCount={breedCounts[key]}
                      maxBreeds={MAX_BREEDS}
                      loading={false}
                      onClose={() => {
                        setIsOpen(null);
                        setListPriceUSD("");
                      }}
                    />
                    <div className="fixed mb-30 bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-3 bg-black/80 px-4 py-3 rounded-xl border border-white/10">
                      {!cached.sale?.isActive ? (
                        <>
                          <input
                            placeholder="List price (USD)"
                            className="px-3 py-2 rounded-md bg-gray-200 border border-zinc-700 w-64"
                            value={listPriceUSD}
                            onChange={e => setListPriceUSD(e.target.value)}
                            inputMode="decimal"
                          />
                          <button
                            className="px-4 py-2 rounded-md bg-green-700 hover:bg-green-600 text-white cursor-pointer"
                            onClick={() => doSingleList(tokenId)}
                            disabled={!listPriceUSD}
                          >
                            List for Sale
                          </button>
                        </>
                      ) : (
                        <>
                          <div className="text-sm text-white/80">
                            Listed at {formatUsd(cached.sale.price)}
                          </div>
                          <button
                            className="px-4 py-2 rounded-md bg-red-700 hover:bg-red-600"
                            onClick={() => doCancelListing(tokenId)}
                          >
                            Cancel Listing
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};

export default CollectionsPage;
