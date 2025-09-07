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

function toBool(v: string | number | boolean | undefined): boolean {
  if (typeof v === "boolean") return v;
  if (typeof v === "number") return v !== 0;
  if (!v) return false;
  const s = String(v).toLowerCase();
  return s === "true" || s === "1";
}

// Decode order mirrors on-chain svgParams order used during mint
function decodeAttributes(arr: string[]): AvatarProps {
  const getNum = (i: number, def = 0) => {
    const v = Number(arr[i] ?? def);
    return Number.isFinite(v) ? v : def;
  };
  return {
    hairStyle: getNum(0),
    hairColor: getNum(1),
    body: getNum(2),
    skinColor: getNum(3),
    clothingStyle: getNum(4),
    clothingColor: getNum(5),
    graphic: getNum(6),
    eyebrows: getNum(7),
    eyes: getNum(8),
    facialHair: getNum(9),
    mouthShape: getNum(10),
    mouthColor: getNum(11),
    accessory: getNum(12),
    hat: getNum(13),
    hatColor: getNum(14),
    faceMask: toBool(arr[15]),
    faceMaskColor: getNum(16),
    shape: toBool(arr[17]),
    circleColor: getNum(18),
    lashes: toBool(arr[19]),
    // Not encoded in on-chain params; safe default
    mask: false,
  } as AvatarProps;
}

function traitLabel(group: string, index: number): string {
  const pick = (
    arr: { id: number; label: string }[] | boolean[],
    idx: number
  ) => {
    if (Array.isArray(arr) && typeof arr[0] === "object") {
      const item = (arr as any[]).find(x => x.id === idx) ?? (arr as any[])[0];
      return item?.label ?? String(idx);
    }
    return String(idx);
  };

  switch (group) {
    case "hairStyle":
      return pick(HAIR_STYLES as any, index);
    case "hairColor":
      return pick(HAIR_COLORS as any, index);
    case "body":
      return pick(BODY_TYPES as any, index);
    case "skinColor":
      return pick(SKIN_COLORS as any, index);
    case "clothingStyle":
      return pick(CLOTHING_STYLES as any, index);
    case "clothingColor":
      return pick(CLOTHING_COLORS as any, index);
    case "graphic":
      return pick(CLOTHING_GRAPHICS as any, index);
    case "eyebrows":
      return pick(EYEBROW_SHAPES as any, index);
    case "eyes":
      return pick(EYE_SHAPES as any, index);
    case "facialHair":
      return pick(FACIAL_HAIR_STYLES as any, index);
    case "mouthShape":
      return pick(MOUTH_SHAPES as any, index);
    case "mouthColor":
      return pick(LIP_COLORS as any, index);
    case "accessory":
      return pick(ACCESSORIES as any, index);
    case "hat":
      return pick(HAT_STYLES as any, index);
    case "hatColor":
      return pick(CLOTHING_COLORS as any, index);
    case "faceMaskColor":
      return pick(CLOTHING_COLORS as any, index);
    case "circleColor":
      return pick(BG_COLORS as any, index);
    default:
      return String(index);
  }
}

