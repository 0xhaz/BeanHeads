// utils/normalizeSvgParams.ts
import type { SVGParams } from "./avatarMapping";

function toBig(v: any): bigint {
  if (typeof v === "bigint") return v;
  if (typeof v === "number") return BigInt(v);
  if (typeof v === "string") return BigInt(v);
  if (v && typeof v.toString === "function") return BigInt(v.toString());
  throw new Error("Cannot convert to bigint: " + String(v));
}

function pick(obj: any, key: string, index: number) {
  if (obj == null) return undefined;
  if (Object.prototype.hasOwnProperty.call(obj, key)) return obj[key];
  if (Object.prototype.hasOwnProperty.call(obj, index)) return obj[index];
  return undefined;
}

export function normalizeSvgParams(raw: any): SVGParams {
  if (!raw) throw new Error("normalizeSvgParams: empty value");

  // Already shaped with named keys?
  if (raw.hairParams && raw.bodyParams && raw.clothingParams) {
    return {
      hairParams: {
        hairStyle: toBig(raw.hairParams.hairStyle) as unknown as bigint,
        hairColor: toBig(raw.hairParams.hairColor) as unknown as bigint,
      },
      bodyParams: {
        bodyType: toBig(raw.bodyParams.bodyType) as unknown as bigint,
        skinColor: toBig(raw.bodyParams.skinColor) as unknown as bigint,
      },
      // IMPORTANT: clothing order = clothes, clothingColor, clothesGraphic
      clothingParams: {
        clothes: toBig(raw.clothingParams.clothes) as unknown as bigint,
        clothingColor: toBig(
          raw.clothingParams.clothingColor
        ) as unknown as bigint,
        clothesGraphic: toBig(
          raw.clothingParams.clothesGraphic
        ) as unknown as bigint,
      },
      facialFeaturesParams: {
        eyebrowShape: toBig(
          raw.facialFeaturesParams.eyebrowShape
        ) as unknown as bigint,
        eyeShape: toBig(raw.facialFeaturesParams.eyeShape) as unknown as bigint,
        facialHairType: toBig(
          raw.facialFeaturesParams.facialHairType
        ) as unknown as bigint,
        mouthStyle: toBig(
          raw.facialFeaturesParams.mouthStyle
        ) as unknown as bigint,
        lipColor: toBig(raw.facialFeaturesParams.lipColor) as unknown as bigint,
      },
      accessoryParams: {
        accessoryId: toBig(
          raw.accessoryParams.accessoryId
        ) as unknown as bigint,
        hatStyle: toBig(raw.accessoryParams.hatStyle) as unknown as bigint,
        hatColor: toBig(raw.accessoryParams.hatColor) as unknown as bigint,
      },
      // IMPORTANT: other order = faceMask, faceMaskColor, shapes, shapeColor, lashes
      otherParams: {
        faceMask: Boolean(raw.otherParams.faceMask),
        faceMaskColor: toBig(
          raw.otherParams.faceMaskColor
        ) as unknown as bigint,
        shapes: Boolean(raw.otherParams.shapes),
        shapeColor: toBig(raw.otherParams.shapeColor) as unknown as bigint,
        lashes: Boolean(raw.otherParams.lashes),
      },
    };
  }

  // Tuple / numeric-key object case
  const hair = pick(raw, "hairParams", 0);
  const body = pick(raw, "bodyParams", 1);
  const cloth = pick(raw, "clothingParams", 2);
  const facial = pick(raw, "facialFeaturesParams", 3);
  const acc = pick(raw, "accessoryParams", 4);
  const other = pick(raw, "otherParams", 5);

  if (!hair || !body || !cloth || !facial || !acc || !other) {
    console.error("normalizeSvgParams: unexpected shape:", raw);
    throw new Error("Invalid SVGParams shape from contract");
  }

  return {
    hairParams: {
      hairStyle: toBig(pick(hair, "hairStyle", 0)) as unknown as bigint,
      hairColor: toBig(pick(hair, "hairColor", 1)) as unknown as bigint,
    },
    bodyParams: {
      bodyType: toBig(pick(body, "bodyType", 0)) as unknown as bigint,
      skinColor: toBig(pick(body, "skinColor", 1)) as unknown as bigint,
    },
    // order: clothes, clothingColor, clothesGraphic
    clothingParams: {
      clothes: toBig(pick(cloth, "clothes", 0)) as unknown as bigint,
      clothingColor: toBig(
        pick(cloth, "clothingColor", 1)
      ) as unknown as bigint,
      clothesGraphic: toBig(
        pick(cloth, "clothesGraphic", 2)
      ) as unknown as bigint,
    },
    facialFeaturesParams: {
      eyebrowShape: toBig(pick(facial, "eyebrowShape", 0)) as unknown as bigint,
      eyeShape: toBig(pick(facial, "eyeShape", 1)) as unknown as bigint,
      facialHairType: toBig(
        pick(facial, "facialHairType", 2)
      ) as unknown as bigint,
      mouthStyle: toBig(pick(facial, "mouthStyle", 3)) as unknown as bigint,
      lipColor: toBig(pick(facial, "lipColor", 4)) as unknown as bigint,
    },
    accessoryParams: {
      accessoryId: toBig(pick(acc, "accessoryId", 0)) as unknown as bigint,
      hatStyle: toBig(pick(acc, "hatStyle", 1)) as unknown as bigint,
      hatColor: toBig(pick(acc, "hatColor", 2)) as unknown as bigint,
    },
    // order: faceMask, faceMaskColor, shapes, shapeColor, lashes
    otherParams: {
      faceMask: Boolean(pick(other, "faceMask", 0)),
      faceMaskColor: toBig(
        pick(other, "faceMaskColor", 1)
      ) as unknown as bigint,
      shapes: Boolean(pick(other, "shapes", 2)),
      shapeColor: toBig(pick(other, "shapeColor", 3)) as unknown as bigint,
      lashes: Boolean(pick(other, "lashes", 4)),
    },
  };
}
