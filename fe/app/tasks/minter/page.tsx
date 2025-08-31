import CircularMenu from "@/components/CircularMenu";
import { Button } from "@/components/ui/button";

const pages = [
  ["Hair", "/icons/hair.svg"],
  ["Body", "/icons/body.svg"],
  ["Clothes", "/icons/clothing.svg"],
  ["Facial", "/icons/face.svg"],
  ["Accessories", "/icons/accessories.svg"],
  ["Misc", "/icons/utils.svg"],
];

const MintPage = () => {
  return (
    <div>
      <section>
        <div className="flex items-center justify-center h-[75vh] w-full">
          <CircularMenu pages={pages as [string, string][]} />
        </div>
      </section>
      <div className="flex justify-between gap-4 mb-10">
        <button className="btn-primary justify-center mx-auto px-8 py-4 text-2xl hover:bg-black/50">
          Mint Your NFT
        </button>
        <button className="btn-primary justify-center mx-auto px-8 py-4 text-2xl hover:bg-black/50">
          Randomize It!
        </button>
      </div>
    </div>
  );
};

export default MintPage;
