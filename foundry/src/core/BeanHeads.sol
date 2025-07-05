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

    /**
     * @dev Initializes the contract with default royalty settings
     * @param initialOwner The address to own the contract
     */
    constructor(address initialOwner) ERC721A("BeanHeads", "BEAN") Ownable(initialOwner) {
        royaltyFeeBps = 500; // 5% royalty fee
        royaltyReceiver = msg.sender;
    }

    /**
     * @notice Mints a new Genesis NFT with the provided SVG parameters
     * @param params The struct containing SVG configuration parameters
     * @return tokenId The ID of the newly minted token
     */
    function mintGenesis(Genesis.SVGParams memory params) public returns (uint256 tokenId) {
        tokenId = _nextTokenId();
        s_tokenIdToParams[tokenId] = params;
        _mint(msg.sender, 1);

        emit MintedGenesis(msg.sender, tokenId);
    }

    /**
     * @notice Sets the royalty fee and receiver
     * @param receiver The address that will receive the royalties
     * @param feeBps The royalty fee in basis points (1% = 100 BPS)
     */
    function setRoyaltyInfo(address receiver, uint96 feeBps) external onlyOwner {
        if (feeBps >= MAX_BPS) revert IBeanHeads__InvalidRoyaltyFee();
        royaltyReceiver = receiver;
        royaltyFeeBps = feeBps;
    }

    /**
     * @notice Returns the royalty information for a sale
     * @param tokenId The token ID
     * @param salePrice The sale price of the token
     * @return receiver The address that will receive the royalty
     * @return royaltyAmount The amount of royalty to be paid
     */
    function getRoyaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
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
     * @notice Returns as JSON array of attributes for a token
     * @param tokenId Token ID to query
     * @return JSON string with attributes
     */
    function getAttributesAsJson(uint256 tokenId) external view returns (string memory) {
        // return Genesis.buildAttributes(s_tokenIdToParams[tokenId]);
    }

    /**
     * @notice Withdraws the contract's balance to the owner's address
     *
     */
    function withdrawToken() external override {
        if (msg.sender != owner()) revert IBeanHeads__NotOwner();
        uint256 amount = address(this).balance;
        (bool success,) = owner().call{value: amount}("");
        if (!success) revert IBeanHeads__WithdrawFailed();

        emit Withdrawn(owner(), address(this).balance);
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
     * @notice Sets a custom metadata URI for a token.
     * @param tokenId Token ID to override.
     * @param uri Custom URI string.
     */
    function setTokenURI(uint256 tokenId, string memory uri) public {
        s_customTokenURIs[tokenId] = uri;
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

    /**
     * @notice Returns royalty information for a token sale.
     * @param tokenId The token ID (not used in this implementation, but required by the standard).
     * @param salePrice The sale price of the token.
     * @return receiver The royalty receiver address.
     * @return royaltyAmount The royalty amount to be paid.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        receiver = royaltyReceiver;
        royaltyAmount = (salePrice * royaltyFeeBps) / MAX_BPS;
    }

    function getAttributes(uint256 tokenId) external view override returns (string memory) {
        return Genesis.buildAttributes(s_tokenIdToParams[tokenId]);
    }

    function getOwnerTokensCount() external view override returns (uint256) {
        return balanceOf(_msgSender());
    }
}
