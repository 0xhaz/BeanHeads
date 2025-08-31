import { colors } from "@/utils/theme";
import { ThemeContext } from "@/utils/themeContext";
import { Noop } from "@/utils/Noop";
import { Base } from "./Base";
import { NormalEyebrows } from "./eyebrows/Normal";
import { LeftLoweredEyebrows } from "./eyebrows/LeftLoweredEyebrows";
import { Grin } from "./mouths/Grin";
import { SadMouth } from "./mouths/Sad";
import { Lips } from "./mouths/Lips";
import { SmileOpen } from "./mouths/SmileOpen";
import * as LongHair from "./hair/LongHair";
import * as BunHair from "./hair/BunHair";
import * as ShortHair from "./hair/ShortHair";
import * as PixieCut from "./hair/PixieCut";
import * as BaldingHair from "./hair/BaldingHair";
import * as Afro from "./hair/Afro";
import * as BobCut from "./hair/BobCut";
import * as Beanie from "./hats/Beanie";
import * as Turban from "./hats/Turban";
import * as Chest from "./bodies/Chest";
import * as Breasts from "./bodies/Breasts";
import { MediumBeard } from "./facialHair/MediumBeard";
import { HappyEyes } from "./eyes/HappyEyes";
import { NormalEyes } from "./eyes/NormalEyes";
import { LeftTwitchEyes } from "./eyes/LeftTwitchEyes";
import { Shirt } from "./clothing/Shirt";
import { ContentEyes } from "./eyes/ContentEyes";
import { SeriousEyebrows } from "./eyebrows/SeriousEyebrows";
import { RoundGlasses } from "./accessories/RoundGlasses";
import { AngryEyebrows } from "./eyebrows/AngryEyebrows";
import { StubbleBeard } from "./facialHair/Stubble";
import { RedwoodGraphic } from "./clothingGraphic/Redwood";
import { GatsbyGraphic } from "./clothingGraphic/Gatsby";
import * as Dress from "./clothing/Dress";
import { SquintEyes } from "./eyes/SquintEyes";
import { ConcernedEyebrows } from "./eyebrows/ConcernedEyebrows";
import { Shades } from "./accessories/Shades";
import { TankTop } from "./clothing/TankTop";
import { SimpleEyes } from "./eyes/SimpleEyes";
import { Vue as VueGrpahics } from "./clothingGraphic/Vue";
import { DizzyEyes } from "./eyes/DizzyEyes";
import { WinkEyes } from "./eyes/Wink";
import { HeartEyes } from "./eyes/HeartEyes";
import { OpenMouth } from "./mouths/OpenMouth";
import { SeriousMouth } from "./mouths/SeriousMouth";
import { ReactGraphic } from "./clothingGraphic/React";
import { TinyGlasses } from "./accessories/TinyGlasses";
import { VNeck } from "./clothing/VNeck";
import { GraphQLGraphic } from "./clothingGraphic/GraphQL";
import { Tongue } from "./mouths/Tongue";
import { DressShirt } from "./clothing/DressShirt";

import {
  HairStyleId,
  BodyTypeId,
  FacialHairId,
  ClothingStyleId,
  HatStyleId,
  EyebrowShapeId,
  MouthShapeId,
  AccessoryId,
  ClothingGraphicId,
  EyeShapeId,
} from "./Avatar";
import React from "react";

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
  { id: 0, label: "Chest", Component: Chest },
  { id: 1, label: "Breasts", Component: Breasts },
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

export interface AvatarProps {
  hairStyle: HairStyleId;
  hairColor: keyof typeof colors.hair;
  body: BodyTypeId;
  facialHair: FacialHairId;
  clothingStyle: ClothingStyleId;
  clothingColor: keyof typeof colors.clothing;
  hat: HatStyleId;
  eyebrows: EyebrowShapeId;
  eyes: EyeShapeId;
  mouthShape: MouthShapeId;
  mouthColor?: keyof typeof colors.lipColors;
  accessory: AccessoryId;
  skinColor: keyof typeof colors.skin;
  circleColor?: keyof typeof colors.bgColors;
  hatColor: keyof typeof colors.clothing;
  graphic?: ClothingGraphicId;
  faceMaskColor?: keyof typeof colors.clothing;

  mask?: boolean;
  faceMask?: boolean;
  lashes?: boolean;
  shape?: boolean;
}

export function selectRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

