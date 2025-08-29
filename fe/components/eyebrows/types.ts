import { colors } from "@/utils/theme";

export interface EyebrowProps {
  color?: keyof typeof colors.outline;
  eyebrowType?: React.ComponentType;
}
