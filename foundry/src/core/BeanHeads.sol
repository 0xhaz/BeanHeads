// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ERC721A, IERC721A, ERC721AQueryable} from "ERC721A/extensions/ERC721AQueryable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {OracleLib} from "src/libraries/OracleLib.sol";
import {RenderLib} from "src/libraries/RenderLib.sol";

/**
 * @title BeanHeads
 * @notice BeanHeads is a customizable avatar on chain NFT collection
 * @dev Uses breeding concept to create new avatars similar to Cryptokitties
 * @dev Uses Chainlink VRF for attributes randomness
 */
contract BeanHeads is ERC721A, Ownable, IBeanHeads, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using OracleLib for AggregatorV3Interface;
    /*//////////////////////////////////////////////////////////////
                              GLOBAL STATE
    //////////////////////////////////////////////////////////////*/
    /// @notice Royalty information

    IERC2981 public immutable i_royaltyContract;

    /// @notice Token mint price
    uint256 private s_mintPrice;

    uint256 private constant PRECISION = 1e18; // Precision for price calculations

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/
    /// @notice Mapping tokenId to its SVG parameters
    mapping(uint256 => Genesis.SVGParams) private s_tokenIdToParams;

    /// @notice Mapping of Listing structs for each tokenId
    mapping(uint256 => Listing) private s_tokenIdToListing;

    /// @notice Mapping tokenId to its generation number
    mapping(uint256 tokenId => uint256 generation) private s_tokenIdToGeneration;

    /// @notice Mapping of addresses authorized to breed new tokens
    mapping(address tokenOwner => bool isAuthorized) private s_authorizedBreeders;

    /// @notice Mapping of total minted tokens owned by an address
    mapping(address tokenOwner => uint256[] tokenIds) private s_ownerTokens;

    /// @notice Mapping of allowed tokens to be used for minting
    mapping(address tokenAddress => bool isAllowed) private s_allowedTokens;

    /// @notice Mapping to track token used for minting and transactions
    mapping(uint256 tokenId => address tokenAddress) private s_tokenIdToPaymentToken;

    /// @notice Mapping of token price feeds to get USD value
    mapping(address tokenAddress => address priceFeed) private s_priceFeeds;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier restricting access to authorized breeders
    modifier onlyBreeder() {
        if (!s_authorizedBreeders[msg.sender]) {
            revert IBeanHeads__UnauthorizedBreeders();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Initializes the contract with default royalty settings
     * @param initialOwner The address to own the contract
     */
    constructor(address initialOwner, address royalty_) ERC721A("BeanHeads", "BEAN") Ownable(initialOwner) {
        i_royaltyContract = IERC2981(royalty_);
        s_mintPrice = 0.01 ether; // Set default mint price
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IBeanHeads
    function mintGenesis(address to, Genesis.SVGParams calldata params, uint256 amount, address paymentToken)
        public
        returns (uint256 tokenId)
    {
        if (amount == 0) revert IBeanHeads__InvalidAmount();
        if (!s_allowedTokens[paymentToken]) revert IBeanHeads__TokenNotAllowed(paymentToken);

        IERC20 token = IERC20(paymentToken);
        uint256 rawPrice = s_mintPrice * amount;
        uint256 adjustedPrice = _getTokenAmountFromUsd(paymentToken, rawPrice);

        if (token.allowance(msg.sender, address(this)) < adjustedPrice) revert IBeanHeads__InsufficientAllowance();
        if (token.balanceOf(msg.sender) < adjustedPrice) revert IBeanHeads__InsufficientPayment();

        tokenId = _nextTokenId();
        s_tokenIdToParams[tokenId] = params;

        _safeMint(to, amount);
        s_tokenIdToListing[tokenId] = Listing({
            seller: msg.sender,
            price: 0, // Initialize sale price to 0
            isActive: false
        });
        s_tokenIdToGeneration[tokenId] = 1;
        s_authorizedBreeders[to] = true; // Authorize the minter to breed new tokens
        s_ownerTokens[to].push(tokenId); // Add tokenId to owner's list
        s_tokenIdToPaymentToken[tokenId] = paymentToken; // Store the payment token used for minting

        // Transfer tokens from the minter to the contract
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), adjustedPrice);

        emit MintedGenesis(to, tokenId);
    }

    /// @inheritdoc IBeanHeads
    function sellToken(uint256 tokenId, uint256 price) public {
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        if (msg.sender != ownerOf(tokenId)) revert IBeanHeads__NotOwner();
        if (price <= 0) revert IBeanHeads__PriceMustBeGreaterThanZero();

        safeTransferFrom(msg.sender, address(this), tokenId);

        s_tokenIdToListing[tokenId] = Listing({seller: msg.sender, price: price, isActive: true});

        emit SetTokenPrice(msg.sender, tokenId, price);
    }

    /// @inheritdoc IBeanHeads
    function buyToken(uint256 tokenId, address paymentToken) public nonReentrant {
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();

        uint256 price = s_tokenIdToListing[tokenId].price;
        if (price == 0) revert IBeanHeads__TokenIsNotForSale();
        if (!s_allowedTokens[paymentToken]) revert IBeanHeads__TokenNotAllowed(paymentToken);

        IERC20 token = IERC20(paymentToken);
        uint256 adjustedPrice = _getTokenAmountFromUsd(paymentToken, price);

        if (token.allowance(msg.sender, address(this)) < adjustedPrice) revert IBeanHeads__InsufficientAllowance();
        if (token.balanceOf(msg.sender) < adjustedPrice) revert IBeanHeads__InsufficientPayment();

        address seller = s_tokenIdToListing[tokenId].seller;

        // Reset sale price
        s_tokenIdToListing[tokenId].price = 0;
        s_tokenIdToListing[tokenId].isActive = false; // Mark listing as inactive
        delete s_tokenIdToListing[tokenId].seller; // Clear seller address

        // Pay royalties
        (address royaltyReceiver, uint256 royaltyAmountRaw) = _royaltyInfo(tokenId, price);
        uint256 royaltyAmount = _getTokenAmountFromUsd(paymentToken, royaltyAmountRaw);
        token.safeTransfer(royaltyReceiver, royaltyAmount);

        emit RoyaltyPaid(royaltyReceiver, tokenId, price, royaltyAmount);

        // Transfer remaining amount to seller
        uint256 sellerAmount = adjustedPrice - royaltyAmount;
        IERC20(paymentToken).safeTransfer(seller, sellerAmount);

        s_tokenIdToPaymentToken[tokenId] = paymentToken; // Store the payment token used for the transaction
        IERC721A(address(this)).safeTransferFrom(address(this), msg.sender, tokenId);
        s_ownerTokens[msg.sender].push(tokenId); // Add tokenId to buyer's list
        _removeTokenFromOwner(seller, tokenId); // Remove tokenId from seller's list

        emit TokenSold(msg.sender, seller, tokenId, price);
    }

    /// @inheritdoc IBeanHeads
    function cancelTokenSale(uint256 tokenId) public override {
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        if (msg.sender != s_tokenIdToListing[tokenId].seller) {
            revert IBeanHeads__NotOwner();
        }

        IERC721A(address(this)).safeTransferFrom(address(this), msg.sender, tokenId);

        // Reset sale price
        s_tokenIdToListing[tokenId].price = 0;
        s_tokenIdToListing[tokenId].isActive = false; // Mark listing as inactive
        delete s_tokenIdToListing[tokenId].seller; // Clear seller address

        emit TokenSaleCancelled(msg.sender, tokenId);
    }

    /// @inheritdoc IBeanHeads
    function approve(address to, uint256 tokenId) public payable override(ERC721A, IBeanHeads) {
        super.approve(to, tokenId);
    }

    /// @inheritdoc IBeanHeads
    function tokenURI(uint256 tokenId) public view override(ERC721A, IBeanHeads) returns (string memory) {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }

        // Fetch token parameters
        Genesis.SVGParams memory params = s_tokenIdToParams[tokenId];

        // Return metadata as base64 encoded JSON.
        return RenderLib.buildMetadata(tokenId, params, s_tokenIdToGeneration[tokenId]);
    }

    /// @inheritdoc IBeanHeads
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(IBeanHeads, ERC721A) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IBeanHeads
    function mintFromBreeders(address to, Genesis.SVGParams calldata params, uint256 generation)
        external
        onlyBreeder
        returns (uint256 tokenId)
    {
        tokenId = _nextTokenId();
        s_tokenIdToParams[tokenId] = params;
        s_tokenIdToListing[tokenId].price = 0; // Initialize sale price to 0
        s_tokenIdToGeneration[tokenId] = generation;

        _safeMint(to, 1);
        s_authorizedBreeders[to] = true; // Ensure the minter is authorized to breed
        s_ownerTokens[to].push(tokenId); // Add tokenId to owner's list

        emit MintedNewBreed(to, tokenId);
    }

    /// @inheritdoc IBeanHeads
    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    /// @inheritdoc IBeanHeads
    function getOwnerTokensCount(address owner) external view returns (uint256) {
        return balanceOf(owner);
    }

    /// @inheritdoc IBeanHeads
    function getOwnerOf(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    /// @inheritdoc IBeanHeads
    function getOwnerTokens(address owner) external view override returns (uint256[] memory) {
        return s_ownerTokens[owner];
    }

    /// @inheritdoc IBeanHeads
    function getAttributesByTokenId(uint256 tokenId) external view returns (Genesis.SVGParams memory params) {
        params = s_tokenIdToParams[tokenId];
    }

    /// @inheritdoc IBeanHeads
    function getAttributesByOwner(address owner, uint256 tokenId)
        external
        view
        returns (Genesis.SVGParams memory params)
    {
        if (ownerOf(tokenId) != owner) revert IBeanHeads__NotOwner();
        params = s_tokenIdToParams[tokenId];
    }

    /// @inheritdoc IBeanHeads
    function getAttributes(uint256 tokenId) external view returns (string memory) {
        return Genesis.buildAttributes(s_tokenIdToParams[tokenId], s_tokenIdToGeneration[tokenId]);
    }

    /// @inheritdoc IBeanHeads
    function getTokenSalePrice(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }
        return s_tokenIdToListing[tokenId].price;
    }

    /// @inheritdoc IBeanHeads
    function setMintPrice(uint256 newPrice) external onlyOwner {
        if (newPrice <= 0) revert IBeanHeads__PriceMustBeGreaterThanZero();
        s_mintPrice = newPrice;

        emit MintPriceUpdated(newPrice);
    }

    /// @inheritdoc IBeanHeads
    function getMintPrice() external view returns (uint256) {
        return s_mintPrice;
    }

    /// @inheritdoc IBeanHeads
    function getGeneration(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }
        return s_tokenIdToGeneration[tokenId];
    }

    /// @inheritdoc IBeanHeads
    function getAuthorizedBreeders(address owner) external view returns (bool) {
        return s_authorizedBreeders[owner];
    }

    /// @inheritdoc IBeanHeads
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    /// @inheritdoc IBeanHeads
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @inheritdoc IBeanHeads
    function setAllowedToken(address token, bool isAllowed) external onlyOwner {
        if (token == address(0)) revert IBeanHeads__InvalidTokenAddress();
        s_allowedTokens[token] = isAllowed;

        emit AllowedTokenUpdated(token, isAllowed);
    }

    /// @inheritdoc IBeanHeads
    function isTokenAllowed(address token) external view returns (bool) {
        return s_allowedTokens[token];
    }

    function getPriceFeed(address token) external view returns (address) {
        return s_priceFeeds[token];
    }

    function isTokenForSale(uint256 tokenId) external view returns (bool) {
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        return s_tokenIdToListing[tokenId].isActive;
    }

    /*//////////////////////////////////////////////////////////////
                            ROYALTY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns the royalty information for a sale
     * @param salePrice The sale price of the token
     * @return receiver The address that will receive the royalty
     * @return royaltyAmount The amount of royalty to be paid
     */
    function _royaltyInfo(uint256 tokenId, uint256 salePrice)
        private
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return i_royaltyContract.royaltyInfo(tokenId, salePrice);
    }

    /**
     * @notice Removes tokens from the owner's list (s_ownerTokens)
     * @param owner The address of the token owner
     * @param tokenId The ID of the token to remove
     */
    function _removeTokenFromOwner(address owner, uint256 tokenId) private {
        uint256[] storage tokens = s_ownerTokens[owner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1]; // Move last element to the current position
                tokens.pop(); // Remove the last element
                break;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Converts a USD-denominated price (1e18) to token amount based on Chainlink price feed and token decimals
     * @dev Assumes price feed returns 8 decimals, so adds 1e10 precision adjustment to make up to 1e18
     * @param token The ERC20 token address used for payment
     * @param usdAmount Amount in 18-decimal USD
     * @return tokenAmount Equivalent amount of `token` based on its USD price
     */
    function _getTokenAmountFromUsd(address token, uint256 usdAmount) internal view returns (uint256 tokenAmount) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();

        if (price <= 0) revert IBeanHeads__InvalidOraclePrice(); // optional safety check

        uint8 decimals = IERC20Metadata(token).decimals();
        uint256 scale = 10 ** uint256(decimals);

        tokenAmount = (usdAmount * scale * ADDITIONAL_FEED_PRECISION) / uint256(price);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBeanHeads
    function withdraw(address paymentToken) external onlyOwner nonReentrant {
        uint256 amount = IERC20(paymentToken).balanceOf(address(this));
        if (amount == 0) revert IBeanHeads__WithdrawFailed();

        IERC20(paymentToken).transfer(msg.sender, amount);

        emit TokenWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Allows the contract owner to authorize a breeder contract
     * @param breeder The address of the breeder contract to authorize
     */
    function authorizeBreeder(address breeder) external onlyOwner {
        s_authorizedBreeders[breeder] = true;
    }

    /*//////////////////////////////////////////////////////////////
                               INTERFACE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Supports interface detection.
     * @param interfaceId The interface identifier.
     * @return True if supported.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Inherits from IERC721Receiver interface
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector; // Return the selector for ERC721Received
    }
}
