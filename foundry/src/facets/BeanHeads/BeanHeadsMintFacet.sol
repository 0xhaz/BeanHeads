// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {BHStorage} from "src/libraries/BHStorage.sol";
import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {Genesis} from "src/types/Genesis.sol";
import {IBeanHeadsMint} from "src/interfaces/IBeanHeadsMint.sol";
import {OracleLib} from "src/libraries/OracleLib.sol";

contract BeanHeadsMintFacet is ERC721AUpgradeable, IBeanHeadsMint {
    using SafeERC20 for IERC20;
    using OracleLib for AggregatorV3Interface;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Modifier to check if the token exists
    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            _revert(IBeanHeadsMint__TokenDoesNotExist.selector);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IBeanHeadsMint
    function mintGenesis(address _to, Genesis.SVGParams calldata _params, uint256 _amount, address _paymentToken)
        external
        returns (uint256 _tokenId)
    {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (_amount == 0) _revert(IBeanHeadsMint__InvalidAmount.selector);
        if (!ds.allowedTokens[_paymentToken]) _revert(IBeanHeadsMint__TokenNotAllowed.selector);

        IERC20 token = IERC20(_paymentToken);
        uint256 rawPrice = ds.mintPriceUsd * _amount;
        uint256 adjustedPrice = _getTokenAmountFromUsd(_paymentToken, rawPrice);

        _checkPaymentTokenAllowanceAndBalance(token, adjustedPrice);

        _tokenId = _nextTokenId();
        ds.tokenIdToParams[_tokenId] = _params;

        // Transfer tokens from the minter to the contract
        token.safeTransferFrom(msg.sender, address(this), adjustedPrice);

        _safeMint(_to, _amount);
        ds.tokenIdToListing[_tokenId] = BHStorage.Listing({seller: address(0), price: 0, isActive: false});
        ds.tokenIdToPaymentToken[_tokenId] = _paymentToken;
        ds.tokenIdToGeneration[_tokenId] = 1; // Set generation to 1 for Genesis
        ds.ownerTokens[_to].push(_tokenId);
        ds.authorizedBreeders[_to] = true;

        emit MintedGenesis(_to, _tokenId);
    }

    /// @inheritdoc ERC721AUpgradeable
    function burn(uint256 tokenId) external tokenExists(tokenId) {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (msg.sender != ownerOf(tokenId)) {
            _revert(IBeanHeadsMint__NotOwner.selector);
        }
        _burn(tokenId, true);

        // Remove token from owner's list
        uint256[] storage ownerTokens = ds.ownerTokens[msg.sender];
        for (uint256 i = 0; i < ownerTokens.length; i++) {
            if (ownerTokens[i] == tokenId) {
                ownerTokens[i] = ownerTokens[ownerTokens.length - 1];
                ownerTokens.pop();
                break;
            }
        }
    }

    /// @inheritdoc ERC721AUpgradeable
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (msg.sender != from && !isApprovedForAll(from, msg.sender) && getApproved(tokenId) != msg.sender) {
            _revert(IBeanHeadsMint__NotOwnerOrApproved.selector);
        }
        super.safeTransferFrom(from, to, tokenId, data);

        // Update owner's tokens
        ds.ownerTokens[to].push(tokenId);
        ds.tokenIdToListing[tokenId].isActive = false; // Deactivate listing on transfer
    }

    /// @inheritdoc ERC721AUpgradeable
    function approve(address to, uint256 tokenId) public payable override {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (msg.sender != ownerOf(tokenId)) {
            _revert(IBeanHeadsMint__NotOwner.selector);
        }
        super.approve(to, tokenId);
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

        if (answer <= 0) _revert(IBeanHeadsMint__InvalidOraclePrice.selector);

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
            _revert(IBeanHeadsMint__InsufficientAllowance.selector);
        }
        if (token.balanceOf(msg.sender) < amount) _revert(IBeanHeadsMint__InsufficientPayment.selector);
    }
}
