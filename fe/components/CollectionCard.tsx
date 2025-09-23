"use client";

import React, { useMemo } from "react";
import { Avatar } from "./Avatar";
import type { SVGParams } from "@/utils/avatarMapping";
import { svgParamsToAvatarProps } from "@/utils/avatarMapping"; // ⬅️ use the converter
import {
  HAIR_STYLES,
  BODY_TYPES,
  FACIAL_HAIR_STYLES,
  CLOTHING_STYLES,
  CLOTHING_GRAPHICS,
  HAT_STYLES,
  EYEBROW_SHAPES,
  EYE_SHAPES,
  MOUTH_SHAPES,
  ACCESSORIES,
  HAIR_COLORS,
  CLOTHING_COLORS,
  LIP_COLORS,
  BG_COLORS,
  SKIN_COLORS,
} from "@/components/Avatar";

interface CollectionCardProps {
  tokenId: bigint;
  params: SVGParams;
  generation?: bigint;
  rarityPoints?: bigint;
  breedCount?: bigint;
  maxBreeds?: number;
  loading?: boolean;
  onClose: () => void;
}

/** clamp to valid array index & return label */
function labelFrom(arr: { id?: number; label?: string }[], idxLike: unknown) {
  const n = Number(idxLike);
  if (!Number.isFinite(n) || arr.length === 0) return String(idxLike ?? 0);
  const idx = Math.max(0, Math.min(arr.length - 1, n));
  return arr[idx]?.label ?? String(idx);
}

const CollectionCard = ({
  tokenId,
  params,
  generation,
  rarityPoints,
  breedCount,
  maxBreeds = 5,
  loading,
  onClose,
}: CollectionCardProps) => {
  // Convert *once* to the normalized/clamped AvatarProps
  const av = useMemo(() => svgParamsToAvatarProps(params), [params]);
  const used = Number(breedCount ?? 0);
  const max = Number(maxBreeds ?? 5);
  const remaining = Math.max(0, max - used);

  return (
    <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-black/90 text-white p-8 overflow-y-auto">
      <button
        className="absolute top-6 right-8 text-4xl font-bold hover:text-red-400 cursor-pointer"
        onClick={onClose}
        aria-label="Close"
      >
        ×
      </button>

      <div className="flex flex-col lg:flex-row items-center gap-10 w-full max-w-6xl">
        <div className="flex-shrink-0 w-full lg:w-1/3 flex justify-center">
          <div className="w-[300px] h-[300px] border-4 border-white rounded-3xl overflow-hidden bg-white">
            {/* Use the clamped AvatarProps */}
            <Avatar {...av} />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-8 flex-1 text-sm">
          <div className="col-span-2">
            <h3 className="text-xl font-bold">
              Token #{tokenId.toString()}{" "}
              {loading
                ? "(loading…)"
                : generation !== undefined
                ? `(Gen ${generation.toString()})`
                : ""}
            </h3>
          </div>

          <div className="grid grid-cols-2 gap-6 w-full text-sm">
            <div>
              <h3 className="text-lg font-bold underline mb-2">Hair</h3>
              <p>Style: {labelFrom(HAIR_STYLES, av.hairStyle)}</p>
              <p>Color: {labelFrom(HAIR_COLORS, av.hairColor)}</p>
            </div>

            <div>
              <h3 className="text-lg font-bold underline mb-2">Body</h3>
              <p>Type: {labelFrom(BODY_TYPES, av.body)}</p>
              <p>Skin: {labelFrom(SKIN_COLORS, av.skinColor)}</p>
            </div>

            <div>
              <h3 className="text-lg font-bold underline mb-2">Clothing</h3>
              <p>Style: {labelFrom(CLOTHING_STYLES, av.clothingStyle)}</p>
              <p>Color: {labelFrom(CLOTHING_COLORS, av.clothingColor)}</p>
              <p>Graphic: {labelFrom(CLOTHING_GRAPHICS, av.graphic)}</p>
            </div>

            <div>
              <h3 className="text-lg font-bold underline mb-2">Facial</h3>
              <p>Eyebrows: {labelFrom(EYEBROW_SHAPES, av.eyebrows)}</p>
              <p>Eyes: {labelFrom(EYE_SHAPES, av.eyes)}</p>
              <p>Facial Hair: {labelFrom(FACIAL_HAIR_STYLES, av.facialHair)}</p>
              <p>Mouth: {labelFrom(MOUTH_SHAPES, av.mouthShape)}</p>
              <p>Lips Color: {labelFrom(LIP_COLORS, av.mouthColor)}</p>
            </div>

            <div>
              <h3 className="text-lg font-bold underline mb-2">Misc</h3>
              <p>Face Mask: {av.faceMask ? "Yes" : "No"}</p>
              <p>
                Face Mask Color: {labelFrom(CLOTHING_COLORS, av.faceMaskColor)}
              </p>
              <p>Shapes: {av.shape ? "Yes" : "No"}</p>
              <p>Shape Color: {labelFrom(BG_COLORS, av.circleColor)}</p>
              <p>Lashes: {av.lashes ? "Yes" : "No"}</p>
              <p>Hat: {labelFrom(HAT_STYLES, av.hat)}</p>
              <p>Hat Color: {labelFrom(CLOTHING_COLORS, av.hatColor)}</p>
              <p>Accessory: {labelFrom(ACCESSORIES, av.accessory)}</p>
            </div>

            <div>
              <h3 className="text-lg font-bold underline mb-2">Generation</h3>
              <p>Gen: {generation?.toString() ?? "-"}</p>
              <p>Rarity Points: {rarityPoints?.toString() ?? "0"}</p>
              <p>
                Breeds Used: {used} / {max}{" "}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CollectionCard;
