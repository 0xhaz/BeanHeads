import { colors } from "@/utils/theme";

export interface AccessoryProps {
  color?: keyof typeof colors.outline;
  scale?: number;
}
