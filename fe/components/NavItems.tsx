"use client";
import { cn } from "@/lib/utils";
import Link from "next/link";
import { usePathname } from "next/navigation";

const navItems = [
  { name: "Home", href: "/" },
  { name: "About", href: "/about" },
  { name: "Contact", href: "/contact" },
];

const NavItems = () => {
  const pathname = usePathname();

  return (
    <nav className="flex space-x-4">
      {navItems.map(item => (
        <div key={item.name}>
          <Link
            href={item.href}
            className={cn(
              pathname === item.href && "text-primary font-semibold"
            )}
          >
            {item.name}
          </Link>
        </div>
      ))}
    </nav>
  );
};

export default NavItems;
