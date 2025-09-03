"use client";
import { useState, useEffect, use } from "react";
import CircularMenu from "@/components/CircularMenu";
import { colors } from "@/utils/theme";
import {
  Avatar,
  generateRandomAvatarAttributes as selectRandom,
} from "@/components/Avatar";

const pages = [
  ["Hair", "/icons/hair.svg"],
  ["Body", "/icons/body.svg"],
  ["Clothes", "/icons/clothing.svg"],
  ["Facial", "/icons/face.svg"],
  ["Accessories", "/icons/accessories.svg"],
  ["Misc", "/icons/utils.svg"],
];

const MintPage = () => {
  const [selectedAttributes, setSelectedAttributes] = useState<any | null>(
    null
  );

  useEffect(() => {
    const randomAttributes = selectRandom();
    console.log("Random Attributes:", randomAttributes);
    setSelectedAttributes(randomAttributes);
  }, []);

  const handleRandomize = () => {
    const randomAttributes = selectRandom();
    console.log("Randomized Attributes:", randomAttributes);
    setSelectedAttributes(randomAttributes);
  };

  return (
    <div>
      <section>
        <div className="flex items-center justify-center h-[75vh] w-full">
          <CircularMenu
            pages={pages as [string, string][]}
            selectedAttributes={selectedAttributes}
            setSelectedAttributes={setSelectedAttributes}
          />
        </div>
      </section>
      <div className="flex justify-between gap-4 mb-10">
        <button className="btn-primary justify-center mx-auto px-8 py-4 text-2xl hover:bg-black/50">
          Mint Your NFT
        </button>
        <button
          className="btn-primary justify-center mx-auto px-8 py-4 text-2xl hover:bg-black/50"
          onClick={handleRandomize}
        >
          Randomize It!
        </button>
      </div>
    </div>
  );
};

export default MintPage;
