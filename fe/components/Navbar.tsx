import NavItems from "./NavItems";
import Image from "next/image";
import Link from "next/link";
import { ConnectButton } from "thirdweb/react";

const Navbar = () => {
  return (
    <nav className="navbar">
      <Link href="/">
        <div className="flex items-center gap-2.5 cursor-pointer">
          <Image src="/images/bean.svg" alt="Logo" width={46} height={44} />
        </div>
      </Link>
      <div className="flex items-center gap-8">
        <NavItems />
      </div>
    </nav>
  );
};

export default Navbar;
