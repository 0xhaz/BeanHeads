import {
  HairStyleId,
  BodyTypeId,
  FacialHairId,
  ClothingStyleId,
  HatStyleId,
  EyebrowShapeId,
  EyeShapeId,
  MouthShapeId,
  AccessoryId,
  ClothingGraphicId,
  BGColorId,
  SkinColorId,
  HairColorId,
  LipColorId,
  ClothColorId,
} from "./GenesisIndex";
import { colors } from "@/utils/theme";
import { ThemeContext } from "@/utils/themeContext";
import { Noop } from "@/utils/Noop";
import { Base } from "@/components/Base";
import { NormalEyebrows } from "@/components/eyebrows/Normal";
import { LeftLoweredEyebrows } from "@/components/eyebrows/LeftLoweredEyebrows";
import { Grin } from "@/components/mouths/Grin";
import { SadMouth } from "@/components/mouths/Sad";
import { Lips } from "@/components/mouths/Lips";
import { SmileOpen } from "@/components/mouths/SmileOpen";
import * as LongHair from "@/components/hair/LongHair";
import * as BunHair from "@/components/hair/BunHair";
import * as ShortHair from "@/components/hair/ShortHair";
import * as PixieCut from "@/components/hair/PixieCut";
import * as BaldingHair from "@/components/hair/BaldingHair";
import * as Afro from "@/components/hair/Afro";
import * as BobCut from "@/components/hair/BobCut";
import * as Beanie from "@/components/hats/Beanie";
import * as Turban from "@/components/hats/Turban";
import * as Chest from "@/components/bodies/Chest";
import * as Breasts from "@/components/bodies/Breasts";
import { MediumBeard } from "@/components/facialHair/MediumBeard";
import { HappyEyes } from "@/components/eyes/HappyEyes";
import { NormalEyes } from "@/components/eyes/NormalEyes";
import { LeftTwitchEyes } from "@/components/eyes/LeftTwitchEyes";
import { Shirt } from "@/components/clothing/Shirt";
import { ContentEyes } from "@/components/eyes/ContentEyes";
import { SeriousEyebrows } from "@/components/eyebrows/SeriousEyebrows";
import { RoundGlasses } from "@/components/accessories/RoundGlasses";
import { AngryEyebrows } from "@/components/eyebrows/AngryEyebrows";
import { StubbleBeard } from "@/components/facialHair/Stubble";
import { RedwoodGraphic } from "@/components/clothingGraphic/Redwood";
import { GatsbyGraphic } from "@/components/clothingGraphic/Gatsby";
import * as Dress from "@/components/clothing/Dress";
import { SquintEyes } from "@/components/eyes/SquintEyes";
import { ConcernedEyebrows } from "@/components/eyebrows/ConcernedEyebrows";
import { Shades } from "@/components/accessories/Shades";
import { TankTop } from "@/components/clothing/TankTop";
import { SimpleEyes } from "@/components/eyes/SimpleEyes";
import { Vue as VueGrpahics } from "@/components/clothingGraphic/Vue";
import { DizzyEyes } from "@/components/eyes/DizzyEyes";
import { WinkEyes } from "@/components/eyes/Wink";
import { HeartEyes } from "@/components/eyes/HeartEyes";
import { OpenMouth } from "@/components/mouths/OpenMouth";
import { SeriousMouth } from "@/components/mouths/SeriousMouth";
import { ReactGraphic } from "@/components/clothingGraphic/React";
import { TinyGlasses } from "@/components/accessories/TinyGlasses";
import { VNeck } from "@/components/clothing/VNeck";
import { GraphQLGraphic } from "@/components/clothingGraphic/GraphQL";
import { Tongue } from "@/components/mouths/Tongue";
import { DressShirt } from "@/components/clothing/DressShirt";

export const HAIR_STYLES = [
  { id: 0, label: "None", Front: Noop, Back: Noop },
  { id: 1, label: "Afro", Front: Afro.Front, Back: Afro.Back },
  { id: 2, label: "Balding", Front: BaldingHair.Front, Back: BaldingHair.Back },
  { id: 3, label: "Bob Cut", Front: BobCut.Front, Back: BobCut.Back },
  { id: 4, label: "Bun", Front: BunHair.Front, Back: BunHair.Back },
  { id: 5, label: "Long", Front: LongHair.Front, Back: LongHair.Back },
  { id: 6, label: "Pixie Cut", Front: PixieCut.Front, Back: PixieCut.Back },
  { id: 7, label: "Short", Front: ShortHair.Front, Back: ShortHair.Back },
];

export const BODY_TYPES = [
  { id: 0, label: "Chest", Front: Chest.Front, Back: Chest.Back },
  { id: 1, label: "Breasts", Front: Breasts.Front, Back: Breasts.Back },
];

export const FACIAL_HAIR_STYLES = [
  { id: 0, label: "None", Component: Noop },
  { id: 1, label: "Medium Beard", Component: MediumBeard },
  { id: 2, label: "Stubble", Component: StubbleBeard },
];

export const CLOTHING_STYLES = [
  { id: 0, label: "Naked", Front: Noop, Back: Noop },
  { id: 1, label: "Dress", Front: Dress.Front, Back: Dress.Back },
  { id: 2, label: "Shirt", Front: Noop, Back: DressShirt },
  { id: 3, label: "T-Shirt", Front: Noop, Back: Shirt },
  { id: 4, label: "Tank Top", Front: Noop, Back: TankTop },
  { id: 5, label: "V-Neck", Front: Noop, Back: VNeck },
];

