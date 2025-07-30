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

        // Transfer tokens from the minter to the contract
        token.safeTransferFrom(msg.sender, address(this), adjustedPrice);

        _safeMint(_to, _amount);
        for (uint256 i; i < _amount; i++) {
            uint256 currentTokenId = _tokenId + i;

            // Store the token parameters
            ds.tokenIdToParams[currentTokenId] = _params;
            // Initialize the token's listing and payment token
            ds.tokenIdToListing[currentTokenId] = BHStorage.Listing({seller: address(0), price: 0, isActive: false});
            // Set the payment token and generation
            ds.tokenIdToPaymentToken[currentTokenId] = _paymentToken;
            ds.tokenIdToGeneration[currentTokenId] = 1;

            // Add the token to the owner's list
            ds.ownerTokens[_to].push(currentTokenId);
        }

        emit MintedGenesis(_to, _tokenId);
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
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (msg.sender != from && !isApprovedForAll(from, msg.sender) && getApproved(tokenId) != msg.sender) {
            _revert(IBeanHeadsMint__NotOwnerOrApproved.selector);
        }
        super.safeTransferFrom(from, to, tokenId);

        // Update owner's tokens
        ds.ownerTokens[to].push(tokenId);
        ds.tokenIdToListing[tokenId].isActive = false; // Deactivate listing on transfer
    }

    /// @inheritdoc ERC721AUpgradeable
    function approve(address to, uint256 tokenId) public payable override {
        if (msg.sender != ownerOf(tokenId)) {
            _revert(IBeanHeadsMint__NotOwner.selector);
        }
        super.approve(to, tokenId);
    }

    /// @inheritdoc ERC721AUpgradeable
    function name() public view override returns (string memory) {
        return ERC721AUpgradeable.name();
    }

    /// @inheritdoc ERC721AUpgradeable
    function symbol() public view override returns (string memory) {
        return ERC721AUpgradeable.symbol();
    }

    /// @inheritdoc ERC721AUpgradeable
    function balanceOf(address owner) public view override returns (uint256) {
        return ERC721AUpgradeable.balanceOf(owner);
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
