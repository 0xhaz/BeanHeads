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
import { BreedingMode, BreedRequest } from "@/types/Breeding";

const BreederABI = breeder.abi as Abi;

type BreederCtx = {
  chainId?: number;
  address?: `0x${string}`;
  contract?: ReturnType<typeof getContract> | undefined;
  depositBeanHeads: (tokenId: bigint) => Promise<PreparedTransaction>;
  withdrawBeanHeads: (tokenId: bigint) => Promise<PreparedTransaction>;
  requestBreed: (
    parent1: bigint,
    parent2: bigint,
    mode: BreedingMode,
    tokenAddress: `0x${string}`
  ) => Promise<PreparedTransaction>;
  setCoolDown: (time: bigint) => Promise<PreparedTransaction>;
  getRarityPoints: (tokenId: bigint) => Promise<bigint>;
  getBreedRequest: (requestId: bigint) => Promise<BreedRequest>;
  getEscrowedTokenOwner: (
    tokenId: bigint
  ) => Promise<`0x${string}` | undefined>;
  getParentBreedingCount?: (tokenId: bigint) => Promise<bigint>;
  withdrawFunds?: (tokenAddress: `0x${string}`) => Promise<PreparedTransaction>;
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

  async function depositBeanHeads(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const tx = await prepareContractCall({
        contract,
        method: "depositBeanHeads",
        params: [tokenId],
      });
      return sendTransaction({
        account: account!,
        transaction: tx,
      }) as Promise<PreparedTransaction>;
    } catch (e) {
      throw e;
    }
  }

  async function withdrawBeanHeads(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const tx = await prepareContractCall({
        contract,
        method: "withdrawBeanHeads",
        params: [tokenId],
      });
      return sendTransaction({
        account: account!,
        transaction: tx,
      }) as Promise<PreparedTransaction>;
    } catch (e) {
      throw e;
    }
  }

  async function requestBreed(
    parent1: bigint,
    parent2: bigint,
    mode: BreedingMode,
    tokenAddress: `0x${string}`
  ) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const tx = await prepareContractCall({
        contract,
        method: "requestBreed",
        params: [parent1, parent2, mode, tokenAddress],
      });
      return sendTransaction({
        account: account!,
        transaction: tx,
      }) as Promise<PreparedTransaction>;
    } catch (e) {
      throw e;
    }
  }

  async function setCoolDown(time: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const tx = await prepareContractCall({
        contract,
        method: "setCoolDown",
        params: [time],
      });
      return sendTransaction({
        account: account!,
        transaction: tx,
      }) as Promise<PreparedTransaction>;
    } catch (e) {
      throw e;
    }
  }

  async function getRarityPoints(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const points = await readContract({
        contract,
        method: "getRarityPoints",
        params: [tokenId],
      });
      return points as bigint;
    } catch (e) {
      throw e;
    }
  }

  async function getBreedRequest(requestId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const request = await readContract({
        contract,
        method: "getBreedRequest",
        params: [requestId],
      });
      return request as BreedRequest;
    } catch (e) {
      throw e;
    }
  }

  async function getEscrowedTokenOwner(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const owner = await readContract({
        contract,
        method: "getEscrowedTokenOwner",
        params: [tokenId],
      });
      return owner as `0x${string}` | undefined;
    } catch (e) {
      throw e;
    }
  }

  async function getParentBreedingCount(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const count = await readContract({
        contract,
        method: "getParentBreedingCount",
        params: [tokenId],
      });
      return count as bigint;
    } catch (e) {
      throw e;
    }
  }

  async function withdrawFunds(tokenAddress: `0x${string}`) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const tx = await prepareContractCall({
        contract,
        method: "withdrawFunds",
        params: [tokenAddress],
      });
      return sendTransaction({
        account: account!,
        transaction: tx,
      }) as Promise<PreparedTransaction>;
    } catch (e) {
      throw e;
    }
  }

  const value: BreederCtx = {
    chainId: chain?.id,
    address,
    contract,
    depositBeanHeads,
    withdrawBeanHeads,
    requestBreed,
    setCoolDown,
    getRarityPoints,
    getBreedRequest,
    getEscrowedTokenOwner,
    getParentBreedingCount,
    withdrawFunds,
  };

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useBreeder() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useBreeder must be used within a BreederProvider");
  return ctx;
}

export { BreederABI };
