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
import { PRICE_FEED_ADDRESS } from "@/constants/contract";
import { client } from "@/provider/client";
import AggregatorV3InterfaceABI from "@/app/contracts/AggregatorV3Interface.json";
import type { Abi } from "viem";

const PriceFeedABI = AggregatorV3InterfaceABI.abi as Abi;

type PriceContextValue = {
  priceContract: `0x${string}` | null;
  provider: typeof client | null;
  getUSDPrice: () => Promise<number> | undefined;
};

type PriceProviderProps = {
  children: React.ReactNode;
};

const Ctx = createContext<PriceContextValue | null>(null);
