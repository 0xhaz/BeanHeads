// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {BeanHeads, IBeanHeads} from "src/core/BeanHeads.sol";
import {Helpers} from "test/Helpers.sol";
import {Genesis} from "src/types/Genesis.sol";
import {Handler} from "test/invariant/Handler.t.sol";
import {Vm} from "forge-std/Vm.sol";

contract BeanHeadsInvariantTest is Test {
    BeanHeads internal beanHeads;
    Handler internal handler;
    Helpers internal helpers;

    address internal USER = makeAddr("user");
    address internal USER2 = makeAddr("user2");
    address internal DEPLOYER = makeAddr("deployer");

    uint256 internal constant MINT_PRICE = 0.01 ether;

    uint8 internal constant HAIR_STYLE_MAX_VALUE = 6;
    uint8 internal constant HAIR_COLOR_MAX_VALUE = 5;
    uint8 internal constant ACCESSORY_MAX_VALUE = 3;
    uint8 internal constant BODY_TYPE_MAX_VALUE = 2;
    uint8 internal constant BODY_COLOR_MAX_VALUE = 5;
    uint8 internal constant CLOTH_COLOR_MAX_VALUE = 4;
    uint8 internal constant CLOTHES_TYPE_MAX_VALUE = 5;
    uint8 internal constant CLOTHES_GRAPHIC_MAX_VALUE = 5;
    uint8 internal constant EYEBROW_TYPE_MAX_VALUE = 4;
    uint8 internal constant EYE_TYPE_MAX_VALUE = 8;
    uint8 internal constant FACIAL_HAIR_TYPE_MAX_VALUE = 2;
    uint8 internal constant HAT_COLOR_MAX_VALUE = 4;
    uint8 internal constant HAT_STYLE_MAX_VALUE = 2;
    uint8 internal constant LIPS_COLOR_MAX_VALUE = 4;
    uint8 internal constant MOUTH_TYPE_MAX_VALUE = 6;
    uint8 internal constant OPT_COLOR_MAX_VALUE = 4;
    uint8 internal constant BREAST_COLOR_MAX_VALUE = 5;

    Genesis.SVGParams internal params;

    function setUp() public {
        beanHeads = new BeanHeads(DEPLOYER);
        helpers = new Helpers();
        handler = new Handler(beanHeads, DEPLOYER, USER);

        (
            Genesis.HairParams memory hair,
            Genesis.BodyParams memory body,
            Genesis.ClothingParams memory clothing,
            Genesis.FacialFeaturesParams memory facialFeatures,
            Genesis.AccessoryParams memory accessory,
            Genesis.OtherParams memory other
        ) = helpers.params();
        params = Genesis.SVGParams({
            hairParams: hair,
            bodyParams: body,
            clothingParams: clothing,
            facialFeaturesParams: facialFeatures,
            accessoryParams: accessory,
            otherParams: other
        });

        vm.startPrank(DEPLOYER);
        beanHeads.setRoyaltyInfo(600);
        beanHeads.authorizeBreeder(address(handler));
        vm.stopPrank();

        vm.deal(USER, 1000 ether);
        vm.deal(USER2, 1000 ether);
        vm.deal(DEPLOYER, 1000 ether);

        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = Handler.mintGenesis.selector;
        selectors[1] = Handler.sellToken.selector;
        selectors[2] = Handler.buyToken.selector;
        selectors[3] = Handler.cancelTokenSale.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function test_fuzzMintGenesis(uint256 amount) public {
        amount = bound(amount, 1, 100);
        vm.startPrank(USER);
        uint256 totalPrice = beanHeads.getMintPrice() * amount;
        uint256 firstTokenId = beanHeads.mintGenesis{value: totalPrice}(USER, params, amount);
        assertEq(beanHeads.balanceOf(USER), amount);
        for (uint256 i = 0; i < amount; i++) {
            assertEq(beanHeads.getOwnerOf(firstTokenId + i), USER);
        }
    }

    function test_fuzzMintHairParams(uint8 hairStyle, uint8 hairColor) public {
        Genesis.SVGParams memory fparams = params;
        fparams.hairParams = _makeHairParams(hairStyle, hairColor);

        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, fparams, 1);
        Genesis.SVGParams memory storedParams = beanHeads.getAttributesByTokenId(tokenId);

        assertEq(storedParams.hairParams.hairStyle, fparams.hairParams.hairStyle);
        assertEq(storedParams.hairParams.hairColor, fparams.hairParams.hairColor);
    }

    function test_fuzzMintAccessoryParams(uint8 accessoryId, uint8 hatStyle, uint8 hatColor) public {
        Genesis.SVGParams memory fparams = params;
        fparams.accessoryParams = _makeAccessoryParams(accessoryId, hatStyle, hatColor);

        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, fparams, 1);
        Genesis.SVGParams memory storedParams = beanHeads.getAttributesByTokenId(tokenId);

        assertEq(storedParams.accessoryParams.accessoryId, fparams.accessoryParams.accessoryId);
        assertEq(storedParams.accessoryParams.hatStyle, fparams.accessoryParams.hatStyle);
        assertEq(storedParams.accessoryParams.hatColor, fparams.accessoryParams.hatColor);
    }

    function test_fuzzMintBodyParams(uint8 bodyType, uint8 skinColor) public {
        Genesis.SVGParams memory fparams = params;
        fparams.bodyParams = _makeBodyParams(bodyType, skinColor);

        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, fparams, 1);
        Genesis.SVGParams memory storedParams = beanHeads.getAttributesByTokenId(tokenId);

        assertEq(storedParams.bodyParams.bodyType, fparams.bodyParams.bodyType);
        assertEq(storedParams.bodyParams.skinColor, fparams.bodyParams.skinColor);
    }

    function test_fuzzMintClothingParams(uint8 clothes, uint8 clothesColor, uint8 clothesGraphic) public {
        Genesis.SVGParams memory fparams = params;
        fparams.clothingParams = _makeClothingParams(clothes, clothesColor, clothesGraphic);

        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, fparams, 1);
        Genesis.SVGParams memory storedParams = beanHeads.getAttributesByTokenId(tokenId);

        assertEq(storedParams.clothingParams.clothes, fparams.clothingParams.clothes);
        assertEq(storedParams.clothingParams.clothingColor, fparams.clothingParams.clothingColor);
        assertEq(storedParams.clothingParams.clothesGraphic, fparams.clothingParams.clothesGraphic);
    }

    function test_fuzzMintFacialFeaturesParams(
        uint8 eyebrowShape,
        uint8 eyeShape,
        uint8 facialHairType,
        uint8 mouthStyle,
        uint8 lipColor
    ) public {
        Genesis.SVGParams memory fparams = params;
        fparams.facialFeaturesParams =
            _makeFacialFeaturesParams(eyebrowShape, eyeShape, facialHairType, mouthStyle, lipColor);

        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, fparams, 1);
        Genesis.SVGParams memory storedParams = beanHeads.getAttributesByTokenId(tokenId);

        assertEq(storedParams.facialFeaturesParams.eyebrowShape, fparams.facialFeaturesParams.eyebrowShape);
        assertEq(storedParams.facialFeaturesParams.eyeShape, fparams.facialFeaturesParams.eyeShape);
        assertEq(storedParams.facialFeaturesParams.facialHairType, fparams.facialFeaturesParams.facialHairType);
        assertEq(storedParams.facialFeaturesParams.mouthStyle, fparams.facialFeaturesParams.mouthStyle);
        assertEq(storedParams.facialFeaturesParams.lipColor, fparams.facialFeaturesParams.lipColor);
    }

    function test_fuzzMintOtherParams(uint8 shapeColor, uint8 faceMaskColor, bool faceMask, bool shapes, bool lashes)
        public
    {
        Genesis.SVGParams memory fparams = params;
        fparams.otherParams = _makeOtherParams(shapeColor, faceMaskColor, faceMask, shapes, lashes);

        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, fparams, 1);
        Genesis.SVGParams memory storedParams = beanHeads.getAttributesByTokenId(tokenId);

        assertEq(storedParams.otherParams.shapeColor, fparams.otherParams.shapeColor);
        assertEq(storedParams.otherParams.faceMaskColor, fparams.otherParams.faceMaskColor);
        assertEq(storedParams.otherParams.faceMask, fparams.otherParams.faceMask);
        assertEq(storedParams.otherParams.shapes, fparams.otherParams.shapes);
        assertEq(storedParams.otherParams.lashes, fparams.otherParams.lashes);
    }

    function _makeHairParams(uint8 hairStyle, uint8 hairColor) internal pure returns (Genesis.HairParams memory) {
        return Genesis.HairParams({
            hairStyle: uint8(bound(hairStyle, 0, HAIR_STYLE_MAX_VALUE)),
            hairColor: uint8(bound(hairColor, 0, HAIR_COLOR_MAX_VALUE))
        });
    }

    function _makeAccessoryParams(uint8 accessoryId, uint8 hatStyle, uint8 hatColor)
        internal
        pure
        returns (Genesis.AccessoryParams memory)
    {
        return Genesis.AccessoryParams({
            accessoryId: uint8(bound(accessoryId, 0, ACCESSORY_MAX_VALUE)),
            hatStyle: uint8(bound(hatStyle, 0, HAT_STYLE_MAX_VALUE)),
            hatColor: uint8(bound(hatColor, 0, HAT_COLOR_MAX_VALUE))
        });
    }

    function _makeBodyParams(uint8 bodyType, uint8 skinColor) internal pure returns (Genesis.BodyParams memory) {
        return Genesis.BodyParams({
            bodyType: uint8(bound(bodyType, 1, BODY_TYPE_MAX_VALUE)),
            skinColor: uint8(bound(skinColor, 0, BODY_COLOR_MAX_VALUE))
        });
    }

    function _makeClothingParams(uint8 clothes, uint8 clothesColor, uint8 clothesGraphic)
        internal
        pure
        returns (Genesis.ClothingParams memory)
    {
        return Genesis.ClothingParams({
            clothes: uint8(bound(clothes, 0, CLOTHES_TYPE_MAX_VALUE)),
            clothingColor: uint8(bound(clothesColor, 0, CLOTH_COLOR_MAX_VALUE)),
            clothesGraphic: uint8(bound(clothesGraphic, 0, CLOTHES_GRAPHIC_MAX_VALUE))
        });
    }

    function _makeFacialFeaturesParams(
        uint8 eyebrowShape,
        uint8 eyeShape,
        uint8 facialHairType,
        uint8 mouthStyle,
        uint8 lipColor
    ) internal pure returns (Genesis.FacialFeaturesParams memory) {
        return Genesis.FacialFeaturesParams({
            eyebrowShape: uint8(bound(eyebrowShape, 0, EYEBROW_TYPE_MAX_VALUE)),
            eyeShape: uint8(bound(eyeShape, 0, EYE_TYPE_MAX_VALUE)),
            facialHairType: uint8(bound(facialHairType, 0, FACIAL_HAIR_TYPE_MAX_VALUE)),
            mouthStyle: uint8(bound(mouthStyle, 0, MOUTH_TYPE_MAX_VALUE)),
            lipColor: uint8(bound(lipColor, 0, LIPS_COLOR_MAX_VALUE))
        });
    }

    function _makeOtherParams(uint8 shapeColor, uint8 faceMaskColor, bool faceMask, bool shapes, bool lashes)
        internal
        pure
        returns (Genesis.OtherParams memory)
    {
        return Genesis.OtherParams({
            shapeColor: uint8(bound(shapeColor, 0, OPT_COLOR_MAX_VALUE)),
            faceMaskColor: uint8(bound(faceMaskColor, 0, OPT_COLOR_MAX_VALUE)),
            faceMask: faceMask,
            shapes: shapes,
            lashes: lashes
        });
    }

    function test_fuzzSellPrice(uint256 price) public {
        price = bound(price, 1, 10 ether);

        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
        beanHeads.sellToken(tokenId, price);
        assertEq(beanHeads.getTokenSalePrice(tokenId), price);
        assertEq(beanHeads.ownerOf(tokenId), address(beanHeads));
        vm.stopPrank();
    }

    function test_fuzzBuyPayment(uint256 salePrice, uint256 payment) public {
        salePrice = bound(salePrice, 1, 10 ether);
        payment = bound(payment, salePrice, salePrice + 0.1 ether);

        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
        beanHeads.sellToken(tokenId, salePrice);
        vm.stopPrank();

        uint256 royalty = (salePrice * 600) / 10_000;
        uint256 sellerReceive = salePrice - royalty;

        uint256 deployerBalanceBefore = DEPLOYER.balance;
        uint256 userBalanceBefore = USER.balance;
        uint256 buyerBalanceBefore = USER2.balance;

        vm.prank(USER2);
        beanHeads.buyToken{value: payment}(tokenId, salePrice);

        assertEq(beanHeads.ownerOf(tokenId), USER2);
        assertEq(beanHeads.getTokenSalePrice(tokenId), 0);

        assertEq(DEPLOYER.balance, deployerBalanceBefore + royalty);
        assertEq(USER.balance, userBalanceBefore + sellerReceive);
        assertEq(USER2.balance, buyerBalanceBefore - salePrice);
    }

    function invariant_TotalSupplyMatchesMinted() public view {
        assertEq(beanHeads.totalSupply(), handler.ghost_totalMinted() - handler.ghost_totalBurned());
    }

    function invariant_TokensOnSaleOwnedByContract() public view {
        uint256 nextId = beanHeads.getNextTokenId();
        for (uint256 tokenId = 0; tokenId < nextId; tokenId++) {
            if (beanHeads.exists(tokenId)) {
                if (beanHeads.getTokenSalePrice(tokenId) > 0) {
                    assertEq(beanHeads.ownerOf(tokenId), address(beanHeads));
                } else {
                    assertNotEq(beanHeads.ownerOf(tokenId), address(beanHeads));
                }
            }
        }
    }

    function invariant_RoyaltyCalculation() public view {
        uint256 samplesalePrice = 1 ether;
        (address receiver, uint256 amount) = beanHeads.royaltyInfo(0, samplesalePrice);
        assertEq(receiver, DEPLOYER);
        assertEq(amount, (samplesalePrice * 600) / 10_000);
    }

    function invariant_NoTokenOwnedByZero() public view {
        uint256 nextId = beanHeads.getNextTokenId();
        for (uint256 tokenId = 0; tokenId < nextId; tokenId++) {
            if (beanHeads.exists(tokenId)) {
                assertNotEq(beanHeads.ownerOf(tokenId), address(0));
            }
        }
    }
}
