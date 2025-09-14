// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {BHStorage} from "src/libraries/BHStorage.sol";
import {IBeanHeadsMarketplace} from "src/interfaces/IBeanHeadsMarketplace.sol";
import {BeanHeadsBase} from "src/abstracts/BeanHeadsBase.sol";
import {ReentrancyLib} from "src/libraries/ReentrancyLib.sol";

contract BeanHeadsMarketplaceFacet is BeanHeadsBase, IBeanHeadsMarketplace {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier to check if the token exists
    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            _revert(IBeanHeadsMarketplace__TokenDoesNotExist.selector);
        }
        _;
    }

    /// @notice Reentrancy guard modifier
    modifier nonReentrant() {
        ReentrancyLib.enforceNotEntered();
        _;
        ReentrancyLib.resetStatus();
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBeanHeadsMarketplace
    function sellToken(uint256 _tokenId, uint256 _price) external tokenExists(_tokenId) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (msg.sender != _ownerOf(_tokenId)) _revert(IBeanHeadsMarketplace__NotOwner.selector);
        if (_price <= 0) _revert(IBeanHeadsMarketplace__PriceMustBeGreaterThanZero.selector);

        safeTransferFrom(msg.sender, address(this), _tokenId);

        ds.tokenIdToListing[_tokenId] = BHStorage.Listing({seller: msg.sender, price: _price, isActive: true});

        ds.activeListings.add(_tokenId);

        emit SetTokenPrice(msg.sender, _tokenId, _price);
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function batchSellTokens(uint256[] calldata _tokenIds, uint256[] calldata _prices) external {
        if (_tokenIds.length != _prices.length) _revert(IBeanHeadsMarketplace__MismatchedArrayLengths.selector);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _sellToken(_tokenIds[i], _prices[i], msg.sender);
        }
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function buyToken(address _buyer, uint256 _tokenId, address _paymentToken)
        external
        nonReentrant
        tokenExists(_tokenId)
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        BHStorage.Listing storage listing = ds.tokenIdToListing[_tokenId];

        if (!listing.isActive) _revert(IBeanHeadsMarketplace__TokenNotForSale.selector);
        if (!ds.allowedTokens[_paymentToken]) _revert(IBeanHeadsMarketplace__TokenNotAllowed.selector);

        IERC20 token = IERC20(_paymentToken);
        uint256 price = listing.price;
        uint256 adjustedPrice = _getTokenAmountFromUsd(_paymentToken, price);

        _checkPaymentTokenAllowanceAndBalance(token, adjustedPrice);

        // Transfer tokens from buyer to contract
        token.safeTransferFrom(msg.sender, address(this), adjustedPrice);

        // calculate royalty and transfer it
        (address royaltyReceiver, uint256 royaltyAmountRaw) = _royaltyInfo(_tokenId, adjustedPrice);
        uint256 royaltyAmount = _getTokenAmountFromUsd(_paymentToken, royaltyAmountRaw);
        uint256 sellerAmount = adjustedPrice - royaltyAmount;

        if (royaltyAmount > 0) {
            token.safeTransfer(royaltyReceiver, royaltyAmount);
            emit RoyaltyPaid(royaltyReceiver, _tokenId, price, royaltyAmount);
        }

        // Transfer remaining amount to the seller
        token.safeTransfer(listing.seller, sellerAmount);

        ds.tokenIdToPaymentToken[_tokenId] = _paymentToken;
        _safeTransfer(address(this), _buyer, _tokenId, "");

        ds.tokenIdToListing[_tokenId] = BHStorage.Listing({seller: address(0), price: 0, isActive: false});
        ds.activeListings.remove(_tokenId);

        emit TokenSold(_buyer, listing.seller, _tokenId, adjustedPrice);
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function batchBuyTokens(address _buyer, uint256[] calldata _tokenIds, address _paymentToken)
        external
        nonReentrant
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (!ds.allowedTokens[_paymentToken]) _revert(IBeanHeadsMarketplace__TokenNotAllowed.selector);

        (uint256[] memory adjustedPrices, uint256 totalPrice) = _validateAndCalculatePrices(_tokenIds, _paymentToken);

        _checkPaymentTokenAllowanceAndBalance(IERC20(_paymentToken), totalPrice);

        // Transfer tokens from buyer to contract
        IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), totalPrice);

        _processBatchTransfer(_buyer, _tokenIds, _paymentToken, adjustedPrices);
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function cancelTokenSale(uint256 _tokenId) external tokenExists(_tokenId) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        BHStorage.Listing storage listing = _getListing(_tokenId);

        if (msg.sender != listing.seller) _revert(IBeanHeadsMarketplace__NotOwner.selector);
        if (!listing.isActive) _revert(IBeanHeadsMarketplace__TokenNotForSale.selector);

        // Transfer the token back to the seller
        _safeTransfer(address(this), msg.sender, _tokenId, "");

        // Reset the listing
        listing.isActive = false;
        listing.price = 0;
        listing.seller = address(0);

        ds.activeListings.remove(_tokenId);

        emit TokenSaleCancelled(msg.sender, _tokenId);
    }

    function batchCancelTokenSales(uint256[] calldata _tokenIds, address _seller) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _cancelToken(_tokenIds[i], _seller);
        }
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function getTokenSalePrice(uint256 _tokenId) external view tokenExists(_tokenId) returns (uint256) {
        BHStorage.Listing storage listing = _getListing(_tokenId);

        if (!listing.isActive) {
            _revert(IBeanHeadsMarketplace__TokenNotForSale.selector);
        }

        return listing.price;
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function isTokenForSale(uint256 _tokenId) external view tokenExists(_tokenId) returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.tokenIdToListing[_tokenId].isActive;
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function isTokenAllowed(address _token) external view returns (bool) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.allowedTokens[_token];
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function getTokenSaleInfo(uint256 _tokenId)
        external
        view
        tokenExists(_tokenId)
        returns (address seller, uint256 price, bool isActive)
    {
        BHStorage.Listing storage listing = _getListing(_tokenId);
        return (listing.seller, listing.price, listing.isActive);
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function getAllActiveSaleTokens() external view returns (uint256[] memory) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        return ds.activeListings.values();
    }

    /// @notice Inherits from IERC721Receiver interface
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector; // Return the selector for ERC721Received
    }
}
