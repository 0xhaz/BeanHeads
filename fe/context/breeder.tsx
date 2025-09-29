"use client";

import { createContext, useContext, useMemo, useCallback } from "react";
import {
  getContract,
  readContract,
  prepareContractCall,
  sendTransaction,
  waitForReceipt,
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
  approveToken: (
    owner: `0x${string}`,
    spender: `0x${string}`,
    amount: bigint,
    chain: any
  ) => Promise<void>;
  ensureTokenApproval: (tokenId: bigint) => Promise<void>;
  depositBeanHeads: (tokenId: bigint) => Promise<void>;
  withdrawBeanHeads: (tokenId: bigint) => Promise<void>;
  requestBreed: (
    parent1: bigint,
    parent2: bigint,
    mode: BreedingMode,
    tokenAddress: `0x${string}`
  ) => Promise<void>;
  setCoolDown: (time: bigint) => Promise<void>;
  getRarityPoints: (tokenId: bigint) => Promise<bigint>;
  getBreedRequest: (requestId: bigint) => Promise<BreedRequest>;
  getEscrowedTokenOwner: (
    tokenId: bigint
  ) => Promise<`0x${string}` | undefined>;
  getParentBreedingCount?: (tokenId: bigint) => Promise<bigint>;
  withdrawFunds?: (tokenAddress: `0x${string}`) => Promise<void>;
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

    const THRESHOLD = BigInt(10) ** BigInt(24);
    if (allowance >= THRESHOLD) return;

    const tx = await prepareContractCall({
      contract: usdc,
      method: "approve",
      params: [spender, amount],
    });

    const result = await sendTransaction({
      account: account!,
      transaction: tx,
    });
    await waitForReceipt(result);
  }

  async function ensureTokenApproval(tokenId: bigint) {
    if (!nftContract || !account || !chain)
      throw new Error("NFT Contract not initialized");

    const me = account.address.toLowerCase();
    const breeder = BREEDER_ADDRESS[chain.id].toLowerCase();

    // read owner defensively
    let owner: `0x${string}` | undefined;
    try {
      owner = (await readContract({
        contract: nftContract,
        method: "getOwnerOf",
        params: [tokenId],
      })) as `0x${string}`;
    } catch {
      return;
    }

    if (!owner || owner.toLowerCase() !== me) return; // already escrowed or not mine

    try {
      const approved = (await readContract({
        contract: nftContract,
        method: "getApproved",
        params: [tokenId],
      })) as `0x${string}`;
      if (approved && approved.toLowerCase() === breeder) return;
    } catch {
      // ignore – we'll approve below
    }

    const approveTx = await prepareContractCall({
      contract: nftContract,
      method: "approve",
      params: [BREEDER_ADDRESS[chain.id], tokenId],
    });
    const result = await sendTransaction({
      account: account!,
      transaction: approveTx,
    });
    await waitForReceipt(result);
  }

  async function depositBeanHeads(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");

    const tx = await prepareContractCall({
      contract,
      method: "depositBeanHeads",
      params: [tokenId],
    });
    const result = await sendTransaction({
      account: account!,
      transaction: tx,
    });
    await waitForReceipt(result);
  }

  async function withdrawBeanHeads(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const tx = await prepareContractCall({
        contract,
        method: "withdrawBeanHeads",
        params: [tokenId],
      });
      const result = await sendTransaction({
        account: account!,
        transaction: tx,
      });
      await waitForReceipt(result);
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
    if (!contract || !chain || !account)
      throw new Error("Contract not initialized");

    if (mode === BreedingMode.Ascension && parent2 !== BigInt(0))
      throw new Error("Ascension mode requires parent2 to be 0");
    if (parent1 === parent2)
      throw new Error("Parent1 and Parent2 cannot be the same");

    // optional: assert tokens are escrowed by the caller
    const escrow1 = await getEscrowedTokenOwner(parent1);
    if (!escrow1 || escrow1.toLowerCase() !== account.address!.toLowerCase())
      throw new Error("Parent 1 is not escrowed by you");

    if (mode !== BreedingMode.Ascension) {
      const escrow2 = await getEscrowedTokenOwner(parent2);
      if (!escrow2 || escrow2.toLowerCase() !== account.address!.toLowerCase())
        throw new Error("Parent 2 is not escrowed by you");
    }

    // USDC allowance (unchanged)
    if (tokenAddress) {
      await approveToken(
        account.address as `0x${string}`,
        contract.address as `0x${string}`,
        BigInt(10) ** BigInt(18),
        chain
      );
    }

    const tx = await prepareContractCall({
      contract,
      method: "requestBreed",
      params: [parent1, parent2, mode, tokenAddress],
    });
    const result = await sendTransaction({
      account: account!,
      transaction: tx,
    });
    await waitForReceipt(result);
  }

  async function setCoolDown(time: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const tx = await prepareContractCall({
        contract,
        method: "setCoolDown",
        params: [time],
      });
      const result = await sendTransaction({
        account: account!,
        transaction: tx,
      });
      await waitForReceipt(result);
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
      console.log("Rarity points:", points);
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
      console.log("Breeding count:", count);
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
      const result = await sendTransaction({
        account: account!,
        transaction: tx,
      });
      await waitForReceipt(result);
    } catch (e) {
      throw e;
    }
  }

  const value: BreederCtx = {
    chainId: chain?.id,
    address,
    contract,
    approveToken,
    getContractAddress,
    ensureTokenApproval,
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
