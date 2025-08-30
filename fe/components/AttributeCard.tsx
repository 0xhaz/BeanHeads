import { colors } from "@/utils/theme";
import {
  HAIR_STYLES,
  BODY_TYPES,
  FACIAL_HAIR_STYLES,
  CLOTHING_STYLES,
  HAT_STYLES,
  EYEBROW_SHAPES,
  EYE_SHAPES,
  MOUTH_SHAPES,
  ACCESSORIES,
  CLOTHING_GRAPHICS,
} from "./Avatar";

const TRAIT_MAP = {
  hair: {
    style: HAIR_STYLES,
    color: Object.keys(colors.hair),
  },
  body: {
    style: BODY_TYPES,
    color: Object.keys(colors.skin),
  },
  clothing: {
    style: CLOTHING_STYLES,
    color: Object.keys(colors.clothing),
    graphic: CLOTHING_GRAPHICS,
  },
  facialFeatures: {
    eyebrows: EYEBROW_SHAPES,
    eyes: EYE_SHAPES,
    facialHair: FACIAL_HAIR_STYLES,
    mouth: MOUTH_SHAPES,
    lipColor: Object.keys(colors.lipColors),
  },
  accessories: {
    accessory: ACCESSORIES,
    hatStyles: HAT_STYLES,
    hatColors: Object.keys(colors.clothing),
  },
  misc: {
    faceMask: [true, false],
    faceMaskColor: Object.keys(colors.clothing),
    mask: [true, false],
    lashes: [true, false],
    shape: [true, false],
    shapeColor: Object.keys(colors.bgColors),
  },
};

interface AttributeCardProps {
  title?: string;
  onClose?: () => void;
  children?: React.ReactNode;
  className?: string;
  selectedAttributes?: any;
  setSelectedAttributes?: React.Dispatch<React.SetStateAction<any>>;
  category?: string;
}

const AttributeCard = ({
  title,
  onClose,
  className,
  selectedAttributes,
  setSelectedAttributes,
  category,
}: AttributeCardProps) => {
  const traits = category
    ? TRAIT_MAP[category.toLowerCase() as keyof typeof TRAIT_MAP]
    : null;

  const handleChange = (traitKey: string, value: string) => {
    if (!setSelectedAttributes || !category) return;

    const options = traits?.[
      traitKey as keyof typeof traits
    ] as unknown as any[];

    let newValue: any = value;

    if (
      Array.isArray(options) &&
      typeof options[0] === "object" &&
      "id" in options[0]
    ) {
      const match =
        Array.isArray(options) && options.length > 0
          ? (options as any[]).find((opt: any) => opt.label === value)
          : undefined;
      if (match) newValue = match;
    } else if (value === "true" || value === "false") {
      newValue = value === "true";
    }

    setSelectedAttributes((prev: any) => ({
      ...prev,
      [category]: {
        ...prev[category],
        [traitKey]: newValue,
      },
    }));
  };

  return (
    <div
      className={`bg-white/10 backdrop-blur-lg border border-white/30 rounded-xl p-6 text-white w-[300px] shadow-lg ${className}`}
      onClick={e => e.stopPropagation()}
    >
      {title && (
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold">{title}</h3>
          {onClose && (
            <button
              onClick={onClose}
              className="text-white/60 hover:text-white cursor-pointer"
            >
              x
            </button>
          )}
        </div>
      )}

      {traits ? (
        <div className="flex flex-col gap-4">
          {Object.entries(traits).map(([traitKey, options]) => {
            const selected =
              (category && selectedAttributes?.[category]?.[traitKey]) ??
              selectedAttributes?.[traitKey];
            const selectedValue =
              typeof selected === "object" && selected?.id
                ? selected.id
                : selected?.toString() ?? "";

            return (
              <div key={traitKey}>
                <label className="block text-sm font-medium capitalize mb-1">
                  {traitKey}
                </label>
                <select
                  className="w-full bg-white/20 text-white p-2 rounded"
                  value={selectedValue}
                  onChange={e => handleChange(traitKey, e.target.value)}
                >
                  {(options ?? []).map((option: any) => {
                    const val =
                      typeof option === "object" && "id" in option
                        ? option.id
                        : option.toString();
                    const label =
                      typeof option === "object" && "label" in option
                        ? option.label
                        : option.toString();
                    return (
                      <option key={val} value={val}>
                        {label}
                      </option>
                    );
                  })}
                </select>
              </div>
            );
          })}
        </div>
      ) : (
        <p className="text-white/60">No category selected</p>
      )}
    </div>
  );
};

export default AttributeCard;
