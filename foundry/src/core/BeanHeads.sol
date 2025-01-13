// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ERC721AQueryable, ERC721A, IERC721A} from "ERC721A/extensions/ERC721AQueryable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {Errors, Events} from "src/types/Constants.sol";
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

    uint256 private tokenIdCounter;
    uint96 private royaltyFeeBps;
    address private royaltyReceiver;
    uint96 private constant MAX_BPS = 10000;

    mapping(uint256 => Genesis.SVGParams) private _tokenIdToParams;
    mapping(address => uint256[]) private _ownerToTokens;
    mapping(uint256 => string) private _customTokenURIs;

    constructor() ERC721A("BeanHeads", "BEAN") Ownable(msg.sender) {
        royaltyFeeBps = 500; // 5% royalty
        royaltyReceiver = msg.sender;
    }

    function mintGenesis(Genesis.SVGParams memory params) public returns (uint256) {
        tokenIdCounter++;
        _tokenIdToParams[tokenIdCounter] = params;
        _mint(msg.sender, 1);
        _ownerToTokens[msg.sender].push(tokenIdCounter);

        emit Events.MintedGenesis(msg.sender, tokenIdCounter);
        return tokenIdCounter;
    }

    function getOwnerAttributes(address owner) external view returns (string[20][] memory) {}

    function getOwnerTokens(address owner) external view returns (uint256[] memory) {
        return _ownerToTokens[owner];
    }

    function getOwnerTokensCount(address owner) external view returns (uint256) {
        uint256 tokenCount = balanceOf(owner);
        return tokenCount;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function getOwnerTokensCount() external view returns (uint256) {
        return balanceOf(_msgSender());
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function getOwnerOf(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    function getAttributesCount() external view returns (uint256) {}

    function getAttributesByIndex(uint256 index) external view returns (string[20] memory) {}

    function getAttributesByTokenId(uint256 tokenId) external view returns (Genesis.SVGParams memory params) {
        params = _tokenIdToParams[tokenId];
    }

    function getAttributesByOwner(address owner, uint256 tokenId)
        external
        view
        returns (Genesis.SVGParams memory params)
    {
        if (owner != _msgSender()) revert Errors.NotOwner();
        params = _tokenIdToParams[tokenId];
    }

    function getAttributes(uint256 tokenId) external view override returns (string memory) {}

    function randomNum(uint256 mod, uint256 seed, uint256 salt) external view override returns (uint256) {}

    function withdraw() external override {
        if (msg.sender != owner()) revert Errors.NotOwner();

        (bool success,) = owner().call{value: address(this).balance}("");
        if (!success) revert Errors.WithdrawFailed();

        emit Events.Withdrawn(owner(), address(this).balance);
    }

    function tokenURI(uint256 tokenID) public view override(IERC721A, ERC721A, IBeanHeads) returns (string memory) {
        // Fetch token parameters
        Genesis.SVGParams memory params = _tokenIdToParams[tokenID];

        // Build attributes and image
        string memory attributes = Genesis.buildAttributes(params);
        string memory image = Genesis.generateBase64SVG(params);

        // Generate metadata JSON
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "BeanHeads #',
                tokenID.toString(),
                '", "description": "BeanHeads is a customizable avatar on chain NFT collection", "image": "',
                image,
                '", "attributes":',
                attributes,
                "}"
            )
        );

        // Return metadata as base64 encoded JSON
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
    }

    function setTokenURI(uint256 tokenId, string memory uri) public {
        _customTokenURIs[tokenId] = uri;
    }

    function getAttributesAsJson(uint256 tokenId) external view returns (string memory) {
        return Genesis.buildAttributes(_tokenIdToParams[tokenId]);
    }

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
        receiver = royaltyReceiver;
        royaltyAmount = (salePrice * royaltyFeeBps) / MAX_BPS;
    }
}
