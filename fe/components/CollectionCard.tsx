"use client";

import { Avatar } from "./Avatar";
import type { SVGParams } from "@/utils/avatarMapping";
import { useBeanHeads } from "@/context/beanheads";
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
import { useActiveAccount, useActiveWallet } from "thirdweb/react";

interface CollectionCardProps {
  tokenId: bigint;
  params: SVGParams;
  generation?: bigint;
  loading?: boolean;
  onClose: () => void;
}

function labelFrom(arr: any[], id: bigint | number | boolean): string {
  if (typeof id === "boolean") return id ? "Yes" : "No";
  const num = Number(id);
  return arr.find(opt => opt.id === num)?.label ?? num.toString();
}

const CollectionCard = ({
  tokenId,
  params,
  generation,
  loading,
  onClose,
}: CollectionCardProps) => {
  return (
    <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-black/90 text-white p-8 overflow-y-auto ">
      <button
        className="absolute top-50 right-70 text-4xl font-bold hover:text-red-400 cursor-pointer"
        onClick={onClose}
      >
        x
      </button>

      <div className="flex flex-col lg:flex-row items-center gap-10 w-full max-w-6xl">
        <div className="flex-shrink-0 w-full lg:w-1/3 flex justify-center">
          <div className="w-[300px] h-[300px] border-4 border-white rounded-3xl overflow-hidden bg-white">
            <Avatar
              hairStyle={Number(params?.hairParams?.hairStyle ?? 0)}
              hairColor={Number(params?.hairParams?.hairColor ?? 0)}
              body={Number(params?.bodyParams?.bodyType ?? 0)}
              facialHair={Number(
                params?.facialFeaturesParams?.facialHairType ?? 0
              )}
              clothingStyle={Number(params?.clothingParams?.clothes ?? 0)}
              clothingColor={Number(params?.clothingParams?.clothingColor ?? 0)}
              hat={Number(params?.accessoryParams?.hatStyle ?? 0)}
              eyebrows={Number(params?.facialFeaturesParams?.eyebrowShape ?? 0)}
              eyes={Number(params?.facialFeaturesParams?.eyeShape ?? 0)}
              mouthShape={Number(params?.facialFeaturesParams?.mouthStyle ?? 0)}
              mouthColor={Number(params?.facialFeaturesParams?.lipColor ?? 0)}
              accessory={Number(params?.accessoryParams?.accessoryId ?? 0)}
              skinColor={Number(params?.bodyParams?.skinColor ?? 0)}
              hatColor={Number(params?.accessoryParams?.hatColor ?? 0)}
              graphic={Number(params?.clothingParams?.clothesGraphic ?? 0)}
              faceMaskColor={Number(params?.otherParams?.faceMaskColor ?? 0)}
              circleColor={Number(params?.otherParams?.shapeColor ?? 0)}
              mask={params?.otherParams?.shapes ?? false}
              faceMask={params?.otherParams?.faceMask ?? false}
              lashes={params?.otherParams?.lashes ?? false}
              shape={params?.otherParams?.shapes ?? false}
            />
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

          <div className="grid grid-cols-2 gap-6 w-full text-sm  ">
            <div>
              <h3 className="text-lg font-bold underline mb-2">Hair</h3>
              <p>
                Style:{" "}
                {labelFrom(HAIR_STYLES, params?.hairParams?.hairStyle ?? 0)}
              </p>
              <p>
                Color:{" "}
                {labelFrom(HAIR_COLORS, params?.hairParams?.hairColor ?? 0)}
              </p>
            </div>

            <div>
              <h3 className="text-lg font-bold underline mb-2">Body</h3>
              <p>
                Type: {labelFrom(BODY_TYPES, params?.bodyParams?.bodyType ?? 0)}
              </p>
              <p>
                Skin:{" "}
                {labelFrom(SKIN_COLORS, params?.bodyParams?.skinColor ?? 0)}
              </p>
            </div>

            <div>
              <h3 className="text-lg font-bold underline mb-2">Clothing</h3>
              <p>
                Style:{" "}
                {labelFrom(
                  CLOTHING_STYLES,
                  params?.clothingParams?.clothes ?? 0
                )}
              </p>
              <p>
                Color:{" "}
                {labelFrom(
                  CLOTHING_COLORS,
                  params?.clothingParams?.clothingColor ?? 0
                )}
              </p>
              <p>
                Graphic:{" "}
                {labelFrom(
                  CLOTHING_GRAPHICS,
                  params?.clothingParams?.clothesGraphic ?? 0
                )}
              </p>
            </div>

            <div>
              <h3 className="text-lg font-bold underline mb-2">Facial</h3>
              <p>
                Eyebrows:{" "}
                {labelFrom(
                  EYEBROW_SHAPES,
                  params?.facialFeaturesParams?.eyebrowShape ?? 0
                )}
              </p>
              <p>
                Eyes:{" "}
                {labelFrom(
                  EYE_SHAPES,
                  params?.facialFeaturesParams?.eyeShape ?? 0
                )}
              </p>
              <p>
                Facial Hair:{" "}
                {labelFrom(
                  FACIAL_HAIR_STYLES,
                  params?.facialFeaturesParams?.facialHairType ?? 0
                )}
              </p>
              <p>
                Mouth:{" "}
                {labelFrom(
                  MOUTH_SHAPES,
                  params?.facialFeaturesParams?.mouthStyle ?? 0
                )}
              </p>
              <p>
                Lips Color:{" "}
                {labelFrom(
                  LIP_COLORS,
                  params?.facialFeaturesParams?.lipColor ?? 0
                )}
              </p>
            </div>

            <div>
              <h3 className="text-lg font-bold underline mb-2">Misc</h3>
              <p>Face Mask: {params?.otherParams?.faceMask ? "Yes" : "No"}</p>
              <p>
                Face Mask Color:{" "}
                {labelFrom(
                  CLOTHING_COLORS,
                  params?.otherParams?.faceMaskColor ?? 0
                )}
              </p>
              <p>Shapes: {params?.otherParams?.shapes ? "Yes" : "No"}</p>
              <p>
                Shape Color:{" "}
                {labelFrom(BG_COLORS, params?.otherParams?.shapeColor ?? 0)}
              </p>
              <p>Lashes: {params?.otherParams?.lashes ? "Yes" : "No"}</p>
            </div>

            <div>
              <h3 className="text-lg font-bold underline mb-2">Generation</h3>
              <p>Gen: {generation}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CollectionCard;
