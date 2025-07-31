// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeadsBreeding} from "src/interfaces/IBeanHeadsBreeding.sol";
import {BeanHeadsBase} from "src/abstracts/BeanHeadsBase.sol";

contract BeanHeadsBreedingFacet is BeanHeadsBase, IBeanHeadsBreeding {
    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier restricting access to authorized breeders
    modifier onlyBreeder() {
        BHStorage.BeanHeadsStorage storage s = BHStorage.diamondStorage();
        if (!s.authorizedBreeders[msg.sender]) {
            _revert(IBeanHeadsBreeding__UnauthorizedBreeders.selector);
        }
        _;
    }

    /// @notice Modifier to check if the token exists
    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            _revert(IBeanHeadsBreeding__TokenDoesNotExist.selector);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IBeanHeadsBreeding
    function mintFromBreeders(address _to, Genesis.SVGParams calldata _params, uint256 _generation)
        external
        onlyBreeder
        returns (uint256 _tokenId)
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        _tokenId = _nextTokenId();
        ds.tokenIdToParams[_tokenId] = _params;
        ds.tokenIdToGeneration[_tokenId] = _generation;
        ds.tokenIdToListing[_tokenId] = BHStorage.Listing({seller: address(0), price: 0, isActive: false});

        _safeMint(_to, 1);
        ds.authorizedBreeders[_to] = true; // Ensure the recipient is marked as an authorized breeder

        emit MintedNewBreed(_to, _tokenId);
    }

    /// @inheritdoc IBeanHeadsBreeding
    function getAuthorizedBreeders(address _breeder) external view returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.authorizedBreeders[_breeder];
    }

    /// @inheritdoc IBeanHeadsBreeding
    function getMintPrice() external view returns (uint256) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.mintPriceUsd;
    }

    /// @inheritdoc IBeanHeadsBreeding
    function burn(uint256 tokenId) external onlyBreeder {
        _burn(tokenId, true);
    }

    /// @inheritdoc IBeanHeadsBreeding
    function getGeneration(uint256 _tokenId) external view tokenExists(_tokenId) returns (uint256) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.tokenIdToGeneration[_tokenId];
    }

    /// @inheritdoc IBeanHeadsBreeding
    function getOwnerTokens(address _owner) external view returns (uint256[] memory) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.ownerTokens[_owner];
    }

    /// @inheritdoc IBeanHeadsBreeding
    function getPriceFeed(address _token) external view returns (address) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.priceFeeds[_token];
    }
}