const MyCollections = () => {
  const account = useActiveAccount();
  const chain = useActiveWalletChain();
  const {
    totalSupply,
    getOwnerTokensCount,
    getOwnerOf,
    getAttributesByTokenId,
  } = useBeanHeads();

  const [loading, setLoading] = useState(false);
  const [items, setItems] = useState<OwnedNFT[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [active, setActive] = useState<OwnedNFT | null>(null);

  const fetchOwned = async () => {
    if (!account || !chain) return;
    setLoading(true);
    setError(null);
    try {
      const [supply, ownedCount] = await Promise.all([
        totalSupply(),
        getOwnerTokensCount(account.address as `0x${string}`),
      ]);
      const total = Number(supply ?? 0);
      let need = Number(ownedCount ?? 0);
      const out: OwnedNFT[] = [];
      if (total === 0 || need === 0) {
        setItems([]);
        setLoading(false);
        return;
      }
      for (let i = 1; i <= total; i++) {
        if (need <= 0) break;
        const tokenId = BigInt(i);
        try {
          const owner = await getOwnerOf(tokenId);
          if (owner?.toLowerCase() !== account.address.toLowerCase()) continue;
          const attrsRaw = (await getAttributesByTokenId(tokenId)) ?? [];
          const props = decodeAttributes(attrsRaw);
          out.push({ tokenId, attrsRaw, props });
          need -= 1;
        } catch (e) {
          // ignore individual token errors
        }
      }
      setItems(out);
    } catch (e: any) {
      setError(e?.message ?? "Failed to load collection");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOwned();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [account?.address, chain?.id]);

  const grid = useMemo(() => {
    if (!items.length) return null;
    return (
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6 mt-6">
        {items.map(item => (
          <button
            key={String(item.tokenId)}
            className="bg-white/10 backdrop-blur border border-white/20 rounded-xl p-4 hover:bg-white/20 transition text-left"
            onClick={() => setActive(item)}
          >
            <div className="w-full flex justify-center">
              <Avatar {...item.props} />
            </div>
            <div className="mt-3">
              <div className="text-sm text-white/70">Token</div>
              <div className="text-lg font-semibold">
                #{String(item.tokenId)}
              </div>
            </div>
          </button>
        ))}
      </div>
    );
  }, [items]);

  return (
    <div className="p-6">
      <h1 className="text-2xl font-semibold">My Collection</h1>
      {!account && (
        <p className="mt-4 text-white/70">Connect your wallet to view NFTs.</p>
      )}
      {account && loading && (
        <p className="mt-4 text-white/70">Loading your NFTs…</p>
      )}
      {account && !loading && !items.length && !error && (
        <p className="mt-4 text-white/70">No NFTs found on this network.</p>
      )}
      {error && <p className="mt-4 text-red-400">{error}</p>}
      {!loading && grid}

      {active && (
        <div
          className="fixed inset-0 bg-black/60 flex items-center justify-center z-50"
          onClick={() => setActive(null)}
        >
          <div
            className="bg-zinc-900 border border-white/20 rounded-2xl p-6 w-full max-w-3xl text-white shadow-xl"
            onClick={e => e.stopPropagation()}
          >
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-semibold">
                BeanHead #{String(active.tokenId)}
              </h2>
              <button
                className="text-white/60 hover:text-white"
                onClick={() => setActive(null)}
              >
                Close
              </button>
            </div>
            <div className="flex flex-col md:flex-row gap-6">
              <div className="flex-shrink-0 self-center md:self-start">
                <Avatar {...active.props} />
              </div>
              <div className="grid grid-cols-2 gap-4 flex-1">
                {(
                  [
                    ["Hair Style", "hairStyle", active.props.hairStyle],
                    ["Hair Color", "hairColor", active.props.hairColor],
                    ["Body", "body", active.props.body],
                    ["Skin", "skinColor", active.props.skinColor],
                    ["Clothing", "clothingStyle", active.props.clothingStyle],
                    [
                      "Clothing Color",
                      "clothingColor",
                      active.props.clothingColor,
                    ],
                    ["Graphic", "graphic", active.props.graphic],
                    ["Eyebrows", "eyebrows", active.props.eyebrows],
                    ["Eyes", "eyes", active.props.eyes],
                    ["Facial Hair", "facialHair", active.props.facialHair],
                    ["Mouth", "mouthShape", active.props.mouthShape],
                    ["Lip Color", "mouthColor", active.props.mouthColor],
                    ["Accessory", "accessory", active.props.accessory],
                    ["Hat", "hat", active.props.hat],
                    ["Hat Color", "hatColor", active.props.hatColor],
                    ["Face Mask", "faceMask", active.props.faceMask ? 1 : 0],
                    [
                      "Face Mask Color",
                      "faceMaskColor",
                      active.props.faceMaskColor,
                    ],
                    ["Has Shape", "shape", active.props.shape ? 1 : 0],
                    ["Shape Color", "circleColor", active.props.circleColor],
                    ["Lashes", "lashes", active.props.lashes ? 1 : 0],
                  ] as const
                ).map(([label, key, idx]) => (
                  <div key={label} className="bg-white/5 rounded-md p-3">
                    <div className="text-xs text-white/60">{label}</div>
                    <div className="text-sm font-medium">
                      {typeof idx === "number"
                        ? traitLabel(key, idx)
                        : String(idx)}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MyCollections;
