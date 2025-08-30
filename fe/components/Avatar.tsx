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

import type { HairProps } from "./hair/types";
import React from "react";

export const HAIR_STYLES = [
  { id: 0, Front: Noop, Back: Noop },
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

export interface HairParams {
  style: string;
  color: string;
}

export interface BodyParams {
  style: string;
  color: string;
}

export interface ClothingParams {
  style: string;
  color: string;
  graphic: string;
}

export interface FacialFeaturesParams {
  eyebrows: string;
  eyes: string;
  facialHair: string;
  mouth: string;
  lipColor: string;
}

export interface AccessoryParams {
  accessory: string;
  hatStyles: string;
  hatColors: string;
}

export interface OtherParams {
  faceMask: boolean;
  faceMaskColor: string;
  mask: boolean;
  lashes: boolean;
  shape: boolean;
  shapeColor: string;
}

export interface AvatarProps extends React.SVGProps<SVGSVGElement> {
  hair: HairParams;
  body: BodyParams;
  clothing: ClothingParams;
  facialFeatures: FacialFeaturesParams;
  accessories: AccessoryParams;
  misc: OtherParams;
}

export function selectRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

export function generateRandomAvatarAttributes(): AvatarProps {
  return {
    hair: {
      style: selectRandom(HAIR_STYLES.filter(h => h.label)).label as string,
      color: selectRandom(
        Object.keys(colors.hair) as (keyof typeof colors.hair)[]
      ),
    },
    body: {
      style: selectRandom(BODY_TYPES).label as string,
      color: selectRandom(
        Object.keys(colors.skin) as (keyof typeof colors.skin)[]
      ),
    },
    facialHair: selectRandom(FACIAL_HAIR_STYLES),
    clothing: {
      style: selectRandom(CLOTHING_STYLES).label as string,
      color: selectRandom(
        Object.keys(colors.clothing) as (keyof typeof colors.clothing)[]
      ),
      graphic: selectRandom(CLOTHING_GRAPHICS).label as string,
    },
    hat: selectRandom(HAT_STYLES),
    eyebrows: selectRandom(EYEBROW_SHAPES),
    eyes: selectRandom(EYE_SHAPES),
    mouth: {
      shape: selectRandom(MOUTH_SHAPES),
      color: selectRandom(
        Object.keys(colors.lipColors) as (keyof typeof colors.lipColors)[]
      ),
    },
    accessory: selectRandom(ACCESSORIES),
    skinColor: selectRandom(
      Object.keys(colors.skin) as (keyof typeof colors.skin)[]
    ),
    hatColor: selectRandom(
      Object.keys(colors.clothing) as (keyof typeof colors.clothing)[]
    ),
    graphic: selectRandom(CLOTHING_GRAPHICS),
    faceMaskColor: selectRandom(
      Object.keys(colors.clothing) as (keyof typeof colors.clothing)[]
    ),
    mask: selectRandom([true, false]),
    faceMask: selectRandom([true, false]),
    lashes: selectRandom([true, false]),
  };
}

export const Avatar = React.forwardRef<SVGSVGElement, AvatarProps>(
  (
    { hair, body, clothing, facialFeatures, accessories, misc, ...rest },
    ref
  ) => {
    return (
      <svg ref={ref} {...rest}>
        <HairDetail style={hair.style} color={hair.color} />
        <BodyDetail style={body.style} color={body.color} />
      </svg>
    );
  }
);
