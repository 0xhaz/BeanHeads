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
import type { Abi } from "viem";
import {
  BEANHEADS_ADDRESS,
  USDC_ADDRESS,
  LINK_ADDRESS,
} from "@/constants/contract";
import { client } from "@/provider/client";
import beanHeadsDiamond from "@/app/contracts/BeanHeadsDiamond.json";
import {
  ACCESSORIES,
  BG_COLORS,
  BODY_TYPES,
  CLOTHING_COLORS,
  CLOTHING_GRAPHICS,
  CLOTHING_STYLES,
  EYE_SHAPES,
  EYEBROW_SHAPES,
  FACIAL_HAIR_STYLES,
  HAIR_COLORS,
  HAIR_STYLES,
  HAT_STYLES,
  LIP_COLORS,
  MOUTH_SHAPES,
  SKIN_COLORS,
} from "@/components/Avatar";
// Ensure ABI is typed as readonly for thirdweb
const rawAbi = beanHeadsDiamond.abi as any[];

const BeanHeadsABI: Abi = rawAbi.map(item => {
  if (item?.type === "function" && item.outputs === undefined) {
    return { ...item, outputs: [] };
  }
  return item;
}) as Abi;

type BeanHeadsCtx = {
  chainId?: number;
  address?: `0x${string}`;
  contract?: ReturnType<typeof getContract> | undefined;
  totalSupply: () => Promise<bigint | undefined>;
  balanceOf: (owner: `0x${string}`) => Promise<bigint | undefined>;
  mintGenesis?: (
    address: `0x${string}`,
    svgParams: any,
    amount: bigint,
    paymentToken: `0x${string}` | null,
    options?: BaseTransactionOptions
  ) => Promise<PreparedTransaction>;
  tokenURI: (tokenId: bigint) => Promise<string | undefined>;
  getAttributesByTokenId: (tokenId: bigint) => Promise<string[] | undefined>;
  getAttributesByOwner: (
    owner: `0x${string}`,
    tokenId: bigint
  ) => Promise<string[] | undefined>;
  getAttributes: (tokenId: bigint) => Promise<string | undefined>;
  exists: (tokenId: bigint) => Promise<boolean | undefined>;
  getOwnerTokensCount: (owner: `0x${string}`) => Promise<bigint | undefined>;
  isBridgeAuthorized: (
    chainId: bigint,
    bridgeAddress: `0x${string}`
  ) => Promise<boolean | undefined>;
  isTokenLocked: (tokenId: bigint) => Promise<boolean | undefined>;
  mintBridgeToken?: (
    address: `0x${string}`,
    tokenId: bigint,
    svgParams: any,
    originChainId: bigint,
    options?: BaseTransactionOptions
  ) => Promise<PreparedTransaction>;
  unlockToken?: (tokenId: bigint) => Promise<PreparedTransaction>;
  lockToken?: (tokenId: bigint) => Promise<PreparedTransaction>;
  burnToken?: (tokenId: bigint) => Promise<PreparedTransaction>;
  approve?: (
    to: `0x${string}`,
    tokenId: bigint
  ) => Promise<PreparedTransaction>;
  name: () => Promise<string>;
  symbol: () => Promise<string>;
  getOwnerOf: (tokenId: bigint) => Promise<`0x${string}`>;
};

const Ctx = createContext<BeanHeadsCtx | null>(null);

