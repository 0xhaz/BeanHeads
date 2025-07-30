// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeadsBreeding} from "src/interfaces/IBeanHeadsBreeding.sol";

contract BeanHeadsBreedingFacet is ERC721AUpgradeable, IBeanHeadsBreeding {
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
        ds.ownerTokens[_to].push(_tokenId);

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
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        _burn(tokenId, true);

        // Remove token from owner's list
        uint256[] storage ownerTokens = ds.ownerTokens[msg.sender];
        for (uint256 i = 0; i < ownerTokens.length; i++) {
            if (ownerTokens[i] == tokenId) {
                ownerTokens[i] = ownerTokens[ownerTokens.length - 1];
                ownerTokens.pop();
                break;
            }
        }
    }
}
