import { colors } from "./theme";

export function getClothingColorByIndex(index: number) {
  const keys = Object.keys(colors.clothing);
  const key = keys[index % keys.length] as keyof typeof colors.clothing;
  return colors.clothing[key];
}

export function getHairColorByIndex(index: number) {
  const keys = Object.keys(colors.hair);
  const key = keys[index % keys.length] as keyof typeof colors.hair;
  return colors.hair[key];
}

export function getSkinColorByIndex(index: number) {
  const keys = Object.keys(colors.skin);
  const key = keys[index % keys.length] as keyof typeof colors.skin;
  return colors.skin[key];
}

export function getLipColorByIndex(index: number) {
  const keys = Object.keys(colors.lipColors);
  const key = keys[index % keys.length] as keyof typeof colors.lipColors;
  return colors.lipColors[key];
}
