import { BodyProps } from "@/components/bodies/types";
import { ClothingProps } from "@/components/clothing/types";
import { HairProps } from "@/components/hair/types";
import { HatProps } from "@/components/hats/types";

export interface GenesisAvatarParams {
  hairParams: {
    hairStyle: number;
    BackHair: React.ComponentType<HairProps>;
    FrontHair: React.ComponentType<HairProps>;
    hairColor: number;
  };
  bodyParams: {
    bodyType: number;
    Front: React.ComponentType<BodyProps>;
    Back: React.ComponentType<BodyProps>;
    skinColor: number;
    braStraps: boolean;
  };
  clothingParams: {
    clothes: number;
    ClothingBack: React.ComponentType<ClothingProps>;
    ClothingFront: React.ComponentType<ClothingProps>;
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
  accessoryParams: {
    accessoryId: number;
    hatStyle: number;
    BackHat: React.ComponentType<HatProps>;
    FrontHat: React.ComponentType<HatProps>;
    hatColor: number;
    scale: number;
  };
  otherParams: {
    mask: boolean;
    faceMask: boolean;
    faceMaskColor: number;
    shape: boolean;
    shapeColor: number;
    lashes: boolean;
  };
}
