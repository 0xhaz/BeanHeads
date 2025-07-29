// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {BHStorage} from "src/libraries/BHStorage.sol";
import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {Genesis} from "src/types/Genesis.sol";
import {RenderLib} from "src/libraries/RenderLib.sol";
import {IBeanHeadsView} from "src/interfaces/IBeanHeadsView.sol";

contract BeanHeadsViewFacet is ERC721AUpgradeable, IBeanHeadsView {
    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Modifier to check if the token exists
    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            _revert(IBeanHeadsView__TokenDoesNotExist.selector);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IBeanHeadsView
    function tokenURI(uint256 _tokenId) external view tokenExists(_tokenId) returns (string memory) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        // Fetch token parameters
        Genesis.SVGParams memory params = ds.tokenIdToParams[_tokenId];

        // Return metadata as base64 encoded JSON.
        return RenderLib.buildMetadata(_tokenId, params, ds.tokenIdToGeneration[_tokenId]);
    }

    /// @inheritdoc IBeanHeadsView
    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    /// @inheritdoc IBeanHeadsView
    function getOwnerOf(uint256 _tokenId) external view tokenExists(_tokenId) returns (address) {
        return _ownerOf(_tokenId);
    }

    /// @inheritdoc IBeanHeadsView
    function getOwnerTokens(address _owner) external view returns (uint256[] memory) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.ownerTokens[_owner];
    }

    /// @inheritdoc IBeanHeadsView
    function getAttributesByTokenId(uint256 _tokenId)
        external
        view
        tokenExists(_tokenId)
        returns (Genesis.SVGParams memory)
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.tokenIdToParams[_tokenId];
    }

    /// @inheritdoc IBeanHeadsView
    function getAttributesByOwner(address _owner, uint256 _tokenId)
        external
        view
        tokenExists(_tokenId)
        returns (Genesis.SVGParams memory)
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        uint256[] memory tokens = ds.ownerTokens[_owner];

        return ds.tokenIdToParams[tokens[_tokenId]];
    }

    /// @inheritdoc IBeanHeadsView
    function getAttributes(uint256 _tokenId) external view tokenExists(_tokenId) returns (string memory) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        return Genesis.buildAttributes(ds.tokenIdToParams[_tokenId], ds.tokenIdToGeneration[_tokenId]);
    }

    /// @inheritdoc IBeanHeadsView
    function getTokenSalePrice(uint256 _tokenId) external view tokenExists(_tokenId) returns (uint256) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        BHStorage.Listing storage listing = ds.tokenIdToListing[_tokenId];

        if (!listing.isActive) {
            _revert(IBeanHeadsView__TokenNotForSale.selector);
        }

        return listing.price;
    }

    /// @inheritdoc IBeanHeadsView
    function getMintPrice() external view returns (uint256) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.mintPriceUsd;
    }

    /// @inheritdoc IBeanHeadsView
    function getGeneration(uint256 _tokenId) external view tokenExists(_tokenId) returns (uint256) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.tokenIdToGeneration[_tokenId];
    }

    /// @inheritdoc IBeanHeadsView
    function getAuthorizedBreeders(address _breeder) external view returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.authorizedBreeders[_breeder];
    }

    /// @inheritdoc IBeanHeadsView
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @inheritdoc IBeanHeadsView
    function isTokenAllowed(address _token) external view returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.allowedTokens[_token];
    }

    /// @inheritdoc IBeanHeadsView
    function getPriceFeed(address _token) external view returns (address) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.priceFeeds[_token];
    }

    /// @inheritdoc IBeanHeadsView
    function isTokenForSale(uint256 _tokenId) external view tokenExists(_tokenId) returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.tokenIdToListing[_tokenId].isActive;
    }
}