export function BeanHeadsProvider({ children }: { children: React.ReactNode }) {
  const account = useActiveAccount();
  const chain = useActiveWalletChain();

  const address = chain ? BEANHEADS_ADDRESS[chain.id] : undefined;

  const contract = useMemo(() => {
    if (!chain || !address) return undefined;

    return getContract({
      client,
      chain,
      address,
      abi: BeanHeadsABI,
    });
  }, [address, chain]);

  /*//////////////////////////////////////////////////////////////
                              VIEW FACET
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

  async function exists(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method: "function exists(uint256 tokenId) view returns (bool)",
      params: [tokenId],
    }) as Promise<boolean>;
  }

  async function getOwnerTokensCount(owner: `0x${string}`) {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method:
        "function getOwnerTokensCount(address owner) view returns (uint256)",
      params: [owner],
    }) as Promise<bigint>;
  }

  async function isBridgeAuthorized(
    chainId: bigint,
    bridgeAddress: `0x${string}`
  ) {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method:
        "function isBridgeAuthorized(uint256 chainId, address bridgeAddress) view returns (bool)",
      params: [chainId, bridgeAddress],
    }) as Promise<boolean>;
  }

  async function isTokenLocked(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method: "function isTokenLocked(uint256 tokenId) view returns (bool)",
      params: [tokenId],
    }) as Promise<boolean>;
  }

  /*//////////////////////////////////////////////////////////////
                               MINT FACET
    //////////////////////////////////////////////////////////////*/

  const hairParams = {
    hairStyle: HAIR_STYLES,
    hairColor: HAIR_COLORS,
  };
  const bodyParams = {
    bodyType: BODY_TYPES,
    skinColor: SKIN_COLORS,
  };
  const clothingParams = {
    clothes: CLOTHING_STYLES,
    clothingColor: CLOTHING_COLORS,
    clothesGraphic: CLOTHING_GRAPHICS,
  };
  const facialFeatureParams = {
    eyebrowShape: EYEBROW_SHAPES,
    eyeShape: EYE_SHAPES,
    facialHairType: FACIAL_HAIR_STYLES,
    mouthStyle: MOUTH_SHAPES,
    lipColor: LIP_COLORS,
  };
  const accessoryParams = {
    accessoryId: ACCESSORIES,
    hatStyle: HAT_STYLES,
    hatColor: CLOTHING_COLORS,
  };
  const otherParams = {
    faceMask: [true, false],
    faceMaskColor: CLOTHING_COLORS,
    shapes: [true, false],
    shapeColor: BG_COLORS,
    lashes: [true, false],
  };
  const svgParams = {
    ...hairParams,
    ...bodyParams,
    ...clothingParams,
    ...facialFeatureParams,
    ...accessoryParams,
    ...otherParams,
  };

  async function mintGenesis(
    address: `0x${string}`,
    svgParams: any,
    amount: bigint,
    paymentToken: `0x${string}` | null,
    options?: BaseTransactionOptions
  ) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method:
        "function mintGenesis(address to, string[] memory svgParams, uint256 amount, address paymentToken) returns (uint256)",
      params: [
        address,
        Object.values(svgParams) as string[],
        amount,
        paymentToken ?? USDC_ADDRESS[chain?.id!],
      ],
      value: paymentToken ? BigInt(0) : amount,
      ...options,
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function mintBridgeToken(
    address: `0x${string}`,
    tokenId: bigint,
    svgParams: any,
    originChainId: bigint,
    options?: BaseTransactionOptions
  ) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method:
        "function mintBridgeToken(address to, uint256 tokenId, string[] memory svgParams, uint256 originChainId)",
      params: [
        address,
        tokenId,
        Object.values(svgParams) as string[],
        originChainId,
      ],
      ...options,
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function unlockToken(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "function unlockToken(uint256 tokenId)",
      params: [tokenId],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function lockToken(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "function lockToken(uint256 tokenId)",
      params: [tokenId],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  function burnToken(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = prepareContractCall({
      contract,
      method: "function burnToken(uint256 tokenId)",
      params: [tokenId],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  function approve(to: `0x${string}`, tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = prepareContractCall({
      contract,
      method: "function approve(address to, uint256 tokenId) payable",
      params: [to, tokenId],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  function name() {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method: "function name() view returns (string)",
    }) as Promise<string>;
  }

  function symbol() {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method: "function symbol() view returns (string)",
    }) as Promise<string>;
  }

  async function balanceOf(owner: `0x${string}`) {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const balance = await readContract({
        contract,
        method: "function balanceOf(address owner) view returns (uint256)",
        params: [owner],
      });
      return balance as bigint;
    } catch (error) {
      console.error("Error fetching balanceOf:", error);
    }
  }

  function getOwnerOf(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method: "function ownerOf(uint256 tokenId) view returns (address)",
      params: [tokenId],
    }) as Promise<`0x${string}`>;
  }

  const value: BeanHeadsCtx = {
    chainId: chain?.id,
    address,
    contract,
    totalSupply,
    balanceOf,
    mintGenesis,
    tokenURI,
    getAttributesByTokenId,
    getAttributesByOwner,
    getAttributes,
    exists,
    getOwnerTokensCount,
    isBridgeAuthorized,
    isTokenLocked,
    mintBridgeToken,
    unlockToken,
    lockToken,
    burnToken,
    approve,
    name,
    symbol,
    getOwnerOf,
  };

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useBeanHeads() {
  const context = useContext(Ctx);
  if (!context) {
    throw new Error("useBeanHeads must be used within a BeanHeadsProvider");
  }
  return context;
}

export { BeanHeadsABI };
