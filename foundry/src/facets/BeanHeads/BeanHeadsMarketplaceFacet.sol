// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721AUpgradeableInternal} from "src/ERC721A/ERC721AUpgradeableInternal.sol";
import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {IBeanHeadsMarketplace} from "src/interfaces/IBeanHeadsMarketplace.sol";

contract BeanHeadsMarketplaceFacet is ERC721AUpgradeable, ReentrancyGuard, IBeanHeadsMarketplace {
    using SafeERC20 for IERC20;

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

        emit SetTokenPrice(msg.sender, _tokenId, _price);
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function buyToken(uint256 _tokenId, address _paymentToken) external nonReentrant tokenExists(_tokenId) {
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
        ds.ownerTokens[msg.sender].push(_tokenId);

        ds.tokenIdToPaymentToken[_tokenId] = _paymentToken;
        _safeTransfer(address(this), msg.sender, _tokenId, "");

        emit TokenSold(msg.sender, listing.seller, _tokenId, adjustedPrice);

        ds.tokenIdToListing[_tokenId] = BHStorage.Listing({seller: address(0), price: 0, isActive: false});
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function cancelTokenSale(uint256 _tokenId) external tokenExists(_tokenId) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        BHStorage.Listing storage listing = ds.tokenIdToListing[_tokenId];

        if (msg.sender != listing.seller) _revert(IBeanHeadsMarketplace__NotOwner.selector);
        if (!listing.isActive) _revert(IBeanHeadsMarketplace__TokenNotForSale.selector);

        // Transfer the token back to the seller
        _safeTransfer(address(this), msg.sender, _tokenId, "");
        ds.ownerTokens[msg.sender].push(_tokenId);

        // Reset the listing
        listing.isActive = false;
        listing.price = 0;
        listing.seller = address(0);

        emit TokenSaleCancelled(msg.sender, _tokenId);
    }

    /// @inheritdoc IBeanHeadsMarketplace
    function getTokenSalePrice(uint256 _tokenId) external view tokenExists(_tokenId) returns (uint256) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        BHStorage.Listing storage listing = ds.tokenIdToListing[_tokenId];

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
    function _getTokenAmountFromUsd(address token, uint256 usdAmount) internal view returns (uint256) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ds.priceFeeds[token]);
        (, int256 answer,,,) = priceFeed.latestRoundData();

        if (answer <= 0) _revert(IBeanHeadsMarketplace__InvalidOraclePrice.selector);

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
            _revert(IBeanHeadsMarketplace__InsufficientAllowance.selector);
        }
        if (token.balanceOf(msg.sender) < amount) _revert(IBeanHeadsMarketplace__InsufficientPayment.selector);
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
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

        return IERC2981(ds.royaltyContract).royaltyInfo(tokenId, salePrice);
    }

    /**
     * @notice Removes tokens from the owner's list (s_ownerTokens)
     * @param owner The address of the token owner
     * @param tokenId The ID of the token to remove
     */
    function _removeTokenFromOwner(address owner, uint256 tokenId) internal {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        uint256[] storage tokens = ds.ownerTokens[owner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    /// @notice Inherits from IERC721Receiver interface
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector; // Return the selector for ERC721Received
    }
}
