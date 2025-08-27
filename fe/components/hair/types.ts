import { colors } from "@/utils/theme";

export interface HairProps {
  hairColor: keyof typeof colors.hair;
  hasHat?: boolean;
}
