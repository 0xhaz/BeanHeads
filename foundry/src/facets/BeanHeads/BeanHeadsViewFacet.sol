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
        if (msg.sender != _owner) {
            _revert(IBeanHeadsView__NotOwner.selector);
        }

        return ds.tokenIdToParams[_tokenId];
    }

    /// @inheritdoc IBeanHeadsView
    function getAttributes(uint256 _tokenId) external view tokenExists(_tokenId) returns (string memory) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        return Genesis.buildAttributes(ds.tokenIdToParams[_tokenId], ds.tokenIdToGeneration[_tokenId]);
    }

    /// @inheritdoc IBeanHeadsView
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @inheritdoc IBeanHeadsView
    function getOwnerTokensCount(address _owner) external view returns (uint256) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.ownerTokens[_owner].length;
    }

    /// @inheritdoc IBeanHeadsView
    function getTotalSupply() external view returns (uint256) {
        return _totalMinted();
    }
}
