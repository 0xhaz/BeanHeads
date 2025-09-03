"use client";
import React, { useState, useEffect } from "react";
import CircularItems from "@/components/CircularItems";
import CloseCircularMenu from "@/components/CloseCircularMenu";
import CircularIcon from "@/components/CircularIcon";
import { AttributeCard, CATEGORY_MAP } from "./AttributeCard";
import { Avatar } from "./Avatar";
import { colors } from "@/utils/theme";

interface CircularMenuProps {
  pages: [string, string][];
  selectedAttributes: any | null;
  setSelectedAttributes: React.Dispatch<React.SetStateAction<any>>;
}

const CircularMenu = ({
  pages,
  selectedAttributes,
  setSelectedAttributes,
}: CircularMenuProps) => {
  const [isOpen, setIsOpen] = useState(false);
  const [activeCategory, setActiveCategory] = useState<string | null>(null);

  const handleSetIsOpen = () => {
    setIsOpen(prevBool => !prevBool);
  };

  // Enforce smart contract conditions on attribute changes
  useEffect(() => {
    if (!selectedAttributes) return;

    let updated = { ...selectedAttributes };

    // Lashes not allowed for certain eye shapes (matching isAllowedLashes in OptItems.sol)
    const disallowedEyeForLashes = [0, 1, 2, 6]; // HappyEyes, NormalEyes, LeftTwitchEyes, DizzyEyes
    const eyes = updated?.facialFeatures?.eyes ?? 0;
    if (disallowedEyeForLashes.includes(eyes) && updated?.misc?.lashes) {
      updated.misc.lashes = false;
    }

    // Hats not allowed for afro hair (ID 5)
    const disallowedHairForHats = [1]; // Afro
    const hairStyle = updated?.hair?.style ?? 0;
    if (
      disallowedHairForHats.includes(hairStyle) &&
      updated?.accessories?.hat !== 0
    ) {
      updated.accessories.hat = 0;
    }

    if (JSON.stringify(updated) !== JSON.stringify(selectedAttributes)) {
      setSelectedAttributes(updated);
    }
  }, [selectedAttributes, setSelectedAttributes]);

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
        mask: selectedAttributes?.misc?.shape ?? false,
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
