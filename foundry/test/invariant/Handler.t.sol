// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {Helpers} from "test/Helpers.sol";
import {Genesis} from "src/types/Genesis.sol";
import {CommonBase} from "forge-std/Base.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";

contract Handler is CommonBase, Helpers {
    IBeanHeads internal beanHeads;
    HelperConfig internal helperConfig;
    Helpers internal helpers;
    DeployBeanHeads internal deployBeanHeads;
    MockERC20 internal mockERC20;

    // address internal deployer;
    address internal user;
    address internal deployerAddress;

    uint256 public ghost_totalMinted;
    uint256 public ghost_totalBurned;
    uint256 public ghost_totalSold;

    Genesis.SVGParams internal defaultParams;

    constructor(address _beanHeads, address _deployer, address _user) {
        beanHeads = IBeanHeads(payable(_beanHeads));
        deployerAddress = _deployer;
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
        beanHeads.mintGenesis(user, defaultParams, amount, address(mockERC20));
        ghost_totalMinted += amount;
    }

    function sellToken(uint256 tokenId, uint256 price) public {
        uint256 nextId = beanHeads.getNextTokenId();
        if (nextId == 0) return;
        tokenId = bound(tokenId, 0, nextId - 1);
        if (!beanHeads.exists(tokenId)) return;
        if (beanHeads.getOwnerOf(tokenId) != user) return;

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

        uint256 adjustedPrice = salePrice;

        vm.startPrank(user);
        mockERC20.mint(user, adjustedPrice);
        mockERC20.approve(address(beanHeads), adjustedPrice);
        vm.stopPrank();

        payment = bound(payment, salePrice, salePrice + 0.1 ether);
        vm.deal(user, payment);
        vm.prank(user);
        beanHeads.buyToken(tokenId, address(mockERC20));
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
        if (beanHeads.getOwnerOf(tokenId) != user) return;

        vm.prank(user);
        beanHeads.burn(tokenId);
        ghost_totalBurned++;
    }
}
