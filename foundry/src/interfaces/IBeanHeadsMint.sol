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
    /// @notice Error for unauthorized bridge access
    error IBeanHeadsMint__UnauthorizedBridge();
    /// @notice Error if the tokenId is already exists
    error IBeanHeadsMint__TokenAlreadyExists();
    /// @notice Error if the token is not locked
    error IBeanHeadsMint__NotLocked();
    /// @notice Error if the token is already locked
    error IBeanHeadsMint__AlreadyLocked();
    /// @notice Error if user wants to mint a token that is already minted on another chain
    error IBeanHeadsMint__MultiHopNotAllowed();
    /// @notice Error when user tries to burn the source token
    error IBeanHeadsMint__CannotBurnOriginToken();

    /// @notice Emitted when a new Genesis NFT is minted
    event MintedGenesis(address indexed owner, uint256 indexed tokenId);

    /// @notice Emitted when locked token is return to the owner
    event ReturnedToSource(address indexed owner, uint256 indexed tokenId);

    /// @notice Emitted when mirrored token is burned
    event TokenBurned(address indexed owner, uint256 indexed tokenId);

    /**
     * @notice Mints a new Genesis NFT with the provided SVG parameters
     * @param params The struct containing SVG configuration parameters
     * @return tokenId The ID of the newly minted token
     */
    function mintGenesis(address to, Genesis.SVGParams memory params, uint256 amount, address token)
        external
        returns (uint256);

    /// @notice Returns the name of the contract
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the contract
    function symbol() external view returns (string memory);

    /// @notice Returns the balance of a given address
    /// @param owner The address to query the balance of
    /// @return The number of tokens owned by the address
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Approves an address to manage a specific token
     * @param to The address to approve for the token
     * @param tokenId  The ID of the token to approve
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @notice Transfers a token from one address to another
     * @param from The address to transfer the token from
     * @param to The address to transfer the token to
     * @param tokenId The ID of the token to transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external payable;

    /**
     * @notice Transfers a token from one address to another
     * @param from The address to transfer the token from
     * @param to The address to transfer the token to
     * @param tokenId The ID of the token to transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;

    /**
     * @notice Returns the next available token ID
     * @return The next token ID as a uint256
     */
    function getNextTokenId() external view returns (uint256);

    /**
     * @notice Returns the owner of a given token ID
     * @param _tokenId The ID of the token
     * @return The address of the owner
     */
    function getOwnerOf(uint256 _tokenId) external view returns (address);

    /**
     * @notice Mints a bridge token on a remote chain
     * @param _to The address that will receive the minted token
     * @param _tokenId The ID of the token to be minted
     * @param _params The SVG parameters for the token to be minted
     * @dev _tokenId is use to retain the token ID across chains
     */
    function mintBridgeToken(address _to, uint256 _tokenId, Genesis.SVGParams calldata _params, uint256 _originChainId)
        external;

    /**
     * @notice Unlocks a token, allowing it to be transferred or modified
     * @dev This function is used to unlock a token that was previously locked.
     * @param _tokenId The ID of the token to lock
     */
    function unlockToken(uint256 _tokenId) external;

    /**
     * @notice Locks a token, preventing it from being transferred or modified
     * @dev This function is used to lock a token to prevent re-entrancy.
     * @param _tokenId The ID of the token to lock
     */
    function lockToken(uint256 _tokenId) external;

    /**
     * @notice Burns a token, permanently removing it from circulation
     * @param _tokenId The ID of the token to burn
     */
    function burnToken(uint256 _tokenId) external;
}
