"use client";
import { cn } from "@/lib/utils";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { ConnectButton } from "thirdweb/react";
import { inAppWallet, createWallet } from "thirdweb/wallets";
import { client, wallets } from "@/provider/client";
import { arbitrumSepolia, optimismSepolia, sepolia } from "thirdweb/chains";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

const navItems = [
  { name: "Home", href: "/" },
  { name: "About", href: "/about" },
  { name: "Contact", href: "/contact" },
];

const queryClient = new QueryClient();

const NavItems = () => {
  const pathname = usePathname();

  return (
    <nav className="flex  space-x-4">
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
      <QueryClientProvider client={queryClient}>
        <ConnectButton
          client={client}
          wallets={wallets}
          chains={[sepolia, arbitrumSepolia, optimismSepolia]}
          // accountAbstraction={{
          //   chain: sepolia,
          //   sponsorGas: true,
          // }}
          connectModal={{ size: "wide" }}
        />
      </QueryClientProvider>
    </nav>
  );
};

export default NavItems;
