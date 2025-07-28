// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {BHDLib} from "src/libraries/BHDLib.sol";
import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721A, IERC721A, ERC721AQueryable} from "ERC721A/extensions/ERC721AQueryable.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {OracleLib} from "src/libraries/OracleLib.sol";

contract BeanHeadsMintFacet is IBeanHeads {
    using SafeERC20 for IERC20;
    using OracleLib for AggregatorV3Interface;

    uint256 private constant PRECISION = 1e18; // Precision for price calculations

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;

    function mintGenesis(address _to, Genesis.SVGParams calldata _params, uint256 _amount, address _paymentToken)
        external
        returns (uint256 _tokenId)
    {
        BHDLib.BeanHeadsStorage storage ds = BHDLib.diamondStorage();
        if (_amount == 0) revert IBeanHeads__InvalidAmount();
        if (!ds.allowedTokens[_paymentToken]) revert IBeanHeads__TokenNotAllowed(_paymentToken);

        IERC20 token = IERC20(_paymentToken);
        uint256 rawPrice = ds.mintPriceUsd * _amount;
        uint256 adjustedPrice = _getTokenAmountFromUsd(_paymentToken, rawPrice);

        _checkPaymentTokenAllowanceAndBalance(token, adjustedPrice);

        _tokenId = _nextTokenId();
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
        BHDLib.BeanHeadsStorage storage ds = BHDLib.diamondStorage();
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ds.priceFeeds[token]);
        (, int256 answer,,,) = priceFeed.latestRoundData();

        if (answer <= 0) revert IBeanHeads__InvalidOraclePrice();

        uint256 price = uint256(answer) * ADDITIONAL_FEED_PRECISION;
        uint8 tokenDecimals = IERC20Metadata(token).decimals();

        // Required token amount = usdAmount / tokenPrice
        uint256 tokenAmountIn18 = (usdAmount * PRECISION) / price;

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
        if (token.allowance(msg.sender, address(this)) < amount) revert IBeanHeads__InsufficientAllowance();
        if (token.balanceOf(msg.sender) < amount) revert IBeanHeads__InsufficientPayment();
    }

    function _nextTokenId() internal view returns (uint256) {}
}
