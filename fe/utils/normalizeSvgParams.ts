import type { SVGParams } from "./avatarMapping";

function toBig(v: any): bigint {
  if (typeof v === "bigint") return v;
  if (typeof v === "number") return BigInt(v);
  if (typeof v === "string") return BigInt(v);
  if (v && typeof v.toString === "function") return BigInt(v.toString());
  throw new Error("Cannot convert to bigint: " + String(v));
}

function get(obj: any, key: string, index: number): any {
  if (obj == null) return undefined;
  if (Object.prototype.hasOwnProperty.call(obj, key)) return obj[key];
  if (Object.prototype.hasOwnProperty.call(obj, index)) return obj[index];
  return undefined;
}

export function normalizeSvgParams(raw: any): SVGParams {
  if (!raw) throw new Error("normalizeSvgParams: empty value");

  // Case A: already shaped (named nested keys)
  if (raw.hairParams && raw.bodyParams && raw.clothingParams) {
    return {
      accessoryParams: {
        accessoryId: toBig(raw.accessoryParams.accessoryId),
        hatStyle: toBig(raw.accessoryParams.hatStyle),
        hatColor: toBig(raw.accessoryParams.hatColor),
      },
      bodyParams: {
        bodyType: toBig(raw.bodyParams.bodyType),
        skinColor: toBig(raw.bodyParams.skinColor),
      },
      clothingParams: {
        clothes: toBig(raw.clothingParams.clothes),
        clothesGraphic: toBig(raw.clothingParams.clothesGraphic),
        clothingColor: toBig(raw.clothingParams.clothingColor),
      },
      hairParams: {
        hairStyle: toBig(raw.hairParams.hairStyle),
        hairColor: toBig(raw.hairParams.hairColor),
      },
      facialFeaturesParams: {
        eyebrowShape: toBig(raw.facialFeaturesParams.eyebrowShape),
        eyeShape: toBig(raw.facialFeaturesParams.eyeShape),
        facialHairType: toBig(raw.facialFeaturesParams.facialHairType),
        mouthStyle: toBig(raw.facialFeaturesParams.mouthStyle),
        lipColor: toBig(raw.facialFeaturesParams.lipColor),
      },
      otherParams: {
        shapeColor: toBig(raw.otherParams.shapeColor),
        faceMaskColor: toBig(raw.otherParams.faceMaskColor),
        faceMask: Boolean(raw.otherParams.faceMask),
        shapes: Boolean(raw.otherParams.shapes),
        lashes: Boolean(raw.otherParams.lashes),
      },
    };
  }

  // Case B: viem/ethers often return tuple-like object with numeric indices
  // or an actual array (Array.isArray(raw) === true)
  const acc = get(raw, "accessoryParams", 0);
  const body = get(raw, "bodyParams", 1);
  const cloth = get(raw, "clothingParams", 2);
  const hair = get(raw, "hairParams", 3);
  const facial = get(raw, "facialFeaturesParams", 4);
  const other = get(raw, "otherParams", 5);

  if (!acc || !body || !cloth || !hair || !facial || !other) {
    // Case C: you might be calling the wrong function (e.g., getAttributes returning a string)
    if (typeof raw === "string") {
      throw new Error(
        "normalizeSvgParams: got a string. Did you call getAttributes (string) instead of getAttributesByOwner (struct)?"
      );
    }
    console.error("normalizeSvgParams: unexpected shape:", raw);
    throw new Error("Invalid SVGParams shape from contract");
  }

  const accessoryParams = {
    accessoryId: toBig(get(acc, "accessoryId", 0)),
    hatStyle: toBig(get(acc, "hatStyle", 1)),
    hatColor: toBig(get(acc, "hatColor", 2)),
  };
  const bodyParams = {
    bodyType: toBig(get(body, "bodyType", 0)),
    skinColor: toBig(get(body, "skinColor", 1)),
  };
  const clothingParams = {
    clothes: toBig(get(cloth, "clothes", 0)),
    clothesGraphic: toBig(get(cloth, "clothesGraphic", 1)),
    clothingColor: toBig(get(cloth, "clothingColor", 2)),
  };
  const hairParams = {
    hairStyle: toBig(get(hair, "hairStyle", 0)),
    hairColor: toBig(get(hair, "hairColor", 1)),
  };
  const facialFeaturesParams = {
    eyebrowShape: toBig(get(facial, "eyebrowShape", 0)),
    eyeShape: toBig(get(facial, "eyeShape", 1)),
    facialHairType: toBig(get(facial, "facialHairType", 2)),
    mouthStyle: toBig(get(facial, "mouthStyle", 3)),
    lipColor: toBig(get(facial, "lipColor", 4)),
  };
  const otherParams = {
    shapeColor: toBig(get(other, "shapeColor", 0)),
    faceMaskColor: toBig(get(other, "faceMaskColor", 1)),
    faceMask: Boolean(get(other, "faceMask", 2)),
    shapes: Boolean(get(other, "shapes", 3)),
    lashes: Boolean(get(other, "lashes", 4)),
  };

  return {
    accessoryParams,
    bodyParams,
    clothingParams,
    hairParams,
    facialFeaturesParams,
    otherParams,
  };
}
