import type { AvatarProps } from "@/components/Avatar";
export interface SVGParams {
  accessoryParams: {
    accessoryId: bigint;
    hatStyle: bigint;
    hatColor: bigint;
  };
  bodyParams: {
    bodyType: bigint;
    skinColor: bigint;
  };
  clothingParams: {
    clothes: bigint;
    clothesGraphic: bigint;
    clothingColor: bigint;
  };
  hairParams: {
    hairStyle: bigint;
    hairColor: bigint;
  };
  facialFeaturesParams: {
    eyebrowShape: bigint;
    eyeShape: bigint;
    facialHairType: bigint;
    mouthStyle: bigint;
    lipColor: bigint;
  };
  otherParams: {
    shapeColor: bigint;
    faceMaskColor: bigint;
    faceMask: boolean;
    shapes: boolean;
    lashes: boolean;
  };
}

export function svgParamsToAvatarProps(params: SVGParams): AvatarProps {
  return {
    hairStyle: Number(params.hairParams.hairStyle),
    hairColor: Number(params.hairParams.hairColor),
    body: Number(params.bodyParams.bodyType),
    facialHair: Number(params.facialFeaturesParams.facialHairType),
    clothingStyle: Number(params.clothingParams.clothes),
    clothingColor: Number(params.clothingParams.clothingColor),
    hat: Number(params.accessoryParams.hatStyle),
    eyebrows: Number(params.facialFeaturesParams.eyebrowShape),
    eyes: Number(params.facialFeaturesParams.eyeShape),
    mouthShape: Number(params.facialFeaturesParams.mouthStyle),
    mouthColor: Number(params.facialFeaturesParams.lipColor),
    accessory: Number(params.accessoryParams.accessoryId),
    skinColor: Number(params.bodyParams.skinColor),
    circleColor: Number(params.otherParams.shapeColor),
    hatColor: Number(params.accessoryParams.hatColor),
    graphic: Number(params.clothingParams.clothesGraphic),
    faceMaskColor: Number(params.otherParams.faceMaskColor),
    faceMask: params.otherParams.faceMask,
    lashes: params.otherParams.lashes,
    shape: params.otherParams.shapes,
    mask: false, // Deprecated
  };
}

export function getParamsFromAttributes(p: SVGParams): string {
  const part1 =
    p.accessoryParams.accessoryId.toString() +
    p.bodyParams.bodyType.toString() +
    p.clothingParams.clothes.toString() +
    p.hairParams.hairStyle.toString() +
    p.clothingParams.clothesGraphic.toString() +
    p.facialFeaturesParams.eyebrowShape.toString() +
    p.facialFeaturesParams.eyeShape.toString();

  const part2 =
    p.facialFeaturesParams.facialHairType.toString() +
    p.accessoryParams.hatStyle.toString() +
    p.facialFeaturesParams.mouthStyle.toString() +
    p.bodyParams.skinColor.toString() +
    p.clothingParams.clothingColor.toString() +
    p.hairParams.hairColor.toString() +
    p.accessoryParams.hatColor.toString();

  const part3 =
    p.otherParams.shapeColor.toString() +
    p.facialFeaturesParams.lipColor.toString() +
    p.otherParams.faceMaskColor.toString() +
    (p.otherParams.faceMask ? "true" : "false") +
    (p.otherParams.shapes ? "true" : "false") +
    (p.otherParams.lashes ? "true" : "false");

  return part1 + part2 + part3;
}
