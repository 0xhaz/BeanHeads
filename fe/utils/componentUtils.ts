import { Noop } from "./Noop";

// Single component (like eyes, mouth, etc.)
export function getComponentByIndex<
  T extends { id: number; Component: React.ComponentType<any> }
>(arr: T[], index: number): React.ComponentType<any>;

// Front/Back component (like hair, body, clothing, hats)
export function getComponentByIndex<
  T extends {
    id: number;
    Front: React.ComponentType<any>;
    Back: React.ComponentType<any>;
  }
>(
  arr: T[],
  index: number
): { Front: React.ComponentType<any>; Back: React.ComponentType<any> };

// Implementation
export function getComponentByIndex(arr: any[], index: number): any {
  const item = arr.find(item => item.id === index);
  if (!item) return { Front: Noop, Back: Noop };

  // Return correct shape based on keys
  if ("Component" in item) {
    return item.Component;
  }

  if ("Front" in item && "Back" in item) {
    return {
      Front: item.Front ?? Noop,
      Back: item.Back ?? Noop,
    };
  }

  return Noop; // Fallback
}
