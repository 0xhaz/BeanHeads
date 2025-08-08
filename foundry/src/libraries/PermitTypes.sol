// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {BHStorage} from "src/libraries/BHStorage.sol";

library PermitTypes {
    struct Sell {
        address owner;
        uint256 tokenId;
        uint256 price;
        uint256 nonce;
        uint64 deadline;
    }

    bytes32 internal constant SELL_TYPEHASH =
        keccak256("sellToken(address owner,uint256 tokenId,uint256 price,uint256 nonce,uint64 deadline)");

    struct Buy {
        address buyer;
        address paymentToken;
        address recipient;
        uint256 tokenId;
        uint256 maxPriceUsd;
        uint256 listingNonce;
        uint64 deadline;
    }

    bytes32 internal constant BUY_TYPEHASH = keccak256(
        "buyToken(address buyer,address paymentToken,address recipient,uint256 tokenId,uint256 maxPriceUsd,uint256 listingNonce,uint64 deadline)"
    );

    struct Cancel {
        address seller;
        uint256 tokenId;
        uint256 listingNonce;
        uint64 deadline;
    }

    bytes32 internal constant CANCEL_TYPEHASH =
        keccak256("cancelTokenSale(address seller,uint256 tokenId,uint256 listingNonce,uint64 deadline)");
}