export const CLOTHING_GRAPHICS = [
  { id: 0, label: "None", Component: Noop },
  { id: 1, label: "Gatsby", Component: GatsbyGraphic },
  { id: 2, label: "GraphQL", Component: GraphQLGraphic },
  { id: 3, label: "React", Component: ReactGraphic },
  { id: 4, label: "Redwood", Component: RedwoodGraphic },
  { id: 5, label: "Vue", Component: VueGrpahics },
];

export const HAT_STYLES = [
  { id: 0, label: "None", Front: Noop, Back: Noop },
  { id: 1, label: "Beanie", Front: Beanie.Front, Back: Beanie.Back },
  { id: 2, label: "Turban", Front: Turban.Front, Back: Turban.Back },
];

export const EYEBROW_SHAPES = [
  { id: 0, label: "Angry", Component: AngryEyebrows },
  { id: 1, label: "Concerned", Component: ConcernedEyebrows },
  { id: 2, label: "Left Lowered", Component: LeftLoweredEyebrows },
  { id: 3, label: "Serious", Component: SeriousEyebrows },
  { id: 4, label: "Normal", Component: NormalEyebrows },
];

export const EYE_SHAPES = [
  { id: 0, label: "Content", Component: ContentEyes },
  { id: 1, label: "Dizzy", Component: DizzyEyes },
  { id: 2, label: "Happy", Component: HappyEyes },
  { id: 3, label: "Heart", Component: HeartEyes },
  { id: 4, label: "Left Twitch", Component: LeftTwitchEyes },
  { id: 5, label: "Normal", Component: NormalEyes },
  { id: 6, label: "Simple", Component: SimpleEyes },
  { id: 7, label: "Squint", Component: SquintEyes },
  { id: 8, label: "Wink", Component: WinkEyes },
];

export const MOUTH_SHAPES = [
  { id: 0, label: "Grin", Component: Grin },
  { id: 1, label: "Lips", Component: Lips },
  { id: 2, label: "Open", Component: OpenMouth },
  { id: 3, label: "Smile", Component: SmileOpen },
  { id: 4, label: "Sad", Component: SadMouth },
  { id: 5, label: "Serious", Component: SeriousMouth },
  { id: 6, label: "Tongue", Component: Tongue },
];

export const ACCESSORIES = [
  { id: 0, label: "None", Component: Noop },
  { id: 1, label: "Round Glasses", Component: RoundGlasses },
  { id: 2, label: "Shades", Component: Shades },
  { id: 3, label: "Tiny Glasses", Component: TinyGlasses },
];

export const SKIN_COLORS = [
  { id: 0, color: colors.skin.light },
  { id: 1, color: colors.skin.yellow },
  { id: 2, color: colors.skin.brown },
  { id: 3, color: colors.skin.dark },
  { id: 4, color: colors.skin.red },
  { id: 5, color: colors.skin.black },
];

export const HAIR_COLORS = [
  { id: 0, color: colors.hair.blonde },
  { id: 1, color: colors.hair.orange },
  { id: 2, color: colors.hair.black },
  { id: 3, color: colors.hair.white },
  { id: 4, color: colors.hair.brown },
  { id: 5, color: colors.hair.blue },
  { id: 6, color: colors.hair.pink },
];

export const LIP_COLORS = [
  { id: 0, color: colors.lipColors.red },
  { id: 1, color: colors.lipColors.purple },
  { id: 2, color: colors.lipColors.pink },
  { id: 3, color: colors.lipColors.turqoise },
  { id: 4, color: colors.lipColors.green },
];

export const CLOTH_COLORS = [
  { id: 0, color: colors.clothing.white },
  { id: 1, color: colors.clothing.blue },
  { id: 2, color: colors.clothing.black },
  { id: 3, color: colors.clothing.green },
  { id: 4, color: colors.clothing.red },
];

export const BG_COLORS = [
  { id: 0, color: colors.bgColors.white },
  { id: 1, color: colors.bgColors.blue },
  { id: 2, color: colors.bgColors.black },
  { id: 3, color: colors.bgColors.green },
  { id: 4, color: colors.bgColors.red },
];

export interface GenesisHairParams {
  hairStyle: HairStyleId;
  hairColor: HairColorId;
}

export interface GenesisBodyParams {
  body: BodyTypeId;
  skinColor: SkinColorId;
  braStraps: boolean;
}

export interface GenesisClothingParams {
  clothingStyle: ClothingStyleId;
  clothingColor: ClothColorId;
  graphic: ClothingGraphicId;
}

export interface GenesisFacialFeaturesParams {
  eyebrows: EyebrowShapeId;
  eyes: EyeShapeId;
  facialHair: FacialHairId;
  mouth: MouthShapeId;
  lipColor: LipColorId;
}

export interface GenesisAccessoriesParams {
  accessory: AccessoryId;
  hat: HatStyleId;
  hatColor: ClothColorId;
}

export interface GenesisMiscParams {
  mask: boolean;
  faceMask: boolean;
  faceMaskColor: ClothColorId;
  shape: boolean;
  shapeColor: ClothColorId;
  lashes: boolean;
}
