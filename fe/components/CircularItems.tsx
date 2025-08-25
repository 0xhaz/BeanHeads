import Image from "next/image";

interface CircularMenuItemsProps {
  page?: string;
  iconPath: string;
  rotation: number;
  menuIsOpen?: boolean;
  transitionDelay?: number;
  onSelect?: (category: string) => void;
}

const CircularItems = ({
  page,
  iconPath,
  rotation,
  menuIsOpen,
  transitionDelay,
  onSelect,
}: CircularMenuItemsProps) => {
  return (
    <div
      className={`absolute top-0 left-0 flex items-center justify-center w-full h-full rounded-full transition-transform duration-300 ease-in-out
        ${
          menuIsOpen
            ? "opacity-100 pointer-events-auto"
            : "opacity-0 pointer-events-none"
        }`}
      style={{
        transform: `rotate(${rotation}deg) translate(${menuIsOpen ? 175 : 0}%)`,
        transitionDelay: `${menuIsOpen ? transitionDelay : 0}ms`,
      }}
    >
      <div
        className="group relative w-[150px] h-[150px] flex items-center justify-center rounded-full overflow-hidden border-4 border-white shadow-lg"
        style={{ transform: `rotate(${-rotation}deg)` }}
      >
        <Image src={iconPath} alt={page || "icon"} width={100} height={100} />
        <div
          className="absolute inset-0 bg-black/30 backdrop-blur-xl rounded-full opacity-0 group-hover:opacity-80  transition duration-300 flex items-center justify-center text-white font-semibold text-xl cursor-pointer"
          onClick={() => onSelect?.(page!)}
        >
          {page}
        </div>
      </div>
    </div>
  );
};

export default CircularItems;
