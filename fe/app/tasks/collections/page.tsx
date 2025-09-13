"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import { useBeanHeads } from "@/context/beanheads";
import { svgParamsToAvatarProps, type SVGParams } from "@/utils/avatarMapping";
import { normalizeSvgParams } from "@/utils/normalizeSvgParams";
import { Avatar } from "@/components/Avatar";
import Link from "next/link";
import CollectionCard from "@/components/CollectionCard";

type OwnedNFT = {
  tokenId: bigint;
};

const CollectionsPage = () => {
  const { getOwnerTokens, getAttributesByOwner, getGeneration } =
    useBeanHeads();
  const account = useActiveAccount();
  const chain = useActiveWalletChain();
  const [loadingList, setLoadingList] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isOpen, setIsOpen] = useState<string | null>(null);
  const [tokens, setTokens] = useState<OwnedNFT[]>([]);
  const [detailsCache, setDetailsCache] = useState<
    Record<string, { params: SVGParams; generation: bigint }>
  >({});
  const [loadingMap, setLoadingMap] = useState<Record<string, boolean>>({});

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

  const handleOpen = async (tokenId: bigint) => {
    const key = tokenId.toString();
    setIsOpen(key);

    if (detailsCache[key] || loadingMap[key]) return; // cached or already loading

    try {
      setLoadingMap(m => ({ ...m, [key]: true }));
      const owner = account!.address as `0x${string}`;
      const raw = await getAttributesByOwner(owner, tokenId);
      if (!raw) return;
      const params = normalizeSvgParams(raw);
      const generation = await getGeneration(tokenId);
      setDetailsCache(prev => ({ ...prev, [key]: { params, generation } }));
    } catch (e) {
      console.error("Error fetching NFT details:", e);
    } finally {
      setLoadingMap(m => ({ ...m, [key]: false }));
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
      <div className="p-8 text-2xl font-bold underline">My Collections</div>
      <div className="flex flex-col p-4 gap-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8 p-8 ">
          {tokens.map(({ tokenId }) => {
            const key = tokenId.toString();
            const cached = detailsCache[key];
            const inFlight = !!loadingMap[key];
            const props = cached
              ? svgParamsToAvatarProps(cached.params)
              : undefined;

            return (
              <div
                key={key}
                className="group relative h-[250px] w-[250px] rounded-3xl  border-4 border-white shadow-lg overflow-hidden"
              >
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
                  <div className="text-white text-lg font-bold">
                    {cached
                      ? "View Details"
                      : inFlight
                      ? "Loading…"
                      : "Load Details"}
                  </div>
                </div>

                {isOpen === key && !cached && (
                  <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/70 text-white">
                    Loading details…
                  </div>
                )}

                {isOpen === key && cached && (
                  <CollectionCard
                    tokenId={tokenId}
                    params={cached?.params}
                    generation={cached?.generation}
                    loading={false}
                    onClose={() => setIsOpen(null)}
                  />
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
