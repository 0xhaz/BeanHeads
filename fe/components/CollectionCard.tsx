"use client";

import { Avatar } from "./Avatar";
import type { SVGParams } from "@/utils/avatarMapping";

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
  params: SVGParams;
  onClose: () => void;
}

function labelFrom(arr: any[], id: bigint | number | boolean): string {
  if (typeof id === "boolean") return id ? "Yes" : "No";
  const num = Number(id);
  return arr.find(opt => opt.id === num)?.label ?? num.toString();
}

const CollectionCard = ({ params, onClose }: CollectionCardProps) => {
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
              hairStyle={Number(params.hairParams.hairStyle)}
              hairColor={Number(params.hairParams.hairColor)}
              body={Number(params.bodyParams.bodyType)}
              facialHair={Number(params.facialFeaturesParams.facialHairType)}
              clothingStyle={Number(params.clothingParams.clothes)}
              clothingColor={Number(params.clothingParams.clothingColor)}
              hat={Number(params.accessoryParams.hatStyle)}
              eyebrows={Number(params.facialFeaturesParams.eyebrowShape)}
              eyes={Number(params.facialFeaturesParams.eyeShape)}
              mouthShape={Number(params.facialFeaturesParams.mouthStyle)}
              mouthColor={Number(params.facialFeaturesParams.lipColor)}
              accessory={Number(params.accessoryParams.accessoryId)}
              skinColor={Number(params.bodyParams.skinColor)}
              hatColor={Number(params.accessoryParams.hatColor)}
              graphic={Number(params.clothingParams.clothesGraphic)}
              faceMaskColor={Number(params.otherParams.faceMaskColor)}
              circleColor={Number(params.otherParams.shapeColor)}
              mask={params.otherParams.shapes}
              faceMask={params.otherParams.faceMask}
              lashes={params.otherParams.lashes}
              shape={params.otherParams.shapes}
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-6 w-full text-sm">
          <div>
            <h3 className="text-lg font-bold underline mb-2">Hair</h3>
            <p>Style: {labelFrom(HAIR_STYLES, params?.hairParams.hairStyle)}</p>
            <p>Color: {labelFrom(HAIR_COLORS, params.hairParams.hairColor)}</p>
          </div>

          <div>
            <h3 className="text-lg font-bold underline mb-2">Body</h3>
            <p>Type: {labelFrom(BODY_TYPES, params.bodyParams.bodyType)}</p>
            <p>Skin: {labelFrom(SKIN_COLORS, params.bodyParams.skinColor)}</p>
          </div>

          <div>
            <h3 className="text-lg font-bold underline mb-2">Clothing</h3>
            <p>
              Style: {labelFrom(CLOTHING_STYLES, params.clothingParams.clothes)}
            </p>
            <p>
              Color:{" "}
              {labelFrom(CLOTHING_COLORS, params.clothingParams.clothingColor)}
            </p>
            <p>
              Graphic:{" "}
              {labelFrom(
                CLOTHING_GRAPHICS,
                params.clothingParams.clothesGraphic
              )}
            </p>
          </div>

          <div>
            <h3 className="text-lg font-bold underline mb-2">Facial</h3>
            <p>
              Eyebrows:{" "}
              {labelFrom(
                EYEBROW_SHAPES,
                params.facialFeaturesParams.eyebrowShape
              )}
            </p>
            <p>
              Eyes:{" "}
              {labelFrom(EYE_SHAPES, params.facialFeaturesParams.eyeShape)}
            </p>
            <p>
              Facial Hair:{" "}
              {labelFrom(
                FACIAL_HAIR_STYLES,
                params.facialFeaturesParams.facialHairType
              )}
            </p>
            <p>
              Mouth:{" "}
              {labelFrom(MOUTH_SHAPES, params.facialFeaturesParams.mouthStyle)}
            </p>
            <p>
              Lips Color:{" "}
              {labelFrom(LIP_COLORS, params.facialFeaturesParams.lipColor)}
            </p>
          </div>

          <div>
            <h3 className="text-lg font-bold underline mb-2">Misc</h3>
            <p>Face Mask: {params.otherParams.faceMask ? "Yes" : "No"}</p>
            <p>
              Face Mask Color:{" "}
              {labelFrom(CLOTHING_COLORS, params.otherParams.faceMaskColor)}
            </p>
            <p>Shapes: {params.otherParams.shapes ? "Yes" : "No"}</p>
            <p>
              Shape Color: {labelFrom(BG_COLORS, params.otherParams.shapeColor)}
            </p>
            <p>Lashes: {params.otherParams.lashes ? "Yes" : "No"}</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CollectionCard;
