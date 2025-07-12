// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "ERC721A/extensions/ERC721AQueryable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

/**
 * @title BeanHeads
 * @notice BeanHeads is a customizable avatar on chain NFT collection
 * @dev Uses breeding concept to create new avatars similar to Cryptokitties
 * @dev Uses Chainlink VRF for attributes randomness
 */
contract BeanHeads is ERC721AQueryable, Ownable, IBeanHeads, IERC2981, ReentrancyGuard {
    using Base64 for bytes;
    using Strings for uint256;

    /// @notice Royalty information
    uint96 private royaltyFeeBps;
    address private royaltyReceiver;
    uint96 private constant MAX_BPS = 10000;

    /// @notice Token mint price
    uint256 public constant MINT_PRICE = 0.01 ether;

    /// @notice Mapping tokenId to its SVG parameters
    mapping(uint256 => Genesis.SVGParams) private s_tokenIdToParams;

    /// @notice Mapping tokenId to its sale price
    mapping(uint256 tokenId => uint256 price) private s_tokenIdToSalePriceValue;

    /// @notice Mapping tokenId to the contract owner (seller)
    mapping(uint256 tokenId => address owner) private s_tokenIdToSeller;

    /// @notice Mapping to store token sales in contract
    mapping(uint256 amount => uint256 balance) private s_tokenSaleBalance;

    /// @notice Mapping tokenId to its generation number
    mapping(uint256 tokenId => uint256 generation) private s_tokenIdToGeneration;

    /// @notice Mapping of addresses authorized to breed new tokens
    mapping(address tokenOwner => bool isAuthorized) private s_authorizedBreeders;

    /// @notice Modifier restricting access to authorized breeders
    modifier onlyBreeder() {
        if (!s_authorizedBreeders[msg.sender]) {
            revert IBeanHeads__UnauthorizedBreeders();
        }
        _;
    }

    /**
     * @dev Initializes the contract with default royalty settings
     * @param initialOwner The address to own the contract
     */
    constructor(address initialOwner) ERC721A("BeanHeads", "BEAN") Ownable(initialOwner) {
        royaltyFeeBps = 500; // 5% royalty fee
        royaltyReceiver = initialOwner; // Set initial royalty receiver to the contract owner
    }

    /**
     * @notice Mints a new Genesis NFT with the provided SVG parameters
     * @param params The struct containing SVG configuration parameters
     * @return tokenId The ID of the newly minted token
     */
    function mintGenesis(address to, Genesis.SVGParams memory params, uint256 amount)
        public
        payable
        returns (uint256 tokenId)
    {
        if (amount == 0) revert IBeanHeads__InvalidAmount();
        uint256 totalPrice = MINT_PRICE * amount;
        if (msg.value < totalPrice) revert IBeanHeads__InsufficientPayment();

        tokenId = _nextTokenId();
        s_tokenIdToParams[tokenId] = params;

        // Track funds collected from minting
        s_tokenSaleBalance[amount] += msg.value; // Update the contract's balance with the mint price

        _safeMint(to, amount);
        s_tokenIdToSalePriceValue[tokenId] = 0; // Initialize sale price to 0
        s_tokenIdToGeneration[tokenId] = 1;
        s_authorizedBreeders[to] = true; // Authorize the minter to breed new tokens

        emit MintedGenesis(to, tokenId);

        uint256 excess = msg.value - totalPrice;
        if (excess > 0) {
            (bool success,) = to.call{value: excess}("");
            if (!success) revert IBeanHeads__WithdrawFailed();
        }
    }

    /**
     * @notice Mints a new token with randomized attributes
     * @dev Only callable by authorized breeders
     * @param to The address to mint the token to
     * @param params The generated SVG parameters for the token
     * @param generation The generation number of the token
     * @return tokenId The ID of the newly minted token
     */
    function mintFromBreeders(address to, Genesis.SVGParams memory params, uint256 generation)
        external
        onlyBreeder
        returns (uint256 tokenId)
    {
        tokenId = _nextTokenId();
        s_tokenIdToParams[tokenId] = params;
        s_tokenIdToSalePriceValue[tokenId] = 0; // Initialize sale price to 0
        s_tokenIdToGeneration[tokenId] = generation;

        _safeMint(to, 1);
        s_authorizedBreeders[to] = true; // Ensure the minter is authorized to breed

        emit MintedNewBreed(to, tokenId);
    }

    /**
     * @notice Sets the royalty fee and receiver
     * @param feeBps The royalty fee in basis points (1% = 100 BPS)
     */
    function setRoyaltyInfo(uint96 feeBps) external onlyOwner {
        if (feeBps >= MAX_BPS) revert IBeanHeads__InvalidRoyaltyFee();

        royaltyFeeBps = feeBps;

        emit RoyaltyInfoUpdated(royaltyReceiver, feeBps);
    }

    /**
     * @notice Sell token with custom price
     * @param tokenId The ID of the token to sell
     * @param price The price at which to sell the token
     */
    function sellToken(uint256 tokenId, uint256 price) public override {
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        if (msg.sender != ownerOf(tokenId)) revert IBeanHeads__NotOwner();
        if (price <= 0) revert IBeanHeads__PriceMustBeGreaterThanZero();

        safeTransferFrom(msg.sender, address(this), tokenId);

        s_tokenIdToSalePriceValue[tokenId] = price;
        s_tokenIdToSeller[tokenId] = msg.sender; // Store the seller address

        emit SetTokenPrice(msg.sender, tokenId, price);
    }

    /**
     * @notice Buys a token currently on sale.
     * @param tokenId The ID of the token to buy.
     * @param price The agreed sale price.
     * @dev This function transfers the token to the buyer, pays the seller minus royalties, and emits relevant events.
     */
    function buyToken(uint256 tokenId, uint256 price) public payable override nonReentrant {
        if (s_tokenIdToSalePriceValue[tokenId] == 0) revert IBeanHeads__TokenIsNotForSale();
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        if (s_tokenIdToSalePriceValue[tokenId] != price) revert IBeanHeads__PriceMismatch();
        if (msg.value < price) revert IBeanHeads__InsufficientPayment();

        address seller = s_tokenIdToSeller[tokenId];

        // Reset sale price
        s_tokenIdToSalePriceValue[tokenId] = 0;
        delete s_tokenIdToSeller[tokenId]; // Clear seller address

        // Pay royalties
        uint256 royaltyAmount = (price * royaltyFeeBps) / MAX_BPS;
        (bool success,) = royaltyReceiver.call{value: royaltyAmount}("");
        if (!success) revert IBeanHeads__RoyaltyPaymentFailed(tokenId);

        emit RoyaltyPaid(royaltyReceiver, tokenId, price, royaltyAmount);

        // Transfer remaining amount to seller
        (success,) = seller.call{value: price - royaltyAmount}("");
        if (!success) revert IBeanHeads__WithdrawFailed();

        IERC721A(address(this)).transferFrom(address(this), msg.sender, tokenId);

        emit TokenSold(msg.sender, seller, tokenId, price);
    }

    /**
     * @notice Cancels the sale of a token
     * @param tokenId The ID of the token to cancel sale for
     * @dev Resets the sale price and seller address
     */
    function cancelTokenSale(uint256 tokenId) public override {
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        if (msg.sender != s_tokenIdToSeller[tokenId]) revert IBeanHeads__NotOwner();

        IERC721A(address(this)).transferFrom(address(this), msg.sender, tokenId);

        // Reset sale price
        s_tokenIdToSalePriceValue[tokenId] = 0;
        delete s_tokenIdToSeller[tokenId]; // Clear seller address

        emit TokenSaleCancelled(msg.sender, tokenId);
    }

    /**
     * @notice Returns the royalty information for a sale
     * @param salePrice The sale price of the token
     * @return receiver The address that will receive the royalty
     * @return royaltyAmount The amount of royalty to be paid
     */
    function royaltyInfo(uint256, uint256 salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyReceiver;
        royaltyAmount = (salePrice * royaltyFeeBps) / MAX_BPS;
    }

    /**
     * @notice Withdraws the contract's balance to the owner's address
     * @dev Only callable by the owner
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        if (amount == 0) revert IBeanHeads__WithdrawFailed();

        s_tokenSaleBalance[amount] = 0; // Reset the balance for the amount

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert IBeanHeads__WithdrawFailed();

        emit TokenWithdrawn(msg.sender, amount);
    }

    function approve(address to, uint256 tokenId) public payable override(IERC721A, ERC721A, IBeanHeads) {
        super.approve(to, tokenId);
    }

    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    receive() external payable {}

    /**
     * @notice Retrieves all token IDs owned by a specific address
     * @param owner The address of the token owner
     * @return tokenIds An array of token IDs owned by the specified address
     */
    function getOwnerTokens(address owner) external view returns (uint256[] memory) {
        return this.tokensOfOwner(owner);
    }

    /**
     * @notice Returns the number of tokens owned by the specified address.
     * @param owner Address to query.
     */
    function getOwnerTokensCount(address owner) external view returns (uint256) {
        return balanceOf(owner);
    }

    /**
     * @notice Returns the owner of a given token ID.
     * @param tokenId Token ID to query.
     */
    function getOwnerOf(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    /**
     * @notice Retrieves the stored SVG parameters for a token ID.
     * @param tokenId The token ID.
     * @return params The SVG parameters struct.
     */
    function getAttributesByTokenId(uint256 tokenId) external view returns (Genesis.SVGParams memory params) {
        params = s_tokenIdToParams[tokenId];
    }

    /**
     * @notice Allows the contract owner to authorize a breeder contract
     * @param breeder The address of the breeder contract to authorize
     */
    function authorizeBreeder(address breeder) external onlyOwner {
        s_authorizedBreeders[breeder] = true;
    }

    /**
     * @notice Retrieves the stored SVG parameters for a token ID, checking caller ownership.
     * @param owner Address expected to own the token.
     * @param tokenId The token ID.
     * @return params The SVG parameters struct.
     */
    function getAttributesByOwner(address owner, uint256 tokenId)
        external
        view
        returns (Genesis.SVGParams memory params)
    {
        if (ownerOf(tokenId) != owner) revert IBeanHeads__NotOwner();
        params = s_tokenIdToParams[tokenId];
    }

    /**
     * @notice Returns the metadata URI for a token.
     * @param tokenId Token ID to query.
     * @return Metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A, IBeanHeads) returns (string memory) {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }

        // Fetch token parameters
        Genesis.SVGParams memory params = s_tokenIdToParams[tokenId];
        // Build attributes and image
        string memory attributes = Genesis.buildAttributes(params, s_tokenIdToGeneration[tokenId]);
        string memory image = Genesis.generateBase64SVG(params);

        // Generate metadata JSON
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "BeanHeads #',
                tokenId.toString(),
                '", "description": "BeanHeads is a customizable avatar on chain NFT collection", "image": "',
                image,
                '", "attributes":',
                attributes,
                "}"
            )
        );

        // Return metadata as base64 encoded JSON.
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
    }

    /**
     * @notice Returns the attributes of a token as a JSON string.
     * @param tokenId The ID of the token to query.
     * @return A JSON string containing the attributes of the token.
     */
    function getAttributes(uint256 tokenId) external view override returns (string memory) {
        return Genesis.buildAttributes(s_tokenIdToParams[tokenId], s_tokenIdToGeneration[tokenId]);
    }

    /**
     * @notice Returns the sale price of a token.
     * @param tokenId The ID of the token to query.
     * @return The sale price of the token.
     */
    function getTokenSalePrice(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }
        return s_tokenIdToSalePriceValue[tokenId];
    }

    function getMintPrice() external pure returns (uint256) {
        return MINT_PRICE;
    }

    function getGeneration(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }
        return s_tokenIdToGeneration[tokenId];
    }

    function getAuthorizedBreeders(address owner) external view returns (bool) {
        return s_authorizedBreeders[owner];
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IBeanHeads, IERC721A, ERC721A)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice Supports interface detection.
     * @param interfaceId The interface identifier.
     * @return True if supported.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector; // Return the selector for ERC721Received
    }
}
