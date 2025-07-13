// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {BeanHeads, IBeanHeads} from "src/core/BeanHeads.sol";
import {Helpers} from "test/Helpers.sol";
import {Genesis} from "src/types/Genesis.sol";
import {CommonBase} from "forge-std/Base.sol";

contract Handler is CommonBase, Helpers {
    BeanHeads internal beanHeads;
    address internal deployer;
    address internal user;
    Helpers internal helpers;

    uint256 public ghost_totalMinted;
    uint256 public ghost_totalBurned;
    uint256 public ghost_totalSold;

    Genesis.SVGParams internal defaultParams;

    constructor(BeanHeads _beanHeads, address _deployer, address _user) {
        beanHeads = _beanHeads;
        deployer = _deployer;
        user = _user;
        helpers = new Helpers();

        (
            Genesis.HairParams memory hair,
            Genesis.BodyParams memory body,
            Genesis.ClothingParams memory clothing,
            Genesis.FacialFeaturesParams memory facialFeatures,
            Genesis.AccessoryParams memory accessory,
            Genesis.OtherParams memory other
        ) = helpers.params();

        defaultParams = Genesis.SVGParams({
            hairParams: hair,
            bodyParams: body,
            clothingParams: clothing,
            facialFeaturesParams: facialFeatures,
            accessoryParams: accessory,
            otherParams: other
        });
    }

    function mintGenesis(uint256 amount) public {
        amount = bound(amount, 1, 10);
        uint256 totalPrice = beanHeads.getMintPrice() * amount;
        vm.deal(user, totalPrice);
        vm.prank(user);
        beanHeads.mintGenesis{value: totalPrice}(user, defaultParams, amount);
        ghost_totalMinted += amount;
    }

    function sellToken(uint256 tokenId, uint256 price) public {
        uint256 nextId = beanHeads.getNextTokenId();
        if (nextId == 0) return;
        tokenId = bound(tokenId, 0, nextId - 1);
        if (!beanHeads.exists(tokenId)) return;
        if (beanHeads.ownerOf(tokenId) != user) return;

        price = bound(price, 1, 1 ether);
        vm.prank(user);
        beanHeads.sellToken(tokenId, price);
        ghost_totalSold++;
    }

    function buyToken(uint256 tokenId, uint256 payment) public {
        uint256 nextId = beanHeads.getNextTokenId();
        if (nextId == 0) return;

        tokenId = bound(tokenId, 0, nextId - 1);
        if (!beanHeads.exists(tokenId)) return;
        uint256 salePrice = beanHeads.getTokenSalePrice(tokenId);
        if (salePrice == 0) return;

        payment = bound(payment, salePrice, salePrice + 0.1 ether);
        vm.deal(user, payment);
        vm.prank(user);
        beanHeads.buyToken{value: payment}(tokenId, salePrice);
        ghost_totalSold--;
    }

    function cancelTokenSale(uint256 tokenId) public {
        uint256 nextId = beanHeads.getNextTokenId();
        if (nextId == 0) return;
        tokenId = bound(tokenId, 0, nextId - 1);
        if (!beanHeads.exists(tokenId)) return;
        if (beanHeads.getTokenSalePrice(tokenId) == 0) return;

        vm.prank(user);
        beanHeads.cancelTokenSale(tokenId);
        ghost_totalSold--;
    }

    function burn(uint256 tokenId) public {
        uint256 nextId = beanHeads.getNextTokenId();
        if (nextId == 0) return;
        tokenId = bound(tokenId, 0, nextId - 1);
        if (!beanHeads.exists(tokenId)) return;
        if (beanHeads.ownerOf(tokenId) != user) return;

        vm.prank(user);
        beanHeads.burn(tokenId);
        ghost_totalBurned++;
    }
}
