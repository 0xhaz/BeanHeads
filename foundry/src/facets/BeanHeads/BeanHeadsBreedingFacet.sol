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
}
