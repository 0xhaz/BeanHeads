"use client";

import { createContext, useContext, useMemo } from "react";
import {
  getContract,
  readContract,
  prepareContractCall,
  sendTransaction,
  type PreparedTransaction,
  type BaseTransactionOptions,
} from "thirdweb";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import { sepolia, arbitrumSepolia, optimismSepolia } from "thirdweb/chains";
import { BEANHEADS_ADDRESS } from "@/constants/contract";
import beanHeadsDiamond from "@/contracts/BeanHeadsDiamond.json";
// Ensure ABI is typed as readonly for thirdweb
const BeanHeadsABI = beanHeadsDiamond.abi;

type BeanHeadsCtx = {
  chainId?: number;
  address?: `0x${string}`;
  contract?: ReturnType<typeof getContract> | undefined;
  totalSupply: () => Promise<bigint | undefined>;
  balanceOf: (owner: `0x${string}`) => Promise<bigint | undefined>;
};

const Ctx = createContext<BeanHeadsCtx | null>(null);

export function BeanHeadsProvider({ children }: { children: React.ReactNode }) {
  const account = useActiveAccount();
  const chain = useActiveWalletChain();

  const address = chain ? BEANHEADS_ADDRESS[chain.id] : undefined;

  const contract = useMemo(() => {
    if (!chain || !address) return undefined;

    return getContract({
      client: undefined as never,
      address: address,
      chain,
    });
  }, [chain, address]);

  /*//////////////////////////////////////////////////////////////
                              VIEW FACETS
    //////////////////////////////////////////////////////////////*/
  async function totalSupply() {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const supply = await readContract({
        contract,
        method: "function totalSupply() view returns (uint256)",
      });
      return supply as bigint;
    } catch (error) {
      console.error("Error fetching totalSupply:", error);
    }
  }

  async function tokenURI(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const uri = await readContract({
        contract,
        method: "function tokenURI(uint256 tokenId) view returns (string)",
        params: [tokenId],
      });
      return uri as string;
    } catch (error) {
      console.error("Error fetching tokenURI:", error);
    }
  }

  async function getAttributesByTokenId(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const attr = await readContract({
        contract,
        method:
          "function getAttributesByTokenId(uint256 tokenId) view returns (string[] memory)",
        params: [tokenId],
      });
      return attr as string[];
    } catch (error) {
      console.error("Error fetching attributes:", error);
    }
  }

  async function getAttributesByOwner(owner: `0x${string}`, tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const attr = await readContract({
        contract,
        method:
          "function getAttributesByOwner(address owner, uint256 tokenId) view returns (string[] memory)",
        params: [owner, tokenId],
      });
      return attr as string[];
    } catch (error) {
      console.error("Error fetching attributes:", error);
    }
  }

  async function getAttributes(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const attr = await readContract({
        contract,
        method:
          "function getAttributes(uint256 tokenId) view returns (string memory)",
        params: [tokenId],
      });
      return attr as string;
    } catch (error) {
      console.error("Error fetching attributes:", error);
    }
  }
}
