"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import { useBeanHeads } from "@/context/beanheads";
import {
  Avatar,
  type AvatarProps,
  HAIR_STYLES,
  HAIR_COLORS,
  BODY_TYPES,
  SKIN_COLORS,
  CLOTHING_STYLES,
  CLOTHING_COLORS,
  CLOTHING_GRAPHICS,
  EYEBROW_SHAPES,
  EYE_SHAPES,
  FACIAL_HAIR_STYLES,
  MOUTH_SHAPES,
  LIP_COLORS,
  ACCESSORIES,
  HAT_STYLES,
  BG_COLORS,
} from "@/components/Avatar";

type OwnedNFT = {
  tokenId: bigint;
  attrsRaw: string[];
  props: AvatarProps;
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
      try {
        // 1) Get the token IDs owned by this address
        const tokenIds = await getOwnerTokens(account.address as `0x${string}`);
        console.log("Token IDs:", tokenIds);

        // 2) For each token, fetch attributes
        for (const tokenId of tokenIds) {
          const attrs = await getAttributesByOwner(
            account.address as `0x${string}`,
            tokenId
          );
          console.log(`Attributes for token ${tokenId.toString()}:`, attrs);
        }
      } catch (err) {
        console.error("Error fetching tokens:", err);
      }
    })();
  }, [account?.address, getOwnerTokens, getAttributesByOwner]);

  return <div>Open console to see your BeanHeads!</div>;
};

export default CollectionsPage;
