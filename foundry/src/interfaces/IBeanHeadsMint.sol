// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";

interface IBeanHeadsMint {
    /// @notice Error for invalid mint amount
    error IBeanHeadsMint__InvalidAmount();
    /// @notice Error for token not allowed for minting
    error IBeanHeadsMint__TokenNotAllowed(address token);
    /// @notice Error for insufficient allowance for the payment token
    error IBeanHeadsMint__InsufficientAllowance();
    /// @notice Error for insufficient payment for minting
    error IBeanHeadsMint__InsufficientPayment();
    /// @notice Error for invalid oracle price
    error IBeanHeadsMint__InvalidOraclePrice();
    /// @notice Error for token does not exist
    error IBeanHeadsMint__TokenDoesNotExist();
    /// @notice Error for not being the owner of the token
    error IBeanHeadsMint__NotOwner();
    /// @notice Error for unapproved token address
    error IBeanHeadsMint__NotOwnerOrApproved();

    /// @notice Emitted when a new Genesis NFT is minted
    event MintedGenesis(address indexed owner, uint256 indexed tokenId);

    /**
     * @notice Mints a new Genesis NFT with the provided SVG parameters
     * @param params The struct containing SVG configuration parameters
     * @return tokenId The ID of the newly minted token
     */
    function mintGenesis(address to, Genesis.SVGParams memory params, uint256 amount, address token)
        external
        returns (uint256);

    /**
     * @notice Burns a token, removing it from circulation
     * @param tokenId The ID of the token to burn
     * @dev This function can only be called by the owner of the token or an authorized breeder.
     */
    function burn(uint256 tokenId) external;
}
