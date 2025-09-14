// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IBeanHeads, IBeanHeadsMarketplace} from "src/interfaces/IBeanHeads.sol";

abstract contract BeanHeadsBase is ERC721AUpgradeable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice Error if the token does not exist
    error IBeanHeadsBase__TokenDoesNotExist();
    /// @notice Error if the price feed is invalid
    error IBeanHeadsBase__InvalidOraclePrice();
    /// @notice Error if the payment token allowance is insufficient
    error IBeanHeadsBase__InsufficientAllowance();
    /// @notice Error if the payment token balance is insufficient
    error IBeanHeadsBase__InsufficientPayment();
    /// @notice Error if the token is locked
    error IBeanHeadsBase__TokenIsLocked();
    /// @notice Error if the token is not for sale
    error IBeanHeadsBase__TokenIsNotForSale();
    /// @notice Error if the token is not allowed for minting
    error IBeanHeadsBase__TokenNotAllowed(address token);
    /// @notice Error if the price is not greater than zero
    error IBeanHeadsBase__PriceMustBeGreaterThanZero();
    /// @notice Error if the token is already listed for sale
    error IBeanHeadsBase__TokenIsAlreadyListed();
    /// @notice Error if the caller is not the owner of the token
    error IBeanHeadsBase__NotOwner();

    using BHStorage for BHStorage.BeanHeadsStorage;

    /// @dev Hook that updates ownerTokens mapping on mint, transfer, and burn
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        // Prevent transfers of locked tokens
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = startTokenId + i;

            // Skip minting (`from == address(0)`) and burning (`to == address(0)`)
            if (from != address(0) && ds.lockedTokens[tokenId]) {
                _revert(IBeanHeadsBase__TokenIsLocked.selector);
            }
        }

        // Handle removal from previous owner
        if (from != address(0)) {
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = startTokenId + i;
                _removeFromOwnerTokens(ds, from, tokenId);
            }
        }

        // Handle addition to new owner
        if (to != address(0)) {
            for (uint256 i = 0; i < quantity; i++) {
                ds.ownerTokens[to].push(startTokenId + i);
            }
        }
    }

    /**
     * @notice Removes a tokenId from the owner's tokens list
     * @param ds The BeanHeadsStorage instance
     * @param owner The address of the token owner
     * @param tokenId The ID of the token to remove
     */
    function _removeFromOwnerTokens(BHStorage.BeanHeadsStorage storage ds, address owner, uint256 tokenId) internal {
        uint256[] storage tokens = ds.ownerTokens[owner];
        uint256 len = tokens.length;

        for (uint256 i = 0; i < len; i++) {
            if (tokens[i] == tokenId) {
                // Swap with the last element and pop
                tokens[i] = tokens[len - 1];
                tokens.pop();
                return;
            }
        }
    }

    /**
     * @notice Converts a USD-denominated price (1e18) to token amount based on Chainlink price feed and token decimals
     * @dev Assumes price feed returns 8 decimals, so adds 1e10 precision adjustment to make up to 1e18
     * @param token The ERC20 token address used for payment
     * @param usdAmount Amount in 18-decimal USD
     * @return tokenAmount Equivalent amount of `token` based on its USD price
     */
    function _getTokenAmountFromUsd(address token, uint256 usdAmount) internal view returns (uint256) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ds.priceFeeds[token]);
        (, int256 answer,,,) = priceFeed.latestRoundData();

        if (answer <= 0) _revert(IBeanHeadsBase__InvalidOraclePrice.selector);

        uint256 price = uint256(answer) * BHStorage.ADDITIONAL_FEED_PRECISION;
        uint8 tokenDecimals = IERC20Metadata(token).decimals();

        // Required token amount = usdAmount / tokenPrice
        uint256 tokenAmountIn18 = (usdAmount * BHStorage.PRECISION) / price;

        if (tokenDecimals < 18) {
            return tokenAmountIn18 / (10 ** (18 - tokenDecimals));
        } else if (tokenDecimals > 18) {
            return tokenAmountIn18 * (10 ** (tokenDecimals - 18));
        } else {
            return tokenAmountIn18;
        }
    }

    /**
     * @notice Check if the user's payment token's allowance and balance are sufficient
     * @param token The ERC20 token address used for payment
     * @param amount The amount to check against the user's balance and allowance
     */
    function _checkPaymentTokenAllowanceAndBalance(IERC20 token, uint256 amount) internal view {
        if (token.allowance(msg.sender, address(this)) < amount) {
            _revert(IBeanHeadsBase__InsufficientAllowance.selector);
        }
        if (token.balanceOf(msg.sender) < amount) _revert(IBeanHeadsBase__InsufficientPayment.selector);
    }

    /**
     * @notice Gets the listing for a specific token ID
     * @param tokenId The ID of the token to get the listing for
     * @return listing The Listing struct containing the token's sale information
     */
    function _getListing(uint256 tokenId) internal view returns (BHStorage.Listing storage listing) {
        listing = BHStorage.diamondStorage().tokenIdToListing[tokenId];
    }

    /**
     * @notice Validates the token IDs and calculates their adjusted prices
     * @param tokenIds The array of token IDs to validate
     * @param paymentToken The address of the payment token
     * @return adjustedPrices The array of adjusted prices for each token ID
     * @return totalPrice The total price for all tokens
     */
    function _validateAndCalculatePrices(uint256[] calldata tokenIds, address paymentToken)
        internal
        view
        returns (uint256[] memory adjustedPrices, uint256 totalPrice)
    {
        uint256 len = tokenIds.length;
        adjustedPrices = new uint256[](len);
        totalPrice = 0;

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = tokenIds[i];
            BHStorage.Listing storage listing = _getListing(tokenId);

            if (!listing.isActive) _revert(IBeanHeadsBase__TokenIsNotForSale.selector);
            uint256 adjustedPrice = _getTokenAmountFromUsd(paymentToken, listing.price);
            adjustedPrices[i] = adjustedPrice;
            totalPrice += adjustedPrice;
        }
    }

    /**
     * @notice Processes the batch transfer of tokens
     * @dev This function handles the transfer of tokens from the contract to the buyer, paying the seller and handling royalties
     * @param buyer The address of the buyer
     * @param tokenIds The array of token IDs to transfer
     * @param paymentToken The address of the payment token
     * @param adjustedPrices The array of adjusted prices for each token ID
     */
    function _processBatchTransfer(
        address buyer,
        uint256[] calldata tokenIds,
        address paymentToken,
        uint256[] memory adjustedPrices
    ) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _processSingleTransfer(buyer, tokenIds[i], paymentToken, adjustedPrices[i]);
        }
    }

    function _processSingleTransfer(address buyer, uint256 tokenId, address paymentToken, uint256 adjustedPrice)
        internal
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        IERC20 token = IERC20(paymentToken);

        BHStorage.Listing storage listing = _getListing(tokenId);

        // Handle royalty
        _handleRoyalty(tokenId, adjustedPrice, paymentToken);

        // Seller payout
        (, uint256 royaltyAmountRaw) = _royaltyInfo(tokenId, adjustedPrice);
        uint256 royaltyAmount = _getTokenAmountFromUsd(paymentToken, royaltyAmountRaw);
        uint256 sellerAmount = adjustedPrice - royaltyAmount;

        token.safeTransfer(listing.seller, sellerAmount);

        // Transfer NFT to buyer
        ds.tokenIdToPaymentToken[tokenId] = paymentToken;
        _safeTransfer(address(this), buyer, tokenId, "");

        emit IBeanHeadsMarketplace.TokenSold(buyer, listing.seller, tokenId, adjustedPrice);

        // Clear listing
        listing.seller = address(0);
        listing.price = 0;
        listing.isActive = false;

        ds.activeListings.remove(tokenId);
    }

    function _handleRoyalty(uint256 tokenId, uint256 adjustedPrice, address paymentToken) internal {
        (address royaltyReceiver, uint256 royaltyAmountRaw) = _royaltyInfo(tokenId, adjustedPrice);
        if (royaltyReceiver == address(0) || royaltyAmountRaw == 0) return;

        uint256 royaltyAmount = _getTokenAmountFromUsd(paymentToken, royaltyAmountRaw);
        if (royaltyAmount == 0) return;

        IERC20(paymentToken).safeTransfer(royaltyReceiver, royaltyAmount);
        emit IBeanHeadsMarketplace.RoyaltyPaid(royaltyReceiver, tokenId, adjustedPrice, royaltyAmount);
    }

    /**
     * @notice Sells a token with a custom price
     * @param tokenId The ID of the token to sell
     * @param price The price at which to sell the token
     * @param seller The address of the seller
     */
    function _sellToken(uint256 tokenId, uint256 price, address seller) internal {
        BHStorage.Listing storage listing = _getListing(tokenId);
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        if (!_exists(tokenId)) _revert(IBeanHeadsBase__TokenDoesNotExist.selector);
        if (_ownerOf(tokenId) != seller) _revert(IBeanHeadsBase__NotOwner.selector);
        if (price <= 0) _revert(IBeanHeadsBase__PriceMustBeGreaterThanZero.selector);
        if (listing.isActive) _revert(IBeanHeadsBase__TokenIsAlreadyListed.selector);

        safeTransferFrom(seller, address(this), tokenId);

        listing.seller = seller;
        listing.price = price;
        listing.isActive = true;

        ds.activeListings.add(tokenId);

        emit IBeanHeadsMarketplace.SetTokenPrice(seller, tokenId, price);
    }

    /**
     * @notice Cancels the sale of a token
     * @param tokenId The ID of the token to cancel the sale for
     * @param seller The address of the seller
     */
    function _cancelToken(uint256 tokenId, address seller) internal {
        BHStorage.Listing storage listing = _getListing(tokenId);
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        if (!_exists(tokenId)) _revert(IBeanHeadsBase__TokenDoesNotExist.selector);
        if (seller != listing.seller) _revert(IBeanHeadsBase__NotOwner.selector);
        if (!listing.isActive) _revert(IBeanHeadsBase__TokenIsNotForSale.selector);

        listing.seller = address(0);
        listing.price = 0;
        listing.isActive = false;

        ds.activeListings.remove(tokenId);

        _transfer(address(this), seller, tokenId);

        emit IBeanHeadsMarketplace.TokenSaleCancelled(seller, tokenId);
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
        internal
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        return IERC2981(ds.royaltyContract).royaltyInfo(tokenId, salePrice);
    }
}
