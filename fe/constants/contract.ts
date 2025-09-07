import { sepolia, arbitrumSepolia, optimismSepolia } from "thirdweb/chains";

export const BEANHEADS_ADDRESS: Record<number, `0x${string}`> = {
  [sepolia.id]: "0x717ad726c9F7e659C037518Dd11Be16DF8099F52",
  [arbitrumSepolia.id]: "0x7A88F9f7bfb29cF50854f83394fcc02D82B16b16",
  [optimismSepolia.id]: "0xbe42BBB87D5827c875ECFe274d13D176Cdb42E75",
};

export const USDC_ADDRESS: Record<number, `0x${string}`> = {
  [sepolia.id]: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
  [arbitrumSepolia.id]: "0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d",
  [optimismSepolia.id]: "0x5fd84259d66Cd46123540766Be93DFE6D43130D7",
};

export const LINK_ADDRESS: Record<number, `0x${string}`> = {
  [sepolia.id]: "0x779877A7B0D9E8603169DdbD7836e478b4624789",
  [arbitrumSepolia.id]: "0xb1D4538B4571d411F07960EF2838Ce337FE1E80E",
  [optimismSepolia.id]: "0x5fd84259d66Cd46123540766Be93DFE6D43130D7",
};
