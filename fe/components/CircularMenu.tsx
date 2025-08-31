"use client";
import { useState, useEffect } from "react";
import CircularItems from "@/components/CircularItems";
import CloseCircularMenu from "@/components/CloseCircularMenu";
import CircularIcon from "@/components/CircularIcon";
import { AttributeCard, CATEGORY_MAP } from "./AttributeCard";
import {
  Avatar,
  generateRandomAvatarAttributes as selectRandom,
} from "./Avatar";
import type { AvatarProps } from "./Avatar";
import { colors } from "@/utils/theme";

interface CircularMenuProps {
  pages: [string, string][];
}

const CircularMenu = ({ pages }: CircularMenuProps) => {
  const [isOpen, setIsOpen] = useState(false);
  const [activeCategory, setActiveCategory] = useState<string | null>(null);
  const [selectedAttributes, setSelectedAttributes] = useState<any | null>(
    null
  );

  const handleSetIsOpen = () => {
    setIsOpen(prevBool => !prevBool);
  };

  useEffect(() => {
    const randomAttributes = selectRandom();
    setSelectedAttributes(randomAttributes);
  }, []);

  const avatarProps = selectedAttributes
    ? {
        hairStyle: selectedAttributes?.hair?.style ?? 0,
        hairColor: selectedAttributes?.hair?.color ?? "brown",
        body: selectedAttributes?.body?.style ?? 0,
        skinColor: selectedAttributes?.body?.color ?? "light",
        facialHair: selectedAttributes?.facialFeatures?.facialHair ?? 0,
        clothingStyle: selectedAttributes?.clothing?.style ?? 0,
        clothingColor: selectedAttributes?.clothing?.color ?? "blue",
        graphic: selectedAttributes?.clothing?.graphic ?? 0,
        eyebrows: selectedAttributes?.facialFeatures?.eyebrows ?? 0,
        eyes: selectedAttributes?.facialFeatures?.eyes ?? 0,
        mouthShape: selectedAttributes?.facialFeatures?.mouth ?? 0,
        mouthColor: selectedAttributes?.facialFeatures?.lipColor ?? "red",
        accessory: selectedAttributes?.accessories?.accessory ?? 0,
        hat: selectedAttributes?.accessories?.hat ?? 0,
        hatColor: selectedAttributes?.accessories?.hatColor ?? "blue",
        faceMask: selectedAttributes?.misc?.faceMask ?? false,
        faceMaskColor: selectedAttributes?.misc?.faceMaskColor ?? "blue",
        mask: selectedAttributes?.misc?.mask ?? false,
        lashes: selectedAttributes?.misc?.lashes ?? false,
        shape: selectedAttributes?.misc?.shape ?? false,
        circleColor:
          selectedAttributes?.misc?.shapeColor ?? colors.bgColors.blue,
      }
    : null;
  return (
    <div className="h-[200px] w-[200px] relative ">
      <div className="group absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 h-[250px] w-[250px] rounded-full border-4 border-white shadow-lg z-50">
        {avatarProps ? (
          <div className="absolute inset-0 z-10 flex items-center justify-center pointer-events-none">
            <Avatar {...avatarProps} />
          </div>
        ) : (
          <div className="absolute inset-0 z-10 flex items-center justify-center">
            <p className="text-white text-sm animate-pulse">Loading</p>
          </div>
        )}

        <div
          className="absolute inset-0 z-20 hidden group-hover:flex items-center justify-center rounded-full cursor-pointer bg-black/25"
          onClick={handleSetIsOpen}
        >
          {isOpen ? <CloseCircularMenu /> : <CircularIcon />}
        </div>
      </div>
      {pages.map(([page, iconPath], index) => (
        <CircularItems
          key={page}
          page={page}
          iconPath={iconPath}
          rotation={(360 / pages.length) * index}
          menuIsOpen={isOpen}
          transitionDelay={index * 75}
          onSelect={category => setActiveCategory(category)}
        />
      ))}
      {activeCategory && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm"
          onClick={() => setActiveCategory(null)}
        >
          <AttributeCard
            title={`${activeCategory} Options`}
            onClose={() => setActiveCategory(null)}
            selectedAttributes={selectedAttributes}
            setSelectedAttributes={setSelectedAttributes}
            category={activeCategory}
          />
        </div>
      )}
    </div>
  );
};

export default CircularMenu;
