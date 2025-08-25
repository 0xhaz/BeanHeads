"use client";
import { useState } from "react";
import CircularItems from "@/components/CircularItems";
import CloseCircularMenu from "@/components/CloseCircularMenu";
import CircularIcon from "@/components/CircularIcon";
import AttributeCard from "./AttributeCard";

interface CircularMenuProps {
  pages: [string, string][];
}

const CircularMenu = ({ pages }: CircularMenuProps) => {
  const [isOpen, setIsOpen] = useState(false);
  const [activeCategory, setActiveCategory] = useState<string | null>(null);

  const handleSetIsOpen = () => {
    setIsOpen(prevBool => !prevBool);
  };
  return (
    <div className="h-[200px] w-[200px] relative ">
      <div className="group absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 h-[250px] w-[250px] rounded-full  border-4 border-white shadow-lg z-50 flex items-center justify-center">
        <div
          className="hidden group-hover:flex items-center justify-center w-full h-full rounded-full cursor-pointer transition-transform duration-300 ease-in-out bg-black/25"
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
          />
        </div>
      )}
    </div>
  );
};

export default CircularMenu;
