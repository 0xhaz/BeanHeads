import { generateRandomAvatarAttributes } from "@/components/Avatar";

export type SVGParams = {
  hairParams: { hairStyle: number; hairColor: number };
  bodyParams: { bodyType: number; skinColor: number };
  clothingParams: {
    clothes: number;
    clothingColor: number;
    clothesGraphic: number;
  };
  facialFeaturesParams: {
    eyebrowShape: number;
    eyeShape: number;
    facialHairType: number;
    mouthStyle: number;
    lipColor: number;
  };
  accessoryParams: { accessoryId: number; hatStyle: number; hatColor: number };
  otherParams: {
    faceMask: boolean;
    faceMaskColor: number;
    shapes: boolean;
    shapeColor: number;
    lashes: boolean;
  };
};

export function toSVGParamsFromAvatar(
  avatar: ReturnType<typeof generateRandomAvatarAttributes>
): SVGParams {
  return {
    hairParams: {
      hairStyle: avatar.hair.style,
      hairColor: avatar.hair.color,
    },
    bodyParams: {
      bodyType: avatar.body.type,
      skinColor: avatar.body.skinColor,
    },
    clothingParams: {
      clothes: avatar.clothing.style,
      clothingColor: avatar.clothing.color,
      clothesGraphic: avatar.clothing.graphic,
    },
    facialFeaturesParams: {
      eyebrows: undefined, // not in struct; map correctly:
      eyebrowShape: avatar.facialFeatures.eyebrows,
      eyeShape: avatar.facialFeatures.eyes,
      facialHairType: avatar.facialFeatures.facialHair,
      mouthStyle: avatar.facialFeatures.mouth,
      lipColor: avatar.facialFeatures.lipColor,
    } as any, // or fix the key names at source
    accessoryParams: {
      accessoryId: avatar.accessories.accessory,
      hatStyle: avatar.accessories.hat,
      hatColor: avatar.accessories.hatColor,
    },
    otherParams: {
      faceMask: avatar.misc.faceMask,
      faceMaskColor: avatar.misc.faceMaskColor,
      shapes: avatar.misc.shape,
      shapeColor: avatar.misc.shapeColor,
      lashes: avatar.misc.lashes,
    },
  };
}
