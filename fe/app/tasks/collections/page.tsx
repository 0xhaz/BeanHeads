"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import { useBeanHeads } from "@/context/beanheads";
import {
  svgParamsToAvatarProps,
  getParamsFromAttributes,
  type SVGParams,
} from "@/utils/avatarMapping";
import { normalizeSvgParams } from "@/utils/normalizeSvgParams";
import { Avatar } from "@/components/Avatar";
import Link from "next/link";
import CollectionCard from "@/components/CollectionCard";

type OwnedNFT = {
  tokenId: bigint;
  attrsRaw: string[];
  props: ReturnType<typeof svgParamsToAvatarProps>;
  svgParams: SVGParams;
};

const CollectionsPage = () => {
  const { getOwnerTokens, getAttributesByOwner } = useBeanHeads();
  const account = useActiveAccount();
  const chain = useActiveWalletChain();
  const [ownedNFTs, setOwnedNFTs] = useState<OwnedNFT[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isOpen, setIsOpen] = useState<string | null>(null);

  const ownerAddress = useMemo(
    () => (account?.address ? (account.address as `0x${string}`) : undefined),
    [account?.address]
  );

  const handleSetIsOpen = (tokenId?: string) => {
    setIsOpen(prev => (prev === tokenId ? null : tokenId || null));
  };

  useEffect(() => {
    if (!account?.address) return;
    (async () => {
      const owner = account.address as `0x${string}`;
      setLoading(true);
      setError(null);

      const ids = await getOwnerTokens(owner);

      const items: OwnedNFT[] = [];
      for (const id of ids) {
        try {
          const raw = await getAttributesByOwner(owner, id);

          let params: SVGParams;
          if (raw) {
            params = normalizeSvgParams(raw);
            console.log("Normalized SVG Params:", params);
          } else {
            continue; // Skip this token if no valid data
          }

          const props = svgParamsToAvatarProps(params);
          items.push({
            tokenId: id,
            attrsRaw: Array.isArray(raw) ? raw : [],
            props,
            svgParams: params,
          });
        } catch (err) {
          setError(`Failed to process token ${id}. Please try again.`);
        }
      }
      setOwnedNFTs(items);
      setLoading(false);
    })().catch(err => {
      console.error("Error fetching owned NFTs:", err);
      setError("Failed to load your collections. Please try again.");
      setLoading(false);
    });
  }, [account?.address, getOwnerTokens, getAttributesByOwner]);

  if (!account?.address)
    return (
      <div className="p-8 text-center text-lg">
        Please connect your wallet to view your collections.
      </div>
    );
  if (ownedNFTs.length === 0)
    return (
      <div className="p-8 text-center text-lg">
        You don't own any BeanHeads yet. Mint or acquire some to see them
        <Link href="/tasks/minter" className=" text-blue-500">
          {" "}
          here!
        </Link>
      </div>
    );

  return (
    <section>
      <div className="p-8 text-2xl font-bold underline">My Collections</div>
      <div className="flex flex-col p-4 gap-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8 p-8 ">
          {ownedNFTs.map(({ tokenId, svgParams }) => {
            const props = svgParamsToAvatarProps(svgParams);
            return (
              <div
                key={tokenId.toString()}
                className="group relative h-[250px] w-[250px] rounded-3xl  border-4 border-white shadow-lg overflow-hidden"
              >
                <Avatar {...props} />
                <div
                  className="absolute inset-0 flex items-center justify-center bg-black/70 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-3xl cursor-pointer"
                  onClick={() => handleSetIsOpen(tokenId.toString())}
                >
                  <div className="text-white text-lg font-bold">
                    View Details
                  </div>
                </div>
                {isOpen === tokenId.toString() && (
                  <CollectionCard
                    params={svgParams}
                    onClose={() => handleSetIsOpen(tokenId.toString())}
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
