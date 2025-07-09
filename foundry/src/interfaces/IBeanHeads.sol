// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Genesis} from "src/types/Genesis.sol";

interface IBeanHeads {
    error IBeanHeads__TokenDoesNotExist();
    error IBeanHeads__NotOwner();
    error IBeanHeads__WithdrawFailed();
    error IBeanHeads__InvalidRoyaltyFee();
    error IBeanHeads__PriceMustBeGreaterThanZero();
    error IBeanHeads__PriceMismatch();
    error IBeanHeads__TokenIsNotForSale();
    error IBeanHeads__RoyaltyPaymentFailed(uint256 tokenId);
    error IBeanHeads__InsufficientPayment();
    error IBeanHeads__InvalidAmount();
    error IBeanHeads__InvalidAttributesArray();
    error IBeanHeads__InvalidRequestId();
    error IBeanHeads__UnauthorizedBreeders();
    error IBeanHeads__NotParentGeneration();

    event MintedGenesis(address indexed owner, uint256 indexed tokenId);
    event TokenWithdrawn(address indexed owner, uint256 amount);
    event SetTokenPrice(address indexed owner, uint256 indexed tokenId, uint256 price);
    event RoyaltyPaid(address indexed receiver, uint256 indexed tokenId, uint256 salePrice, uint256 royaltyAmount);
    event RoyaltyInfoUpdated(address indexed receiver, uint256 feeBps);
    event TokenSaleCancelled(address indexed owner, uint256 indexed tokenId);
    event TokenSold(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 salePrice);
    event MintedNewBreed(address indexed owner, uint256 indexed tokenId);

    function mintGenesis(address to, Genesis.SVGParams memory params, uint256 amount)
        external
        payable
        returns (uint256);

    function getAttributes(uint256 tokenId) external view returns (string memory);

    function getOwnerTokens(address owner) external view returns (uint256[] memory);

    function getOwnerTokensCount(address owner) external view returns (uint256);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function getAttributesByTokenId(uint256 tokenId) external view returns (Genesis.SVGParams memory);

    function getAttributesByOwner(address owner, uint256 tokenId) external view returns (Genesis.SVGParams memory);

    function sellToken(uint256 tokenId, uint256 price) external;

    function buyToken(uint256 tokenId, uint256 price) external payable;

    function cancelTokenSale(uint256 tokenId) external;

    function withdraw() external;

    function getMintPrice() external view returns (uint256);

    function getGeneration(uint256 tokenId) external view returns (uint256);

    function mintFromBreeders(address to, Genesis.SVGParams memory params, uint256 generation)
        external
        payable
        returns (uint256);

    function getAuthorizedBreeders(address owner) external view returns (bool);

    /// @notice Produces the URI describing the metadata of the token ID
    /// @dev Note this URI may be a data: URI with JSON contents directly inlined

    /// @param tokenID The ID of the token for which to produce the metadata
    /// @return the URI of the ERC721 compliant metadata
    function tokenURI(uint256 tokenID) external view returns (string memory);
}
