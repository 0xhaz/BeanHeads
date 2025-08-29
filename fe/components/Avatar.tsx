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
  { label: "None", Front: Noop, Back: Noop },
  { label: "Afro", Front: Afro.Front, Back: Afro.Back },
  { label: "Balding", Front: BaldingHair.Front, Back: BaldingHair.Back },
  { label: "Bob Cut", Front: BobCut.Front, Back: BobCut.Back },
  { label: "Bun", Front: BunHair.Front, Back: BunHair.Back },
  { label: "Long", Front: LongHair.Front, Back: LongHair.Back },
  { label: "Pixie Cut", Front: PixieCut.Front, Back: PixieCut.Back },
  { label: "Short", Front: ShortHair.Front, Back: ShortHair.Back },
];

export const BODY_TYPES = [
  { label: "Chest", Component: Chest },
  { label: "Breasts", Component: Breasts },
];

export const FACIAL_HAIR_STYLES = [
  { label: "None", Component: Noop },
  { label: "Medium Beard", Component: MediumBeard },
  { label: "Stubble", Component: StubbleBeard },
];

export const CLOTHING_STYLES = [
  { label: "Naked", Front: Noop, Back: Noop },
  { label: "Dress", Front: Dress.Front, Back: Dress.Back },
  { label: "Shirt", Front: Noop, Back: DressShirt },
  { label: "T-Shirt", Front: Noop, Back: Shirt },
  { label: "Tank Top", Front: Noop, Back: TankTop },
  { label: "V-Neck", Front: Noop, Back: VNeck },
];

export const CLOTHING_GRAPHICS = [
  { label: "None", Component: Noop },
  { label: "Gatsby", Component: GatsbyGraphic },
  { label: "GraphQL", Component: GraphQLGraphic },
  { label: "React", Component: ReactGraphic },
  { label: "Redwood", Component: RedwoodGraphic },
  { label: "Vue", Component: VueGrpahics },
];

export const HAT_STYLES = [
  { label: "None", Front: Noop, Back: Noop },
  { label: "Beanie", Front: Beanie.Front, Back: Beanie.Back },
  { label: "Turban", Front: Turban.Front, Back: Turban.Back },
];

export const EYEBROW_SHAPES = [
  { label: "Angry", Component: AngryEyebrows },
  { label: "Concerned", Component: ConcernedEyebrows },
  { label: "Left Lowered", Component: LeftLoweredEyebrows },
  { label: "Serious", Component: SeriousEyebrows },
  { label: "Normal", Component: NormalEyebrows },
];

export const EYE_SHAPES = [
  { label: "Content", Component: ContentEyes },
  { label: "Dizzy", Component: DizzyEyes },
  { label: "Happy", Component: HappyEyes },
  { label: "Heart", Component: HeartEyes },
  { label: "Left Twitch", Component: LeftTwitchEyes },
  { label: "Normal", Component: NormalEyes },
  { label: "Simple", Component: SimpleEyes },
  { label: "Squint", Component: SquintEyes },
  { label: "Wink", Component: WinkEyes },
];

export const MOUTH_SHAPES = [
  { label: "Grin", Component: Grin },
  { label: "Lips", Component: Lips },
  { label: "Open", Component: OpenMouth },
  { label: "Smile", Component: SmileOpen },
  { label: "Sad", Component: SadMouth },
  { label: "Serious", Component: SeriousMouth },
  { label: "Tongue", Component: Tongue },
];

export const ACCESSORIES = [
  { label: "None", Component: Noop },
  { label: "Round Glasses", Component: RoundGlasses },
  { label: "Shades", Component: Shades },
  { label: "Tiny Glasses", Component: TinyGlasses },
];

export interface AvatarProps {
  hair: {
    style: (typeof HAIR_STYLES)[number];
    color: keyof typeof colors.hair;
  };
  body: (typeof BODY_TYPES)[number];
  facialHair: (typeof FACIAL_HAIR_STYLES)[number];
  clothing: {
    style: (typeof CLOTHING_STYLES)[number];
    color: keyof typeof colors.clothing;
  };
  hat: (typeof HAT_STYLES)[number];
  eyebrows: (typeof EYEBROW_SHAPES)[number];
  eyes: (typeof EYE_SHAPES)[number];
  mouth?: {
    shape: (typeof MOUTH_SHAPES)[number];
    color?: keyof typeof colors.lipColors;
  };
  accessory: (typeof ACCESSORIES)[number];
  skinColor: keyof typeof colors.skin;
  circleColor?: keyof typeof colors.bgColors;
  hatColor: keyof typeof colors.clothing;
  graphic?: (typeof CLOTHING_GRAPHICS)[number];
  faceMaskColor?: keyof typeof colors.clothing;

  mask?: boolean;
  faceMask?: boolean;
  lashes?: boolean;
}

function selectRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

export const Avatar = React.forwardRef<SVGSVGElement, AvatarProps>(
  (
    {
      hair = {
        style: selectRandom(HAIR_STYLES),
        color: selectRandom(
          Object.keys(colors.hair) as (keyof typeof colors.hair)[]
        ),
      },
      body = selectRandom(BODY_TYPES),
      facialHair = selectRandom(FACIAL_HAIR_STYLES),
      clothing = {
        style: selectRandom(CLOTHING_STYLES),
        color: selectRandom(
          Object.keys(colors.clothing) as (keyof typeof colors.clothing)[]
        ),
      },
      hat = selectRandom(HAT_STYLES),
      eyebrows = selectRandom(EYEBROW_SHAPES),
      eyes = selectRandom(EYE_SHAPES),
      mouth = {
        shape: selectRandom(MOUTH_SHAPES),
        color: selectRandom(
          Object.keys(colors.lipColors) as (keyof typeof colors.lipColors)[]
        ),
      },
      accessory = selectRandom(ACCESSORIES),
      skinColor = selectRandom(
        Object.keys(colors.skin) as (keyof typeof colors.skin)[]
      ),
      circleColor = selectRandom(
        Object.keys(colors.bgColors) as (keyof typeof colors.bgColors)[]
      ),
      hatColor = selectRandom(
        Object.keys(colors.clothing) as (keyof typeof colors.clothing)[]
      ),
      graphic = selectRandom(CLOTHING_GRAPHICS),
      faceMaskColor = selectRandom(
        Object.keys(colors.clothing) as (keyof typeof colors.clothing)[]
      ),
      mask = true,
      faceMask = false,
      lashes = Math.random() > 0.5,

      ...rest
    },
    ref
  ) => {
    const skin = colors.skin[skinColor];
    const Eyes = eyes.Component;
    const Eyebrows = eyebrows.Component;
    const Mouth = mouth;
    const Hair = hair;
    const FacialHair = facialHair.Component;
    const Clothing = clothing;
    const Accessory = accessory.Component;
    const Graphic = graphic;
    const Hat = hat;
    const Body = body.Component;
    return (
      <ThemeContext.Provider value={{ colors, skin }}>
        <Base
          ref={ref}
          eyes={Eyes}
          eyebrows={Eyebrows}
          mouth={Mouth.shape.Component}
          hair={Hair.style}
          facialHair={FacialHair}
          clothing={Clothing.style}
          accessory={Accessory}
          graphic={Graphic.Component}
          hat={Hat}
          body={Body}
          hatColor={hatColor}
          hairColor={hair.color}
          clothingColor={clothing.color}
          lipColor={Mouth.color}
          mask={mask}
          faceMask={faceMask}
          faceMaskColor={faceMaskColor}
          lashes={lashes}
          {...rest}
        />
      </ThemeContext.Provider>
    );
  }
);
