// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";
import {ERC721AUpgradeable} from "src/ERC721A/ERC721AUpgradeable.sol";
import {IBeanHeadsAdmin} from "src/interfaces/IBeanHeadsAdmin.sol";
import {ReentrancyLib} from "src/libraries/ReentrancyLib.sol";

contract BeanHeadsAdminFacet is ERC721AUpgradeable, IBeanHeadsAdmin {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier to check if the caller is the contract owner
    modifier onlyOwner() {
        BHStorage.enforceContractOwner();
        _;
    }

    modifier nonReentrant() {
        ReentrancyLib.enforceNotEntered();
        _;
        ReentrancyLib.resetStatus();
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBeanHeadsAdmin
    function setMintPrice(uint256 _newPrice) external onlyOwner {
        if (_newPrice <= 0) _revert(IBeanHeadsAdmin__PriceMustBeGreaterThanZero.selector);
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        ds.mintPriceUsd = _newPrice;

        emit MintPriceUpdated(_newPrice);
    }

    /// @inheritdoc IBeanHeadsAdmin
    function setAllowedToken(address _token, bool _isAllowed) external onlyOwner {
        if (_token == address(0)) _revert(IBeanHeadsAdmin__InvalidTokenAddress.selector);
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        ds.allowedTokens[_token] = _isAllowed;

        emit AllowedTokenUpdated(_token, _isAllowed);
    }

    /// @inheritdoc IBeanHeadsAdmin
    function addPriceFeed(address _token, address _priceFeed) external onlyOwner {
        if (_token == address(0) || _priceFeed == address(0)) _revert(IBeanHeadsAdmin__InvalidTokenAddress.selector);
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        ds.priceFeeds[_token] = _priceFeed;
        ds.privateFeedsAddresses.push(_priceFeed);

        emit PriceFeedAdded(_token, _priceFeed);
    }

    /// @inheritdoc IBeanHeadsAdmin
    function withdraw(address _paymentToken) external onlyOwner nonReentrant {
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        if (!ds.allowedTokens[_paymentToken]) _revert(IBeanHeadsAdmin__InvalidTokenAddress.selector);

        uint256 balance = IERC20(_paymentToken).balanceOf(address(this));
        if (balance == 0) _revert(IBeanHeadsAdmin__WithdrawFailed.selector);

        IERC20(_paymentToken).safeTransfer(msg.sender, balance);
    }

    /// @inheritdoc IBeanHeadsAdmin
    function authorizeBreeder(address _breeder) external onlyOwner {
        if (_breeder == address(0)) _revert(IBeanHeadsAdmin__InvalidAddress.selector);
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        ds.authorizedBreeders[_breeder] = true;
    }
}
