import { colors } from "@/utils/theme";

export interface BodyProps {
  clothingColor: keyof typeof colors.clothing;
  braStraps: boolean;
}
