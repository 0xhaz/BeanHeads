// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

abstract contract BeanHeadsBase is ERC721AUpgradeable {
    error IBeanHeadsBase__TokenDoesNotExist();
    error IBeanHeadsBase__InvalidOraclePrice();
    error IBeanHeadsBase__InsufficientAllowance();
    error IBeanHeadsBase__InsufficientPayment();

    using BHStorage for BHStorage.BeanHeadsStorage;

    /// @dev Hook that updates ownerTokens mapping on mint, transfer, and burn
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();

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
}
