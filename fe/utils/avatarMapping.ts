import type { AvatarProps } from "@/components/Avatar";
export interface SVGParams {
  hairParams: { hairStyle: bigint; hairColor: bigint };
  bodyParams: { bodyType: bigint; skinColor: bigint };
  clothingParams: {
    clothes: bigint;
    clothingColor: bigint;
    clothesGraphic: bigint;
  };
  facialFeaturesParams: {
    eyebrowShape: bigint;
    eyeShape: bigint;
    facialHairType: bigint;
    mouthStyle: bigint;
    lipColor: bigint;
  };
  accessoryParams: { accessoryId: bigint; hatStyle: bigint; hatColor: bigint };
  otherParams: {
    faceMask: boolean;
    faceMaskColor: bigint;
    shapes: boolean;
    shapeColor: bigint;
    lashes: boolean;
  };
}

export function svgParamsToAvatarProps(p: SVGParams): AvatarProps {
  const shape = p.otherParams.shapes;
  const mask = shape;

  return {
    hairStyle: Number(p.hairParams.hairStyle),
    hairColor: Number(p.hairParams.hairColor),
    body: Number(p.bodyParams.bodyType),
    facialHair: Number(p.facialFeaturesParams.facialHairType),
    clothingStyle: Number(p.clothingParams.clothes),
    clothingColor: Number(p.clothingParams.clothingColor),
    hat: Number(p.accessoryParams.hatStyle),
    eyebrows: Number(p.facialFeaturesParams.eyebrowShape),
    eyes: Number(p.facialFeaturesParams.eyeShape),
    mouthShape: Number(p.facialFeaturesParams.mouthStyle),
    mouthColor: Number(p.facialFeaturesParams.lipColor),
    accessory: Number(p.accessoryParams.accessoryId),
    skinColor: Number(p.bodyParams.skinColor),
    circleColor: Number(p.otherParams.shapeColor),
    hatColor: Number(p.accessoryParams.hatColor),
    graphic: Number(p.clothingParams.clothesGraphic),
    faceMaskColor: Number(p.otherParams.faceMaskColor),
    faceMask: p.otherParams.faceMask,
    lashes: p.otherParams.lashes,
    shape,
    mask,
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
  // (p.otherParams.mask ? "true" : "false");

  return part1 + part2 + part3;
}
