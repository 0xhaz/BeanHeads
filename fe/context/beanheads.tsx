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
  BEANHEADS_ADDRESS,
  USDC_ADDRESS,
  LINK_ADDRESS,
} from "@/constants/contract";
import { client } from "@/provider/client";
import beanHeads from "@/app/contracts/BeanHeadsABI.json";
import ERC20 from "@/app/contracts/ERC20.json";
import { generateRandomAvatarAttributes } from "@/components/Avatar";
import { SVGParams, toSVGParamsFromAvatar } from "@/utils/encode";
// Ensure ABI is typed as readonly for thirdweb
// const rawAbi = beanHeads.abi as any[];
const BeanHeadsABI = beanHeads.abi as Abi;
const ERC20ABI = ERC20 as Abi;

// const BeanHeadsABI: Abi = rawAbi.map(item => {
//   if (item?.type === "function" && item.outputs === undefined) {
//     return { ...item, outputs: [] };
//   }
//   return item;
// }) as Abi;

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
  mintBridgeGenesis?: (
    address: `0x${string}`,
    svgParams: any,
    amount: bigint,
    paymentToken: `0x${string}` | null
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
  getPriceFeed: (token: `0x${string}`) => Promise<`0x${string}`>;
  getGeneration: (tokenId: bigint) => Promise<bigint>;
  getOwnerTokens: (owner: `0x${string}`) => Promise<bigint[]>;
  getAuthorizedBreeders: (address: `0x${string}`) => Promise<`0x${string}`[]>;
  sellToken: (tokenId: bigint, price: bigint) => Promise<PreparedTransaction>;
  batchSellTokens: (
    tokenIds: bigint[],
    price: bigint[]
  ) => Promise<PreparedTransaction>;
  buyToken: (
    buyer: `0x${string}`,
    tokenId: bigint,
    paymentToken: `0x${string}`
  ) => Promise<PreparedTransaction>;
  batchBuyTokens: (
    buyer: `0x${string}`,
    tokenIds: bigint[],
    paymentToken: `0x${string}`
  ) => Promise<PreparedTransaction>;
  cancelTokenSale: (tokenId: bigint) => Promise<PreparedTransaction>;
  batchCancelTokenSales: (
    tokenIds: bigint[],
    seller: `0x${string}`
  ) => Promise<PreparedTransaction>;
  getTokenSalePrice: (tokenId: bigint) => Promise<bigint>;
  isTokenForSale: (tokenId: bigint) => Promise<boolean>;
  getTokenSaleInfo: (
    tokenId: bigint
  ) => Promise<{ seller: `0x${string}`; price: bigint; isActive: boolean }>;
  ready: boolean;
  getAllActiveSaleTokens: () => Promise<bigint[]>;
  setMintPrice?: (newPrice: bigint) => Promise<PreparedTransaction>;
  setAllowedToken?: (
    address: `0x${string}`,
    isAllowed: boolean
  ) => Promise<PreparedTransaction>;
  addPriceFeed?: (
    token: `0x${string}`,
    feed: `0x${string}`
  ) => Promise<PreparedTransaction>;
  withdraw: (token: `0x${string}`) => Promise<PreparedTransaction>;
  authorizeBreeder: (breeder: `0x${string}`) => Promise<PreparedTransaction>;
  setRemoteBridge: (
    chainId: bigint,
    bridgeAddress: `0x${string}`
  ) => Promise<PreparedTransaction>;
  balanceOfERC20: (token: `0x${string}`, chain: any) => Promise<bigint>;
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
      abi: BeanHeadsABI as any,
    });
  }, [address, chain]);

  const tokenContract = useCallback(
    (token: `0x${string}`, chain: any) => {
      return getContract({
        client,
        chain,
        address: token,
        abi: ERC20ABI as any,
      });
    },
    [client]
  );

  /*//////////////////////////////////////////////////////////////
                              VIEW FACET
    //////////////////////////////////////////////////////////////*/
  async function totalSupply() {
    console.log("Contract in totalSupply:", contract);
    if (!contract) throw new Error("Contract not initialized");
    try {
      const supply = await readContract({
        contract,
        method: "function getTotalSupply() view returns (uint256)",
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
        method: "getAttributesByTokenId",
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
        method: "getAttributesByOwner",
        params: [owner, tokenId],
      });
      console.log("Attributes by Owner:", attr);
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

  async function getMintPrice() {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const price = await readContract({
        contract,
        method: "getMintPrice",
      });
      return price as bigint;
    } catch (error) {
      console.error("Error fetching mint price:", error);
    }
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

  async function mintGenesis(
    address: `0x${string}`,
    avatar: ReturnType<typeof generateRandomAvatarAttributes>,
    amount: bigint,
    paymentToken: `0x${string}` | null
  ) {
    if (!contract) throw new Error("Contract not initialized");

    const svgParams = toSVGParamsFromAvatar(avatar);

    if (paymentToken) {
      const priceUsd18 = await getMintPrice();
      const totalPrice = (priceUsd18 ?? BigInt(0)) * amount;
      await approveToken(
        account!.address as `0x${string}`,
        contract.address as `0x${string}`,
        totalPrice,
        chain
      );
    }

    const txRequest = await prepareContractCall({
      contract,
      method: "mintGenesis",
      params: [
        address,
        svgParams as any,
        amount,
        paymentToken ?? USDC_ADDRESS[chain?.id!],
      ],
      value: paymentToken ? BigInt(0) : amount,
    });
    return sendTransaction({
      account: account!,
      transaction: txRequest,
    });
  }

  async function mintBridgeGenesis(
    address: `0x${string}`,
    avatar: ReturnType<typeof generateRandomAvatarAttributes>,
    amount: bigint,
    paymentToken: `0x${string}` | null
  ) {
    if (!contract) throw new Error("Contract not initialized");

    const svgParams = toSVGParamsFromAvatar(avatar);

    if (paymentToken) {
      const priceUsd18 = await getMintPrice();
      const totalPrice = (priceUsd18 ?? BigInt(0)) * amount;
      await approveToken(
        account!.address as `0x${string}`,
        contract.address as `0x${string}`,
        totalPrice,
        chain
      );
    }

    const txRequest = await prepareContractCall({
      contract,
      method: "mintBridgeGenesis",
      params: [
        address,
        svgParams as any,
        amount,
        paymentToken ?? USDC_ADDRESS[chain?.id!],
      ],
      value: paymentToken ? BigInt(0) : amount,
    });
    return sendTransaction({
      account: account!,
      transaction: txRequest,
    });
  }

  async function mintBridgeToken(
    address: `0x${string}`,
    tokenId: bigint,
    avatar: ReturnType<typeof generateRandomAvatarAttributes>,
    originChainId: bigint,
    options?: BaseTransactionOptions
  ) {
    if (!contract) throw new Error("Contract not initialized");

    const svgParams = toSVGParamsFromAvatar(avatar as any);

    const prepared = await prepareContractCall({
      contract,
      method:
        "function mintBridgeToken(address to, uint256 tokenId, string[] memory svgParams, uint256 originChainId)",
      params: [
        address,
        tokenId,
        svgParams as unknown as string[],
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

  async function getOwnerOf(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    let owner = await readContract({
      contract,
      method: "getOwnerOf",
      params: [tokenId],
    });
    return owner as `0x${string}`;
  }

  /*//////////////////////////////////////////////////////////////
                             BREEDER FACET
  //////////////////////////////////////////////////////////////*/

  async function getAuthorizedBreeders(address: `0x${string}`) {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method: "getAuthorizedBreeders",
      params: [address],
    }) as Promise<`0x${string}`[]>;
  }

  async function getGeneration(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method: "getGeneration",
      params: [tokenId],
    }) as Promise<bigint>;
  }

  async function getOwnerTokens(owner: `0x${string}`) {
    if (!contract) throw new Error("Contract not initialized");
    const tokens = await readContract({
      contract,
      method: "getOwnerTokens",
      params: [owner],
    });
    return tokens as bigint[];
  }

  async function getPriceFeed(token: `0x${string}`) {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method: "getPriceFeed",
      params: [token],
    }) as Promise<`0x${string}`>;
  }

  /*//////////////////////////////////////////////////////////////
                           MARKETPLACE FACET
    //////////////////////////////////////////////////////////////*/

  async function sellToken(tokenId: bigint, price: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "sellToken",
      params: [tokenId, price],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function batchSellTokens(tokenIds: bigint[], price: bigint[]) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "batchSellTokens",
      params: [tokenIds, price],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function buyToken(
    buyer: `0x${string}`,
    tokenId: bigint,
    paymentToken: `0x${string}`
  ) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "buyToken",
      params: [buyer, tokenId, paymentToken],
      value: paymentToken === USDC_ADDRESS[chain?.id!] ? BigInt(0) : undefined,
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function batchBuyTokens(
    buyer: `0x${string}`,
    tokenIds: bigint[],
    paymentToken: `0x${string}`
  ) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "batchBuyTokens",
      params: [buyer, tokenIds, paymentToken],
      value: paymentToken === USDC_ADDRESS[chain?.id!] ? BigInt(0) : undefined,
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function cancelTokenSale(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "cancelTokenSale",
      params: [tokenId],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function batchCancelTokenSales(
    tokenIds: bigint[],
    seller: `0x${string}`
  ) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "batchCancelTokenSales",
      params: [tokenIds, seller],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function getTokenSalePrice(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method: "getTokenSalePrice",
      params: [tokenId],
    }) as Promise<bigint>;
  }

  async function isTokenForSale(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method: "isTokenForSale",
      params: [tokenId],
    }) as Promise<boolean>;
  }

  async function getTokenSaleInfo(tokenId: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    return readContract({
      contract,
      method: "getTokenSaleInfo",
      params: [tokenId],
    }) as Promise<{
      seller: `0x${string}`;
      price: bigint;
      isActive: boolean;
    }>;
  }

  const ready = !!contract;
  const getAllActiveSaleTokens = useCallback(async () => {
    if (!contract) return [] as bigint[];
    return (await readContract({
      contract,
      method: "getAllActiveSaleTokens",
      params: [],
    })) as Promise<bigint[]>;
  }, [contract]);

  /*//////////////////////////////////////////////////////////////
                              ADMIN FACET
    //////////////////////////////////////////////////////////////*/

  async function setMintPrice(price: bigint) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "setMintPrice",
      params: [price],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function setAllowedToken(address: `0x${string}`, isAllowed: boolean) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "setAllowedToken",
      params: [address, isAllowed],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function addPriceFeed(address: `0x${string}`, feed: `0x${string}`) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "addPriceFeed",
      params: [address, feed],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function withdraw(token: `0x${string}`) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "withdraw",
      params: [token],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function authorizeBreeder(breeder: `0x${string}`) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "authorizeBreeder",
      params: [breeder],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function setRemoteBridge(chainId: bigint, bridge: `0x${string}`) {
    if (!contract) throw new Error("Contract not initialized");
    const prepared = await prepareContractCall({
      contract,
      method: "setRemoteBridge",
      params: [chainId, bridge],
    });
    return sendTransaction({
      account: account!,
      transaction: prepared,
    }) as Promise<PreparedTransaction>;
  }

  async function balanceOfERC20(
    token: `0x${string}`,
    chain: any
  ): Promise<bigint> {
    if (!address) throw new Error("BeanHeads contract address not resolved");
    const erc20 = getContract({
      client,
      chain,
      address: token,
      abi: ERC20ABI as any,
    });

    const bal = await readContract({
      contract: erc20,
      method: "balanceOf",
      params: [address],
    });

    return bal as bigint;
  }

  const value: BeanHeadsCtx = {
    chainId: chain?.id,
    address,
    contract,
    totalSupply,
    balanceOf,
    mintGenesis,
    mintBridgeGenesis,
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
    getPriceFeed,
    getGeneration,
    getOwnerTokens,
    getAuthorizedBreeders,
    sellToken,
    batchSellTokens,
    buyToken,
    batchBuyTokens,
    cancelTokenSale,
    batchCancelTokenSales,
    getTokenSalePrice,
    isTokenForSale,
    getTokenSaleInfo,
    ready,
    getAllActiveSaleTokens,
    setMintPrice,
    setAllowedToken,
    addPriceFeed,
    withdraw,
    authorizeBreeder,
    setRemoteBridge,
    balanceOfERC20,
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
