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

  const ownerAddress = useMemo(
    () => (account?.address ? (account.address as `0x${string}`) : undefined),
    [account?.address]
  );
  console.log("Owner Address:", ownerAddress);

  useEffect(() => {
    if (!account?.address) return;
    (async () => {
      const owner = account.address as `0x${string}`;
      setLoading(true);
      setError(null);

      const ids = await getOwnerTokens(owner);
      console.log("Owned Token IDs:", ids);

      const items: OwnedNFT[] = [];
      for (const id of ids) {
        try {
          const raw = await getAttributesByOwner(owner, id);
          console.log(`Raw attributes for Token ID ${id}:`, raw);

          let params: SVGParams;
          if (raw) {
            params = normalizeSvgParams(raw);
          } else {
            console.warn(`No attributes found for Token ID ${id}, skipping.`);
            continue; // Skip this token if no valid data
          }
          console.log(`Normalized SVG Params for Token ID ${id}:`, params);

          const props = svgParamsToAvatarProps(params);
          items.push({
            tokenId: id,
            attrsRaw: Array.isArray(raw) ? raw : [],
            props,
            svgParams: params,
          });
        } catch (err) {
          console.error(`Error processing Token ID ${id}:`, err);
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
    return <div>Please connect your wallet to view your collections.</div>;
  if (ownedNFTs.length === 0)
    return (
      <div>
        You don't own any BeanHeads yet. Mint or acquire some to see them here!
      </div>
    );

  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fill, 200px)",
        gap: 16,
      }}
    >
      {ownedNFTs.map(({ tokenId, svgParams }) => {
        const props = svgParamsToAvatarProps(svgParams);
        return (
          <div key={tokenId.toString()}>
            <Avatar {...props} />
            <div>Token ID: {tokenId.toString()}</div>
          </div>
        );
      })}
    </div>
  );
};

export default CollectionsPage;
