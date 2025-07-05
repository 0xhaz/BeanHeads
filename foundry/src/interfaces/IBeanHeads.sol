// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Genesis} from "src/types/Genesis.sol";

interface IBeanHeads {
    error IBeanHeads__InvalidType(uint8 id);
    error IBeanHeads__InvalidColor(uint8 id);
    error IBeanHeads__TokenDoesNotExist();
    error IBeanHeads__NotOwner();
    error IBeanHeads__WithdrawFailed();
    error IBeanHeads__InvalidRoyaltyFee();

    event MintedGenesis(address indexed owner, uint256 indexed tokenId);
    event Withdrawn(address indexed owner, uint256 amount);

    function mintGenesis(Genesis.SVGParams memory params) external returns (uint256);

    function getAttributes(uint256 tokenId) external view returns (string memory);

    function getOwnerTokens(address owner) external view returns (uint256[] memory);

    function getOwnerTokensCount(address owner) external view returns (uint256);

    function getOwnerTokensCount() external view returns (uint256);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function getAttributesByTokenId(uint256 tokenId) external view returns (Genesis.SVGParams memory);

    function getAttributesByOwner(address owner, uint256 tokenId) external view returns (Genesis.SVGParams memory);

    function withdrawToken() external;

    /// @notice Produces the URI describing the metadata of the token ID
    /// @dev Note this URI may be a data: URI with JSON contents directly inlined

    /// @param tokenID The ID of the token for which to produce the metadata
    /// @return the URI of the ERC721 compliant metadata
    function tokenURI(uint256 tokenID) external view returns (string memory);
}
