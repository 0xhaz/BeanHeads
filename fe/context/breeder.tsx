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
  BEANHEADS_ADDRESS,
} from "@/constants/contract";
import { client } from "@/provider/client";
import breeder from "@/app/contracts/BeanHeadsBreeder.json";
import ERC20 from "@/app/contracts/ERC20.json";
import { BreedingMode, BreedRequest } from "@/types/Breeding";
import { BeanHeadsABI } from "./beanheads";

const BreederABI = breeder.abi as Abi;
const ERC20ABI = ERC20 as Abi;

type BreederCtx = {
  chainId?: number;
  address?: `0x${string}`;
  contract?: ReturnType<typeof getContract> | undefined;
  getContractAddress: (chainId?: number) => Promise<`0x${string}`>;
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
      chain: chain!,
      address,
      abi: BreederABI as any,
    });
  }, [address, chain]);

  const nftContract = useMemo(() => {
    if (!chain) return undefined;

    return getContract({
      client,
      chain: chain!,
      address: BEANHEADS_ADDRESS[chain.id],
      abi: BeanHeadsABI as any,
    });
  }, [chain]);

  async function getContractAddress(chainId?: number) {
    if (!chainId) throw new Error("Chain ID is required");
    const addr = BREEDER_ADDRESS[chainId];
    if (!addr) throw new Error("No Breeder contract address for this chain");
    return addr;
  }

  async function approveToken(
    owner: `0x${string}`,
    spender: `0x${string}`,
    amount: bigint,
    chain: any
  ) {
    const usdc = getContract({
      client,
      chain,
      address: USDC_ADDRESS[chain.id],
      abi: ERC20ABI as any,
    });

    const allowance = (await readContract({
      contract: usdc,
      method: "allowance",
      params: [owner, spender],
    })) as bigint;

    if (allowance < amount) {
      const tx = await prepareContractCall({
        contract: usdc,
        method: "approve",
        params: [spender, amount],
      });

      await sendTransaction({
        account: account!,
        transaction: tx,
      });
    }
  }

  //   async function tokenIdApproval(tokenId: bigint) {
  //     if (!nftContract) throw new Error("NFT Contract not initialized");

  //     const tx = await prepareContractCall({
  //       contract: nftContract,
  //       method: "function approve(address to, uint256 tokenId)",
  //       params: [BREEDER_ADDRESS[chain!.id], tokenId],
  //     });

  //     await sendTransaction({
  //       account: account!,
  //       transaction: tx,
  //     });
  //   }

  //   async function depositBeanHeads(tokenId: bigint) {
  //     if (!contract) throw new Error("Contract not initialized");

  //     await tokenIdApproval(tokenId);

  //     const tx = await prepareContractCall({
  //       contract,
  //       method: "depositBeanHeads",
  //       params: [tokenId],
  //     });
  //     return sendTransaction({
  //       account: account!,
  //       transaction: tx,
  //     }) as Promise<PreparedTransaction>;
  //   }

  async function ensureTokenApproval(tokenId: bigint) {
    if (!nftContract || !account || !chain)
      throw new Error("NFT Contract not initialized");

    // check existing approval
    const approved = (await readContract({
      contract: nftContract,
      method: "getApproved",
      params: [tokenId],
    })) as `0x${string}`;

    const breeder = BREEDER_ADDRESS[chain.id].toLowerCase();
    if (approved && approved.toLowerCase() === breeder) return; // already approved

    // approve breeder
    const approveTx = await prepareContractCall({
      contract: nftContract,
      method: "approve",
      params: [BREEDER_ADDRESS[chain.id], tokenId],
    });

    await sendTransaction({
      account: account!,
      transaction: approveTx,
    });

    // poll until approval is visible
    for (let i = 0; i < 10; i++) {
      const now = (await readContract({
        contract: nftContract,
        method: "getApproved",
        params: [tokenId],
      })) as `0x${string}`;
      if (now && now.toLowerCase() === breeder) return;
      await new Promise(r => setTimeout(r, 800));
    }

    throw new Error("Approval not confirmed after waiting");
  }

  async function depositBeanHeads(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");

    await ensureTokenApproval(tokenId);

    const tx = await prepareContractCall({
      contract,
      method: "depositBeanHeads",
      params: [tokenId],
    });

    return sendTransaction({
      account: account!,
      transaction: tx,
    }) as Promise<PreparedTransaction>;
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
    if (mode === BreedingMode.Ascension && parent2 !== BigInt(0)) {
      throw new Error("Ascension mode requires parent2 to be 0");
    }
    if (parent1 === parent2) {
      throw new Error("Parent1 and Parent2 cannot be the same");
    }

    if (tokenAddress) {
      await approveToken(
        account!.address as `0x${string}`,
        contract.address as `0x${string}`,
        BigInt(10) ** BigInt(18),
        chain
      );
    }

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
    getContractAddress,
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
