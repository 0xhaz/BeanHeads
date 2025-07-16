// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "ERC721A/extensions/ERC721AQueryable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {RenderLib} from "src/libraries/RenderLib.sol";

/**
 * @title BeanHeads
 * @notice BeanHeads is a customizable avatar on chain NFT collection
 * @dev Uses breeding concept to create new avatars similar to Cryptokitties
 * @dev Uses Chainlink VRF for attributes randomness
 */
contract BeanHeads is ERC721AQueryable, Ownable, IBeanHeads, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              GLOBAL STATE
    //////////////////////////////////////////////////////////////*/
    /// @notice Royalty information
    IERC2981 public immutable i_royaltyContract;

    /// @notice Token mint price
    uint256 public constant MINT_PRICE = 0.01 ether;

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/
    /// @notice Mapping tokenId to its SVG parameters
    mapping(uint256 => Genesis.SVGParams) private s_tokenIdToParams;

    /// @notice Mapping tokenId to its sale price
    mapping(uint256 tokenId => uint256 price) private s_tokenIdToSalePriceValue;

    /// @notice Mapping tokenId to the contract owner (seller)
    mapping(uint256 tokenId => address owner) private s_tokenIdToSeller;

    /// @notice Mapping tokenId to its generation number
    mapping(uint256 tokenId => uint256 generation) private s_tokenIdToGeneration;

    /// @notice Mapping of addresses authorized to breed new tokens
    mapping(address tokenOwner => bool isAuthorized) private s_authorizedBreeders;

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
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Inherits from IBeanHeads interface
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

    /// @notice Inherits from IBeanHeads interface
    function sellToken(uint256 tokenId, uint256 price) public {
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        if (msg.sender != ownerOf(tokenId)) revert IBeanHeads__NotOwner();
        if (price <= 0) revert IBeanHeads__PriceMustBeGreaterThanZero();

        safeTransferFrom(msg.sender, address(this), tokenId);

        s_tokenIdToSalePriceValue[tokenId] = price;
        s_tokenIdToSeller[tokenId] = msg.sender; // Store the seller address

        emit SetTokenPrice(msg.sender, tokenId, price);
    }

    /// @notice Inherits from IBeanHeads interface
    function buyToken(uint256 tokenId, uint256 price) public payable nonReentrant {
        if (s_tokenIdToSalePriceValue[tokenId] == 0) revert IBeanHeads__TokenIsNotForSale();
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        if (s_tokenIdToSalePriceValue[tokenId] != price) revert IBeanHeads__PriceMismatch();
        if (msg.value < price) revert IBeanHeads__InsufficientPayment();

        address seller = s_tokenIdToSeller[tokenId];

        // Reset sale price
        s_tokenIdToSalePriceValue[tokenId] = 0;
        delete s_tokenIdToSeller[tokenId]; // Clear seller address

        // Pay royalties

        (address royaltyReceiver, uint256 royaltyAmount) = _royaltyInfo(tokenId, price);
        (bool success,) = royaltyReceiver.call{value: royaltyAmount}("");
        if (!success) revert IBeanHeads__RoyaltyPaymentFailed(tokenId);

        emit RoyaltyPaid(royaltyReceiver, tokenId, price, royaltyAmount);

        // Transfer remaining amount to seller
        (success,) = seller.call{value: price - royaltyAmount}("");
        if (!success) revert IBeanHeads__WithdrawFailed();

        uint256 overpayment = msg.value - price;
        if (overpayment > 0) {
            (bool refundSuccess,) = msg.sender.call{value: overpayment}("");
            if (!refundSuccess) revert IBeanHeads__WithdrawFailed();
        }

        IERC721A(address(this)).transferFrom(address(this), msg.sender, tokenId);

        emit TokenSold(msg.sender, seller, tokenId, price);
    }

    /// @notice Inherits from IBeanHeads interface
    function cancelTokenSale(uint256 tokenId) public override {
        if (!_exists(tokenId)) revert IBeanHeads__TokenDoesNotExist();
        if (msg.sender != s_tokenIdToSeller[tokenId]) revert IBeanHeads__NotOwner();

        IERC721A(address(this)).transferFrom(address(this), msg.sender, tokenId);

        // Reset sale price
        s_tokenIdToSalePriceValue[tokenId] = 0;
        delete s_tokenIdToSeller[tokenId]; // Clear seller address

        emit TokenSaleCancelled(msg.sender, tokenId);
    }

    // @notice Inherits from IERC721A and ERC721A
    function approve(address to, uint256 tokenId) public payable override(IERC721A, ERC721A, IBeanHeads) {
        super.approve(to, tokenId);
    }

    /// @notice Inherits from IBeanHeads interface
    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A, IBeanHeads) returns (string memory) {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }

        // Fetch token parameters
        Genesis.SVGParams memory params = s_tokenIdToParams[tokenId];

        // Return metadata as base64 encoded JSON.
        return RenderLib.buildMetadata(tokenId, params, s_tokenIdToGeneration[tokenId]);
    }

    /// @notice Inherits from IERC721A and ERC721A
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IBeanHeads, IERC721A, ERC721A)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Inherits from IBeanHeads interface
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

    /// @notice Inherits from IBeanHeads interface
    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    /// @notice Inherits from IBeanHeads interface
    function getOwnerTokens(address owner) external view returns (uint256[] memory) {
        return this.tokensOfOwner(owner);
    }

    /// @notice Inherits from IBeanHeads interface
    function getOwnerTokensCount(address owner) external view returns (uint256) {
        return balanceOf(owner);
    }

    /// @notice Inherits from IBeanHeads interface
    function getOwnerOf(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    /// @notice Inherits from IBeanHeads interface
    function getAttributesByTokenId(uint256 tokenId) external view returns (Genesis.SVGParams memory params) {
        params = s_tokenIdToParams[tokenId];
    }

    /// @notice Inherits from IBeanHeads interface
    function getAttributesByOwner(address owner, uint256 tokenId)
        external
        view
        returns (Genesis.SVGParams memory params)
    {
        if (ownerOf(tokenId) != owner) revert IBeanHeads__NotOwner();
        params = s_tokenIdToParams[tokenId];
    }

    /// @notice Inherits from IBeanHeads interface
    function getAttributes(uint256 tokenId) external view returns (string memory) {
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

    /// @notice Inherits from IBeanHeads interface
    function getGeneration(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) {
            revert IBeanHeads__TokenDoesNotExist();
        }
        return s_tokenIdToGeneration[tokenId];
    }

    function getAuthorizedBreeders(address owner) external view returns (bool) {
        return s_authorizedBreeders[owner];
    }

    /// @notice Inherits from IERC721A and ERC721A
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    receive() external payable {}

    /// @notice Inherits from IERC721A and ERC721A
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
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

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Inherits from IBeanHeads interface
    function withdraw() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        if (amount == 0) revert IBeanHeads__WithdrawFailed();

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert IBeanHeads__WithdrawFailed();

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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Inherits from IERC721Receiver interface
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector; // Return the selector for ERC721Received
    }
}
