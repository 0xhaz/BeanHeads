// utils/avatarMapping.ts
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

/** Safe defaults to guarantee shape */
const DEF: SVGParams = {
  hairParams: { hairStyle: BigInt(0), hairColor: BigInt(0) },
  bodyParams: { bodyType: BigInt(0), skinColor: BigInt(0) },
  clothingParams: {
    clothes: BigInt(0),
    clothingColor: BigInt(0),
    clothesGraphic: BigInt(0),
  },
  facialFeaturesParams: {
    eyebrowShape: BigInt(0),
    eyeShape: BigInt(0),
    facialHairType: BigInt(0),
    mouthStyle: BigInt(0),
    lipColor: BigInt(0),
  },
  accessoryParams: {
    accessoryId: BigInt(0),
    hatStyle: BigInt(0),
    hatColor: BigInt(0),
  },
  otherParams: {
    faceMask: false,
    faceMaskColor: BigInt(0),
    shapes: false,
    shapeColor: BigInt(0),
    lashes: false,
  },
};

/** Merge helper that fills missing nested keys with defaults (handles undefined safely) */
function fillDefaults(p?: Partial<SVGParams> | SVGParams): SVGParams {
  const src = (p ?? {}) as any;
  return {
    hairParams: { ...DEF.hairParams, ...(src.hairParams ?? {}) },
    bodyParams: { ...DEF.bodyParams, ...(src.bodyParams ?? {}) },
    clothingParams: { ...DEF.clothingParams, ...(src.clothingParams ?? {}) },
    facialFeaturesParams: {
      ...DEF.facialFeaturesParams,
      ...(src.facialFeaturesParams ?? {}),
    },
    accessoryParams: { ...DEF.accessoryParams, ...(src.accessoryParams ?? {}) },
    otherParams: { ...DEF.otherParams, ...(src.otherParams ?? {}) },
  };
}

/** Utility: clamp/modulo any (bigint/number) into [0, len-1] */
function clamp(n: unknown, len: number): number {
  const x = typeof n === "bigint" ? Number(n) : Number(n ?? 0);
  if (!Number.isFinite(x) || len <= 0) return 0;
  return ((x % len) + len) % len;
}

/**
 * Keep these in sync with the array lengths in components/Avatar.tsx
 * (If you add/remove styles/colors, update these numbers.)
 */
const RANGES = {
  hairStyle: 8, // HAIR_STYLES.length
  hairColor: 7, // HAIR_COLORS.length
  body: 2, // BODY_TYPES.length
  facialHair: 3, // FACIAL_HAIR_STYLES.length
  clothingStyle: 6, // CLOTHING_STYLES.length
  clothingColor: 5, // CLOTHING_COLORS.length
  hat: 3, // HAT_STYLES.length
  eyebrows: 5, // EYEBROW_SHAPES.length
  eyes: 9, // EYE_SHAPES.length
  mouthShape: 7, // MOUTH_SHAPES.length
  mouthColor: 5, // LIP_COLORS.length
  accessory: 4, // ACCESSORIES.length
  skinColor: 6, // SKIN_COLORS.length
  circleColor: 5, // BG_COLORS.length
  hatColor: 5, // CLOTHING_COLORS.length
  graphic: 6, // CLOTHING_GRAPHICS.length
  faceMaskColor: 5, // CLOTHING_COLORS.length
};

/** Safe converter with clamping; accepts possibly-undefined/partial input */
export function svgParamsToAvatarProps(
  _p?: Partial<SVGParams> | SVGParams
): AvatarProps {
  const p = fillDefaults(_p);

  const shape = !!p.otherParams.shapes;
  const mask = shape;

  return {
    hairStyle: clamp(p.hairParams.hairStyle, RANGES.hairStyle),
    hairColor: clamp(p.hairParams.hairColor, RANGES.hairColor),
    body: clamp(p.bodyParams.bodyType, RANGES.body),
    facialHair: clamp(p.facialFeaturesParams.facialHairType, RANGES.facialHair),
    clothingStyle: clamp(p.clothingParams.clothes, RANGES.clothingStyle),
    clothingColor: clamp(p.clothingParams.clothingColor, RANGES.clothingColor),
    hat: clamp(p.accessoryParams.hatStyle, RANGES.hat),
    eyebrows: clamp(p.facialFeaturesParams.eyebrowShape, RANGES.eyebrows),
    eyes: clamp(p.facialFeaturesParams.eyeShape, RANGES.eyes),
    mouthShape: clamp(p.facialFeaturesParams.mouthStyle, RANGES.mouthShape),
    mouthColor: clamp(p.facialFeaturesParams.lipColor, RANGES.mouthColor),
    accessory: clamp(p.accessoryParams.accessoryId, RANGES.accessory),
    skinColor: clamp(p.bodyParams.skinColor, RANGES.skinColor),
    circleColor: clamp(p.otherParams.shapeColor, RANGES.circleColor),
    hatColor: clamp(p.accessoryParams.hatColor, RANGES.hatColor),
    graphic: clamp(p.clothingParams.clothesGraphic, RANGES.graphic),
    faceMaskColor: clamp(p.otherParams.faceMaskColor, RANGES.faceMaskColor),
    faceMask: !!p.otherParams.faceMask,
    lashes: !!p.otherParams.lashes,
    shape,
    mask,
  };
}

export function getParamsFromAttributes(
  _p?: Partial<SVGParams> | SVGParams
): string {
  const p = fillDefaults(_p);

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