export function generateRandomAvatarAttributes(): any {
  const flatAttrs: AvatarProps = {
    hairStyle: selectRandom(HAIR_STYLES).id as HairStyleId,
    hairColor: selectRandom(
      Object.keys(colors.hair) as (keyof typeof colors.hair)[]
    ),
    body: selectRandom(BODY_TYPES).id as BodyTypeId,
    facialHair: selectRandom(FACIAL_HAIR_STYLES).id as FacialHairId,
    clothingStyle: selectRandom(CLOTHING_STYLES).id as ClothingStyleId,
    clothingColor: selectRandom(
      Object.keys(colors.clothing) as (keyof typeof colors.clothing)[]
    ),
    hat: selectRandom(HAT_STYLES).id as HatStyleId,
    eyebrows: selectRandom(EYEBROW_SHAPES).id as EyebrowShapeId,
    eyes: selectRandom(EYE_SHAPES).id as EyeShapeId,
    mouthShape: selectRandom(MOUTH_SHAPES).id as MouthShapeId,
    mouthColor: selectRandom(
      Object.keys(colors.lipColors) as (keyof typeof colors.lipColors)[]
    ),
    accessory: selectRandom(ACCESSORIES).id as AccessoryId,
    skinColor: selectRandom(
      Object.keys(colors.skin) as (keyof typeof colors.skin)[]
    ),
    hatColor: selectRandom(
      Object.keys(colors.clothing) as (keyof typeof colors.clothing)[]
    ),
    graphic: selectRandom(CLOTHING_GRAPHICS).id as ClothingGraphicId,
    faceMaskColor: selectRandom(
      Object.keys(colors.clothing) as (keyof typeof colors.clothing)[]
    ),
    circleColor: selectRandom(
      Object.keys(colors.bgColors) as (keyof typeof colors.bgColors)[]
    ),
    mask: selectRandom([true, false]),
    faceMask: selectRandom([true, false]),
    lashes: selectRandom([true, false]),
    shape: selectRandom([true, false]),
  };

  return {
    hair: {
      style: flatAttrs.hairStyle,
      color: flatAttrs.hairColor,
    },
    body: {
      type: flatAttrs.body,
      skinColor: flatAttrs.skinColor,
    },
    clothing: {
      style: flatAttrs.clothingStyle,
      color: flatAttrs.clothingColor,
      graphic: flatAttrs.graphic,
    },
    facialFeatures: {
      eyebrows: flatAttrs.eyebrows,
      eyes: flatAttrs.eyes,
      facialHair: flatAttrs.facialHair,
      mouth: flatAttrs.mouthShape,
      lipColor: flatAttrs.mouthColor,
    },
    accessories: {
      accessory: flatAttrs.accessory,
      hat: flatAttrs.hat,
      hatColor: flatAttrs.hatColor,
    },
    misc: {
      faceMask: flatAttrs.faceMask,
      faceMaskColor: flatAttrs.faceMaskColor,
      mask: flatAttrs.mask,
      lashes: flatAttrs.lashes,
      shape: flatAttrs.shape,
      shapeColor: flatAttrs.circleColor,
    },
  };
}

export const Avatar = React.forwardRef<SVGSVGElement, AvatarProps>(
  (
    {
      hairStyle,
      hairColor,
      body,
      facialHair,
      clothingStyle,
      clothingColor,
      hat,
      eyebrows,
      eyes,
      mouthShape,
      mouthColor,
      accessory,
      skinColor,
      circleColor,
      hatColor,
      graphic,
      faceMaskColor,
      mask,
      faceMask,
      lashes,
      shape,

      ...rest
    },
    ref
  ) => {
    const skin = colors.skin[skinColor];
    const Eyes = EYE_SHAPES[eyes as number]?.Component;
    const Eyebrows = EYEBROW_SHAPES[eyebrows as number]?.Component;
    const Mouth = MOUTH_SHAPES[mouthShape as number]?.Component;
    const Hair = HAIR_STYLES[hairStyle as number];
    const FacialHair = FACIAL_HAIR_STYLES[facialHair as number]?.Component;
    const Clothing = CLOTHING_STYLES[clothingStyle as number];
    const Accessory = ACCESSORIES[accessory as number]?.Component;
    const Graphic = CLOTHING_GRAPHICS[graphic as number];
    const Hat = HAT_STYLES[hat as number];
    const Body = BODY_TYPES[body as number]?.Component;
    return (
      <ThemeContext.Provider value={{ colors, skin }}>
        <Base
          ref={ref}
          eyes={Eyes}
          eyebrows={Eyebrows}
          mouth={Mouth}
          hair={Hair}
          facialHair={FacialHair}
          clothing={Clothing}
          accessory={Accessory}
          graphic={Graphic?.Component}
          hat={Hat}
          body={Body}
          hatColor={hatColor}
          hairColor={hairColor}
          clothingColor={clothingColor}
          lipColor={mouthColor}
          mask={mask ?? false}
          faceMask={faceMask}
          faceMaskColor={faceMaskColor}
          lashes={lashes}
          shape={shape}
          circleColor={circleColor}
          {...rest}
        />
      </ThemeContext.Provider>
    );
  }
);
