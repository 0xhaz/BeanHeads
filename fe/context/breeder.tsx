"use client";

import { createContext, useContext, useMemo, useCallback } from "react";
import {
  getContract,
  readContract,
  prepareContractCall,
  sendTransaction,
  type PreparedTransaction,
  type BaseTransactionOptions,
} from "thirdweb";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import type { Abi } from "viem";
import {
  BREEDER_ADDRESS,
  USDC_ADDRESS,
  LINK_ADDRESS,
} from "@/constants/contract";
import { client } from "@/provider/client";
import breeder from "@/app/contracts/BeanHeadsBreeder.json";

const BreederABI = breeder.abi as Abi;

type BreederCtx = {
  chainId?: number;
  address: `0x${string}`;
  contract?: ReturnType<typeof getContract> | undefined;
};

const Ctx = createContext<BreederCtx | null>(null);

export function BreederProvider({ children }: { children: React.ReactNode }) {
  const account = useActiveAccount();
  const chain = useActiveWalletChain();

  const address = chain ? BREEDER_ADDRESS[chain.id] : undefined;

  const contract = useMemo(() => {
    if (!chain || !address) return undefined;

    return getContract({
      client,
      chain,
      address,
      abi: BreederABI as any,
    });
  }, [address, chain]);
}
