import { sepolia, arbitrumSepolia, optimismSepolia } from "thirdweb/chains";
import {
  BeanHeads,
  USDC,
  LINK,
  AggregatatorV3Interface,
  Breeder,
  Bridge,
  ChainSelector,
} from "@/app/contracts/BeanHeads-address.json";

export const BEANHEADS_ADDRESS: Record<number, `0x${string}`> = {
  [sepolia.id]: BeanHeads.sepolia as `0x${string}`,
  [arbitrumSepolia.id]: BeanHeads.arbitrumSepolia as `0x${string}`,
  [optimismSepolia.id]: BeanHeads.optimismSepolia as `0x${string}`,
};

export const USDC_ADDRESS: Record<number, `0x${string}`> = {
  [sepolia.id]: USDC.sepolia as `0x${string}`,
  [arbitrumSepolia.id]: USDC.arbitrumSepolia as `0x${string}`,
  [optimismSepolia.id]: USDC.optimismSepolia as `0x${string}`,
};

export const LINK_ADDRESS: Record<number, `0x${string}`> = {
  [sepolia.id]: LINK.sepolia as `0x${string}`,
  [arbitrumSepolia.id]: LINK.arbitrumSepolia as `0x${string}`,
  [optimismSepolia.id]: LINK.optimismSepolia as `0x${string}`,
};

export const PRICE_FEED_ADDRESS: Record<number, `0x${string}`> = {
  [sepolia.id]: AggregatatorV3Interface.sepolia as `0x${string}`,
  [arbitrumSepolia.id]:
    AggregatatorV3Interface.arbitrumSepolia as `0x${string}`,
  [optimismSepolia.id]:
    AggregatatorV3Interface.optimismSepolia as `0x${string}`,
};

export const BREEDER_ADDRESS: Record<number, `0x${string}`> = {
  [sepolia.id]: Breeder.sepolia as `0x${string}`,
  [arbitrumSepolia.id]: Breeder.arbitrumSepolia as `0x${string}`,
  [optimismSepolia.id]: Breeder.optimismSepolia as `0x${string}`,
};

export const BRIDGE_ADDRESS: Record<number, `0x${string}`> = {
  [arbitrumSepolia.id]: Bridge.arbitrumSepolia as `0x${string}`,
  [optimismSepolia.id]: Bridge.optimismSepolia as `0x${string}`,
};

export const CHAIN_SELECTOR: Record<number, bigint> = {
  [sepolia.id]: BigInt(ChainSelector.sepolia),
  [arbitrumSepolia.id]: BigInt(ChainSelector.arbitrumSepolia),
  [optimismSepolia.id]: BigInt(ChainSelector.optimismSepolia),
};
