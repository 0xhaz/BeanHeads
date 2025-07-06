// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "ERC721A/extensions/ERC721AQueryable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title BeanHeads
 * @notice BeanHeads is a customizable avatar on chain NFT collection
 * @dev Uses breeding concept to create new avatars similar to Cryptokitties
 * @dev Uses Chainlink VRF for attributes randomness
 */
contract BeanHeads is ERC721AQueryable, Ownable, IBeanHeads, IERC2981 {
    using Base64 for bytes;
    using Strings for uint256;

    /// @notice Royalty information
    uint96 private royaltyFeeBps;
    address private royaltyReceiver;
    uint96 private constant MAX_BPS = 10000;

    /// @notice Mapping tokenId to its SVG parameters
    mapping(uint256 => Genesis.SVGParams) private s_tokenIdToParams;

    /// @notice Mapping tokenId to custom token URI
    mapping(uint256 tokenId => string uriToken) private s_customTokenURIs;

    /// @notice Mapping tokenId that set to sale with price
    mapping(uint256 tokenId => mapping(uint256 price => bool)) private s_tokenIdToSalePrice;

    /// @notice Mapping tokenId to its sale price
    mapping(uint256 tokenId => uint256 price) private s_tokenIdToSalePriceValue;

    /// @notice Mapping tokenId to the contract owner (seller)
    mapping(uint256 tokenId => address owner) private s_tokenIdToSeller;

    /**
     * @dev Initializes the contract with default royalty settings
     * @param initialOwner The address to own the contract
     */
    constructor(address initialOwner) ERC721A("BeanHeads", "BEAN") Ownable(initialOwner) {
        royaltyFeeBps = 500; // 5% royalty fee
        royaltyReceiver = initialOwner; // Set initial royalty receiver to the contract owner
    }

    /**
     * @notice Mints a new Genesis NFT with the provided SVG parameters
     * @param params The struct containing SVG configuration parameters
     * @return tokenId The ID of the newly minted token
     */
    function mintGenesis(Genesis.SVGParams memory params) public returns (uint256 tokenId) {
        tokenId = _nextTokenId();
        s_tokenIdToParams[tokenId] = params;
        _safeMint(msg.sender, 1);
        s_tokenIdToSalePriceValue[tokenId] = 0; // Initialize sale price to 0
        s_tokenIdToSalePrice[tokenId][0] = false; // Initialize sale price mapping

        emit MintedGenesis(msg.sender, tokenId);
    }

    /**
     * @notice Sets the royalty fee and receiver
     * @param feeBps The royalty fee in basis points (1% = 100 BPS)
     */
    function setRoyaltyInfo(uint96 feeBps) external onlyOwner {
        if (feeBps >= MAX_BPS) revert IBeanHeads__InvalidRoyaltyFee();

        royaltyFeeBps = feeBps;

        emit RoyaltyInfoUpdated(royaltyReceiver, feeBps);
    }

    /**
     * @notice Sell token with custom price
     * @param tokenId The ID of the token to sell
     * @param price The price at which to sell the token
     */
    function sellToken(uint256 tokenId, uint256 price) public override {
        if (msg.sender != ownerOf(tokenId)) revert IBeanHeads__NotOwner();
        if (price <= 0) revert IBeanHeads__PriceMustBeGreaterThanZero();
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();

        safeTransferFrom(msg.sender, address(this), tokenId);

        s_tokenIdToSalePriceValue[tokenId] = price;
        s_tokenIdToSalePrice[tokenId][price] = true;
        s_tokenIdToSeller[tokenId] = msg.sender; // Store the seller address

        emit SetTokenPrice(msg.sender, tokenId, price);
    }

    /**
     * @notice Buy a token that is on sale
     * @param tokenId The ID of the token to buy
     * @param price The price at which to buy the token
     * @dev Royalties will be paid to the royalty receiver
     */
    function buyToken(uint256 tokenId, uint256 price) public payable override {
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        if (!s_tokenIdToSalePrice[tokenId][price]) revert IBeanHeads__TokenIsNotForSale();
        if (msg.value < price) revert IBeanHeads__PriceMustBeGreaterThanZero();
        if (s_tokenIdToSalePriceValue[tokenId] != price) revert IBeanHeads__PriceMismatch();

        address seller = s_tokenIdToSeller[tokenId];

        // Reset sale price
        s_tokenIdToSalePriceValue[tokenId] = 0;
        s_tokenIdToSalePrice[tokenId][price] = false;
        delete s_tokenIdToSeller[tokenId]; // Clear seller address

        // Pay royalties
        uint256 royaltyAmount = (price * royaltyFeeBps) / MAX_BPS;
        (bool success,) = royaltyReceiver.call{value: royaltyAmount}("");
        if (!success) revert IBeanHeads__RoyaltyPaymentFailed(tokenId);

        // Transfer remaining amount to seller
        (success,) = seller.call{value: price - royaltyAmount}("");
        if (!success) revert IBeanHeads__WithdrawFailed();

        IERC721A(address(this)).transferFrom(address(this), msg.sender, tokenId);

        emit RoyaltyPaid(royaltyReceiver, tokenId, price, royaltyAmount);
    }

    /**
     * @notice Cancels the sale of a token
     * @param tokenId The ID of the token to cancel sale for
     * @dev Resets the sale price and seller address
     */
    function cancelTokenSale(uint256 tokenId) public override {
        if (msg.sender != s_tokenIdToSeller[tokenId]) revert IBeanHeads__NotOwner();
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        if (!s_tokenIdToSalePrice[tokenId][s_tokenIdToSalePriceValue[tokenId]]) revert IBeanHeads__TokenIsNotForSale();

        IERC721A(address(this)).transferFrom(address(this), msg.sender, tokenId);

        // Reset sale price
        s_tokenIdToSalePriceValue[tokenId] = 0;
        s_tokenIdToSalePrice[tokenId][s_tokenIdToSalePriceValue[tokenId]] = false;
        delete s_tokenIdToSeller[tokenId]; // Clear seller address

        emit TokenSaleCancelled(msg.sender, tokenId);
    }

    /**
     * @notice Returns the royalty information for a sale
     * @param tokenId The token ID
     * @param salePrice The sale price of the token
     * @return receiver The address that will receive the royalty
     * @return royaltyAmount The amount of royalty to be paid
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        onlyOwner
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }
        receiver = royaltyReceiver;
        royaltyAmount = (salePrice * royaltyFeeBps) / MAX_BPS;
    }

    /**
     * @notice Retrieves all token IDs owned by a specific address
     * @param owner The address of the token owner
     * @return tokenIds An array of token IDs owned by the specified address
     */
    function getOwnerTokens(address owner) external view returns (uint256[] memory) {
        return this.tokensOfOwner(owner);
    }

    /**
     * @notice Returns the number of tokens owned by the specified address.
     * @param owner Address to query.
     */
    function getOwnerTokensCount(address owner) external view returns (uint256) {
        return balanceOf(owner);
    }

    /**
     * @notice Returns the owner of a given token ID.
     * @param tokenId Token ID to query.
     */
    function getOwnerOf(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    /**
     * @notice Retrieves the stored SVG parameters for a token ID.
     * @param tokenId The token ID.
     * @return params The SVG parameters struct.
     */
    function getAttributesByTokenId(uint256 tokenId) external view returns (Genesis.SVGParams memory params) {
        params = s_tokenIdToParams[tokenId];
    }

    /**
     * @notice Retrieves the stored SVG parameters for a token ID, checking caller ownership.
     * @param owner Address expected to own the token.
     * @param tokenId The token ID.
     * @return params The SVG parameters struct.
     */
    function getAttributesByOwner(address owner, uint256 tokenId)
        external
        view
        returns (Genesis.SVGParams memory params)
    {
        if (owner != _msgSender()) revert IBeanHeads__NotOwner();
        if (ownerOf(tokenId) != owner) revert IBeanHeads__NotOwner();
        params = s_tokenIdToParams[tokenId];
    }

    /**
     * @notice Returns the metadata URI for a token.
     * @param tokenId Token ID to query.
     * @return Metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A, IBeanHeads) returns (string memory) {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }

        // Use custom URI if set
        if (bytes(s_customTokenURIs[tokenId]).length > 0) {
            return s_customTokenURIs[tokenId];
        }

        // Fetch token parameters
        Genesis.SVGParams memory params = s_tokenIdToParams[tokenId];
        // Build attributes and image
        string memory attributes = Genesis.buildAttributes(params);
        string memory image = Genesis.generateBase64SVG(params);

        // Generate metadata JSON
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "BeanHeads #',
                tokenId.toString(),
                '", "description": "BeanHeads is a customizable avatar on chain NFT collection", "image": "',
                image,
                '", "attributes":',
                attributes,
                "}"
            )
        );

        // Return metadata as base64 encoded JSON.
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
    }

    /**
     * @notice Returns the attributes of a token as a JSON string.
     * @param tokenId The ID of the token to query.
     * @return A JSON string containing the attributes of the token.
     */
    function getAttributes(uint256 tokenId) external view override returns (string memory) {
        return Genesis.buildAttributes(s_tokenIdToParams[tokenId]);
    }

    /**
     * @notice Checks if a token is on sale at a specific price.
     * @param tokenId The ID of the token to check.
     * @param price The price to check against.
     * @return True if the token is on sale at the specified price, false otherwise.
     */
    function getTokenOnSale(uint256 tokenId, uint256 price) external view returns (bool) {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }
        return s_tokenIdToSalePrice[tokenId][price];
    }

    /**
     * @notice Returns the sale price of a token.
     * @param tokenId The ID of the token to query.
     * @return The sale price of the token.
     */
    function getTokenSalePrice(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }
        return s_tokenIdToSalePriceValue[tokenId];
    }

    /**
     * @notice Supports interface detection.
     * @param interfaceId The interface identifier.
     * @return True if supported.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector; // Return the selector for ERC721Received
    }
}
