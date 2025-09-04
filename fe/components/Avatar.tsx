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
import { Vue as VueGraphics } from "./clothingGraphic/Vue";
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
  { id: 5, label: "Vue", Component: VueGraphics },
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

// Define color arrays with indices
export const HAIR_COLORS = [
  { id: 0, label: "Blonde", base: "#FEDC58", shadow: "#EDBF2E" },
  { id: 1, label: "Orange", base: "#D96E27", shadow: "#C65C22" },
  { id: 2, label: "Black", base: "#592d3d", shadow: "#592d3d" },
  { id: 3, label: "White", base: "#ffffff", shadow: "#E2E2E2" },
  { id: 4, label: "Brown", base: "#A56941", shadow: "#8D5638" },
  { id: 5, label: "Blue", base: "#85c5e5", shadow: "#67B7D6" },
  { id: 6, label: "Pink", base: "#D69AC7", shadow: "#C683B4" },
];

export const CLOTHING_COLORS = [
  { id: 0, label: "White", base: "#FFFFFF", shadow: "#E2E2E2" },
  { id: 1, label: "Blue", base: "#85c5e5", shadow: "#67B7D6" },
  { id: 2, label: "Black", base: "#633749", shadow: "#5E3244" },
  { id: 3, label: "Green", base: "#89D86F", shadow: "#7DC462" },
  { id: 4, label: "Red", base: "#D67070", shadow: "#C46565" },
];

export const LIP_COLORS = [
  { id: 0, label: "Red", base: "#DD3E3E", shadow: "#C43333" },
  { id: 1, label: "Purple", base: "#B256A1", shadow: "#9C4490" },
  { id: 2, label: "Pink", base: "#D69AC7", shadow: "#C683B4" },
  { id: 3, label: "Turquoise", base: "#5CCBF1", shadow: "#49B5CD" },
  { id: 4, label: "Green", base: "#4AB749", shadow: "#3CA047" },
];

export const BG_COLORS = [
  { id: 0, label: "White", value: "#FFFFFF" },
  { id: 1, label: "Blue", value: "#85c5e5" },
  { id: 2, label: "Black", value: "#633749" },
  { id: 3, label: "Green", value: "#89D86F" },
  { id: 4, label: "Red", value: "#D67070" }, // Fixed typo "0xD67070"
];

export const SKIN_COLORS = [
  { id: 0, label: "Light", base: "#fdd2b2", shadow: "#f3ab98" },
  { id: 1, label: "Yellow", base: "#FBE8B3", shadow: "#EDD494" },
  { id: 2, label: "Brown", base: "#D8985D", shadow: "#C6854E" },
  { id: 3, label: "Dark", base: "#A56941", shadow: "#8D5638" },
  { id: 4, label: "Red", base: "#CC734C", shadow: "#B56241" },
  { id: 5, label: "Black", base: "#754437", shadow: "#6B3D34" },
];

export interface AvatarProps {
  hairStyle: number;
  hairColor: number;
  body: number;
  facialHair: number;
  clothingStyle: number;
  clothingColor: number;
  hat: number;
  eyebrows: number;
  eyes: number;
  mouthShape: number;
  mouthColor: number;
  accessory: number;
  skinColor: number;
  circleColor: number;
  hatColor: number;
  graphic: number;
  faceMaskColor: number;
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
    hairStyle: selectRandom(HAIR_STYLES).id,
    hairColor: selectRandom(HAIR_COLORS).id,
    body: selectRandom(BODY_TYPES).id,
    facialHair: selectRandom(FACIAL_HAIR_STYLES).id,
    clothingStyle: selectRandom(CLOTHING_STYLES).id,
    clothingColor: selectRandom(CLOTHING_COLORS).id,
    hat: selectRandom(HAT_STYLES).id,
    eyebrows: selectRandom(EYEBROW_SHAPES).id,
    eyes: selectRandom(EYE_SHAPES).id,
    mouthShape: selectRandom(MOUTH_SHAPES).id,
    mouthColor: selectRandom(LIP_COLORS).id,
    accessory: selectRandom(ACCESSORIES).id,
    skinColor: selectRandom(SKIN_COLORS).id,
    hatColor: selectRandom(CLOTHING_COLORS).id,
    graphic: selectRandom(CLOTHING_GRAPHICS).id,
    faceMaskColor: selectRandom(CLOTHING_COLORS).id,
    circleColor: selectRandom(BG_COLORS).id,
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
    const skin = SKIN_COLORS[skinColor]?.base
      ? {
          base: SKIN_COLORS[skinColor].base,
          shadow: SKIN_COLORS[skinColor].shadow,
        }
      : SKIN_COLORS[0];
    const Eyes = EYE_SHAPES[eyes]?.Component;
    const Eyebrows = EYEBROW_SHAPES[eyebrows]?.Component;
    const Mouth = MOUTH_SHAPES[mouthShape]?.Component;
    const Hair = HAIR_STYLES[hairStyle];
    const FacialHair = FACIAL_HAIR_STYLES[facialHair]?.Component;
    const Clothing = CLOTHING_STYLES[clothingStyle];
    const Accessory = ACCESSORIES[accessory]?.Component;
    const Graphic = CLOTHING_GRAPHICS[graphic]?.Component;
    const Hat = HAT_STYLES[hat];
    const Body = BODY_TYPES[body]?.Component;

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
          graphic={Graphic}
          hat={Hat}
          body={Body}
          hatColor={
            CLOTHING_COLORS[
              hatColor
            ]?.label.toLowerCase() as keyof typeof colors.clothing
          }
          hairColor={
            HAIR_COLORS[
              hairColor
            ]?.label.toLowerCase() as keyof typeof colors.hair
          }
          clothingColor={
            CLOTHING_COLORS[
              clothingColor
            ]?.label.toLowerCase() as keyof typeof colors.clothing
          }
          lipColor={
            LIP_COLORS[
              mouthColor
            ]?.label.toLowerCase() as keyof typeof colors.lipColors
          }
          mask={mask ?? false}
          faceMask={faceMask}
          faceMaskColor={
            CLOTHING_COLORS[
              faceMaskColor
            ]?.label.toLowerCase() as keyof typeof colors.clothing
          }
          lashes={lashes}
          shape={shape}
          circleColor={
            BG_COLORS[
              circleColor
            ]?.label.toLowerCase() as keyof typeof colors.bgColors
          }
          {...rest}
        />
      </ThemeContext.Provider>
    );
  }
);
