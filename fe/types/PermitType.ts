import { keccak256, stringToBytes } from "thirdweb";

export namespace PermitTypes {
  export interface Sell {
    owner: `0x${string}`;
    tokenId: bigint;
    price: bigint;
    nonce: bigint;
    deadline: bigint;
  }

  export interface Buy {
    buyer: `0x${string}`;
    paymentToken: `0x${string}`;
    recipient: `0x${string}`;
    tokenId: bigint;
    maxPriceUsd: bigint;
    listingNonce: bigint;
    deadline: bigint;
  }

  export interface BuyLocals {
    priceUsd: bigint;
    adjustedPrice: bigint;
    royaltyReceiver: `0x${string}`;
    royaltyUsd: bigint;
    royaltyAmount: bigint;
    sellerAmount: bigint;
  }

  export interface Cancel {
    seller: `0x${string}`;
    tokenId: bigint;
    listingNonce: bigint;
    deadline: bigint;
  }

  export const SELL_TYPE = [
    { name: "owner", type: "address" },
    { name: "tokenId", type: "uint256" },
    { name: "price", type: "uint256" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint64" },
  ] as const;

  export const BUY_TYPE = [
    { name: "buyer", type: "address" },
    { name: "paymentToken", type: "address" },
    { name: "recipient", type: "address" },
    { name: "tokenId", type: "uint256" },
    { name: "maxPriceUsd", type: "uint256" },
    { name: "listingNonce", type: "uint256" },
    { name: "deadline", type: "uint64" },
  ] as const;

  export const CANCEL_TYPE = [
    { name: "seller", type: "address" },
    { name: "tokenId", type: "uint256" },
    { name: "listingNonce", type: "uint256" },
    { name: "deadline", type: "uint64" },
  ] as const;

  export const SELL_TYPEHASH = keccak256(
    stringToBytes(
      "sellToken(address owner,uint256 tokenId,uint256 price,uint256 nonce,uint64 deadline)"
    )
  );

  export const BUY_TYPEHASH = keccak256(
    stringToBytes(
      "buyToken(address buyer,address paymentToken,address recipient,uint256 tokenId,uint256 maxPriceUsd,uint256 listingNonce,uint64 deadline)"
    )
  );

  export const CANCEL_TYPEHASH = keccak256(
    stringToBytes(
      "cancelToken(address seller,uint256 tokenId,uint256 listingNonce,uint64 deadline)"
    )
  );
}
