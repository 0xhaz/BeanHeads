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
  BRIDGE_ADDRESS,
  USDC_ADDRESS,
  LINK_ADDRESS,
  BEANHEADS_ADDRESS,
} from "@/constants/contract";
import { client } from "@/provider/client";
import bridge from "@/app/contracts/BeanHeadsBridge.json";
import ERC20 from "@/app/contracts/ERC20.json";
import { BeanHeadsABI } from "./beanheads";
import { generateRandomAvatarAttributes } from "@/components/Avatar";
import { toSVGParamsFromAvatar } from "@/utils/encode";
import { PermitTypes } from "@/types/PermitType";

const BridgeABI = bridge.abi as Abi;
const ERC20ABI = ERC20 as Abi;

type BridgeCtx = {
  chainId?: number;
  address?: `0x${string}`;
  contract?: ReturnType<typeof getContract> | null;
  nftContract?: ReturnType<typeof getContract> | null;
  sendMintTokenRequest: (
    destChainId: bigint,
    to: `0x${string}`,
    avatarParams: ReturnType<typeof generateRandomAvatarAttributes>,
    amount: bigint,
    paymentToken: `0x${string}` | null
  ) => Promise<PreparedTransaction>;
  sendSellTokenRequest: (
    destChainId: bigint,
    sell: PermitTypes.Sell,
    permitDeadline: bigint,
    permitSig: `0x${string}`
  ) => Promise<PreparedTransaction>;
  sendBatchSellTokenRequest: (
    destChainId: bigint,
    sells: PermitTypes.Sell[],
    permitDeadline: bigint,
    permitSig: `0x${string}`
  ) => Promise<PreparedTransaction>;
  sendBuyTokenRequest: (
    destChainId: bigint,
    tokenId: bigint,
    paymentToken: `0x${string}`,
    price: bigint
  ) => Promise<PreparedTransaction>;
  sendBatchBuyTokenRequest: (
    destChainId: bigint,
    tokenIds: bigint[],
    prices: bigint[],
    paymentToken: `0x${string}`
  ) => Promise<PreparedTransaction>;
  sendTransferTokenRequest: (
    destChainId: bigint,
    tokenId: bigint,
    to: `0x${string}`
  ) => Promise<PreparedTransaction>;
  setRemoteBridge: (address: `0x${string}`) => Promise<PreparedTransaction>;
  depositLink: (amount: bigint) => Promise<PreparedTransaction>;
  withdrawLink: (amount: bigint) => Promise<PreparedTransaction>;
};

const Ctx = createContext<BridgeCtx | null>(null);

