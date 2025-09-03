import {
  HAIR_STYLES,
  BODY_TYPES,
  CLOTHING_STYLES,
  FACIAL_HAIR_STYLES,
  MOUTH_SHAPES,
  EYE_SHAPES,
  EYEBROW_SHAPES,
  ACCESSORIES,
  HAT_STYLES,
  CLOTHING_GRAPHICS,
} from "@/types/GenesisComponentParams";

export function getHairComponent(id: number) {
  return HAIR_STYLES.find(h => h.id === id) ?? HAIR_STYLES[0];
}

export function getBodyComponent(id: number) {
  return BODY_TYPES.find(b => b.id === id) ?? BODY_TYPES[0];
}

export function getClothingComponent(id: number) {
  return CLOTHING_STYLES.find(c => c.id === id) ?? CLOTHING_STYLES[0];
}

export function getFacialHairComponent(id: number) {
  return FACIAL_HAIR_STYLES.find(f => f.id === id) ?? FACIAL_HAIR_STYLES[0];
}

export function getMouthComponent(id: number) {
  return MOUTH_SHAPES.find(m => m.id === id) ?? MOUTH_SHAPES[0];
}

export function getEyesComponent(id: number) {
  return EYE_SHAPES.find(e => e.id === id) ?? EYE_SHAPES[0];
}

export function getEyebrowComponent(id: number) {
  return EYEBROW_SHAPES.find(e => e.id === id) ?? EYEBROW_SHAPES[0];
}

export function getAccessoryComponent(id: number) {
  return ACCESSORIES.find(a => a.id === id) ?? ACCESSORIES[0];
}

export function getHatComponent(id: number) {
  return HAT_STYLES.find(h => h.id === id) ?? HAT_STYLES[0];
}

export function getGraphicComponent(id: number) {
  return CLOTHING_GRAPHICS.find(g => g.id === id) ?? CLOTHING_GRAPHICS[0];
}
