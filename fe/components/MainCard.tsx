import Image from "next/image";
import Link from "next/link";

interface MainCardProps {
  id: string;
  title: string;
  image: string;
  description: string;
  color: string;
}

const MainCard = ({ id, title, image, description, color }: MainCardProps) => {
  return (
    <article className="companion-card mt-3" style={{ backgroundColor: color }}>
      <div className="flex justify-between items-center">
        <div className="font-bold">{title}</div>
        <button className="companion-bookmark">
          <Image
            src="/icons/bookmark.svg"
            alt="bookmark"
            width={12.5}
            height={15}
          />
        </button>
      </div>
      <Image
        src={image}
        alt={title}
        width={100}
        height={100}
        className="w-[150px] object-cover rounded-lg mx-auto mb-2"
      />
      <p className="text-sm mx-auto">{description}</p>
      <Link href={`/tasks/${id}`} className="w-full">
        <button className="btn-primary w-full justify-center">
          Go to page
        </button>
      </Link>
    </article>
  );
};

export default MainCard;