export function BridgeProvider({ children }: { children: React.ReactNode }) {
  const account = useActiveAccount();
  const chain = useActiveWalletChain();

  const address = chain ? BRIDGE_ADDRESS[chain.id] : undefined;

  const contract = useMemo(() => {
    if (!chain || !address) return undefined;

    return getContract({
      client,
      chain: chain!,
      address,
      abi: BridgeABI as any,
    });
  }, [chain, address]);

  const nftContract = useMemo(() => {
    if (!chain) return undefined;
    const addr = BEANHEADS_ADDRESS[chain.id];
    if (!addr) return undefined;
    return getContract({
      client,
      chain: chain!,
      address: addr,
      abi: BeanHeadsABI as any,
    });
  }, [chain]);

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

  async function getMintPrice() {
    if (!contract) throw new Error("Contract not initialized");
    try {
      const price = await readContract({
        contract: nftContract!,
        method: "getMintPrice",
      });
      return price as bigint;
    } catch (error) {
      console.error("Error fetching mint price:", error);
    }
  }

  async function sendMintTokenRequest(
    destChainId: bigint,
    to: `0x${string}`,
    avatarParams: ReturnType<typeof generateRandomAvatarAttributes>,
    amount: bigint,
    paymentToken: `0x${string}` | null
  ) {
    if (!contract) throw new Error("Bridge contract not available");

    const svgParams = toSVGParamsFromAvatar(avatarParams);

    if (paymentToken) {
      const priceUsd18 = await getMintPrice();
      const totalPrice = (priceUsd18 ?? BigInt(0)) * amount;
      await approveToken(
        account!.address as `0x${string}`,
        contract.address as `0x${string}`,
        totalPrice,
        chain!
      );
    }

    const tx = await prepareContractCall({
      contract,
      method: "requestMintToken",
      params: [
        destChainId,
        to,
        svgParams as any,
        amount,
        paymentToken ?? USDC_ADDRESS[chain!.id],
      ],
      value: paymentToken ? BigInt(0) : amount,
    });

    return sendTransaction({
      account: account!,
      transaction: tx,
    });
  }

  function buildDomain(params: {
    chainId: bigint;
    verifyingContract: `0x${string}`;
    name?: string;
    version?: string;
  }) {
    const {
      chainId,
      verifyingContract,
      name = "BeanHeadsBridge",
      version = "1",
    } = params;

    return {
      name,
      version,
      chainId,
      verifyingContract,
    } as const;
  }

  async function sendSellTokenRequest(
    destChainId: bigint,
    sell: PermitTypes.Sell,
    permitDeadline: bigint,
    permitSig: `0x${string}`
  ) {
    if (!contract) throw new Error("Bridge contract not available");
    if (!account) throw new Error("Wallet not connected");
    if (!chain) throw new Error("Chain not available");

    const domain = buildDomain({
      chainId: BigInt(chain.id),
      verifyingContract: contract.address as `0x${string}`,
    });

    const sellSig = await account.signTypedData({
      domain,
      types: { sellToken: PermitTypes.SELL_TYPE },
      primaryType: "sellToken",
      message: sell,
    });

    const tx = await prepareContractCall({
      contract,
      method: "sendSellTokenRequest",
      params: [
        destChainId,
        sell,
        sellSig as `0x${string}`,
        permitDeadline,
        permitSig,
      ],
    });

    return sendTransaction({
      account: account!,
      transaction: tx,
    });
  }

  async function sendBatchSellTokenRequest(
    destChainId: bigint,
    sells: PermitTypes.Sell[],
    permitDeadline: bigint,
    permitSig: `0x${string}`
  ) {
    if (!contract) throw new Error("Bridge contract not available");
    if (!account) throw new Error("Wallet not connected");
    if (!chain) throw new Error("Chain not available");

    const domain = buildDomain({
      chainId: BigInt(chain.id),
      verifyingContract: contract.address as `0x${string}`,
    });

    const sellSigs = await Promise.all(
      sells.map(sell =>
        account.signTypedData({
          domain,
          types: { sellToken: PermitTypes.SELL_TYPE },
          primaryType: "sellToken",
          message: sell,
        })
      )
    );

    const tx = await prepareContractCall({
      contract,
      method: "sendBatchSellTokenRequest",
      params: [
        destChainId,
        sells,
        sellSigs as `0x${string}`[],
        permitDeadline,
        permitSig,
      ],
    });

    return sendTransaction({
      account: account!,
      transaction: tx,
    });
  }

  async function sendBuyTokenRequest(
    destChainId: bigint,
    tokenId: bigint,
    paymentToken: `0x${string}`,
    price: bigint
  ) {
    if (!contract) throw new Error("Bridge contract not available");

    const tx = await prepareContractCall({
      contract,
      method: "sendBuyTokenRequest",
      params: [destChainId, tokenId, paymentToken, price],
    });

    return sendTransaction({
      account: account!,
      transaction: tx,
    });
  }

  async function sendBatchBuyTokenRequest(
    destChainId: bigint,
    tokenIds: bigint[],
    prices: bigint[],
    paymentToken: `0x${string}`
  ) {
    if (!contract) throw new Error("Bridge contract not available");

    const tx = await prepareContractCall({
      contract,
      method: "sendBatchBuyTokenRequest",
      params: [destChainId, tokenIds, paymentToken, prices],
    });

    return sendTransaction({
      account: account!,
      transaction: tx,
    });
  }

  async function sendTransferTokenRequest(
    destChainId: bigint,
    tokenId: bigint,
    to: `0x${string}`
  ) {
    if (!contract) throw new Error("Bridge contract not available");

    const tx = await prepareContractCall({
      contract,
      method: "sendTransferTokenRequest",
      params: [destChainId, tokenId, to],
    });

    return sendTransaction({
      account: account!,
      transaction: tx,
    });
  }

  async function setRemoteBridge(address: `0x${string}`) {
    if (!contract) throw new Error("Bridge contract not available");

    const tx = await prepareContractCall({
      contract,
      method: "setRemoteBridge",
      params: [address],
    });

    return sendTransaction({
      account: account!,
      transaction: tx,
    });
  }

  async function depositLink(amount: bigint) {
    if (!contract) throw new Error("Bridge contract not available");
    if (!chain) throw new Error("Chain not available");

    const link = getContract({
      client,
      chain,
      address: LINK_ADDRESS[chain.id],
      abi: ERC20ABI as any,
    });

    const allowance = (await readContract({
      contract: link,
      method: "allowance",
      params: [
        account!.address as `0x${string}`,
        contract.address as `0x${string}`,
      ],
    })) as bigint;

    if (allowance < amount) {
      const approveTx = await prepareContractCall({
        contract: link,
        method: "approve",
        params: [contract.address as `0x${string}`, amount],
      });

      const approveResult = await sendTransaction({
        account: account!,
        transaction: approveTx,
      });
      await waitForReceipt(approveResult);
    }

    const tx = await prepareContractCall({
      contract,
      method: "depositLink",
      params: [amount],
    });

    return sendTransaction({
      account: account!,
      transaction: tx,
    });
  }

  async function withdrawLink(amount: bigint) {
    if (!contract) throw new Error("Bridge contract not available");

    const tx = await prepareContractCall({
      contract,
      method: "withdrawLink",
      params: [amount],
    });

    return sendTransaction({
      account: account!,
      transaction: tx,
    });
  }

  const value: BridgeCtx = {
    chainId: chain?.id,
    address,
    contract,
    nftContract,
    sendMintTokenRequest,
    sendSellTokenRequest,
    sendBatchSellTokenRequest,
    sendBuyTokenRequest,
    sendBatchBuyTokenRequest,
    sendTransferTokenRequest,
    setRemoteBridge,
    depositLink,
    withdrawLink,
  };

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useBridge() {
  const ctx = useContext(Ctx);
  if (!ctx) {
    throw new Error("useBridge must be used within a BridgeProvider");
  }
  return ctx;
}
