// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {BeanHeads, IBeanHeads} from "src/core/BeanHeads.sol";
import {Helpers} from "test/Helpers.sol";
import {Genesis} from "src/types/Genesis.sol";
import {Vm} from "forge-std/Vm.sol";

contract BeanHeadsTest is Test, Helpers {
    BeanHeads beanHeads;

    Helpers helpers;

    address public USER = makeAddr("USER");
    address public USER2 = makeAddr("USER2");
    address public DEPLOYER = makeAddr("DEPLOYER");

    uint256 public MINT_PRICE = 0.01 ether;

    string public expectedTokenURI =
        "data:application/json;base64,eyJuYW1lIjogIkJlYW5IZWFkcyAjMCIsICJkZXNjcmlwdGlvbiI6ICJCZWFuSGVhZHMgaXMgYSBjdXN0b21pemFibGUgYXZhdGFyIG9uIGNoYWluIE5GVCBjb2xsZWN0aW9uIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjRiV3h1Y3owaWFIUjBjRG92TDNkM2R5NTNNeTV2Y21jdk1qQXdNQzl6ZG1jaUlIWnBaWGRDYjNnOUlqQWdNQ0ExTURBZ05UQXdJajQ4Y21WamRDQjNhV1IwYUQwaU5UQXdJaUJvWldsbmFIUTlJalV3TUNJZ1ptbHNiRDBpQXlJdlBqeDBaWGgwSUhnOUlqVXdKU0lnZVQwaU5UQWxJaUJrYjIxcGJtRnVkQzFpWVhObGJHbHVaVDBpYldsa1pHeGxJaUIwWlhoMExXRnVZMmh2Y2owaWJXbGtaR3hsSWlCbWIyNTBMWE5wZW1VOUlqSTBJajVDWldGdVNHVmhaSE1nUVhaaGRHRnlQQzkwWlhoMFBqd3ZjM1puUGc9PSIsICJhdHRyaWJ1dGVzIjpbeyJ0cmFpdF90eXBlIjogIkhhaXIgU3R5bGUiLCAidmFsdWUiOiAiQWZybyJ9LHsidHJhaXRfdHlwZSI6ICJIYWlyIENvbG9yIiwgInZhbHVlIjogIkJsb25kZSJ9LHsidHJhaXRfdHlwZSI6ICJBY2Nlc3NvcnkiLCAidmFsdWUiOiAiUm91bmQgR2xhc3NlcyJ9LHsidHJhaXRfdHlwZSI6ICJIYXQgU3R5bGUiLCAidmFsdWUiOiAiQmVhbmllIn0seyJ0cmFpdF90eXBlIjogIkhhdCBDb2xvciIsICJ2YWx1ZSI6ICJHcmVlbiJ9LHsidHJhaXRfdHlwZSI6ICJCb2R5IFR5cGUiLCAidmFsdWUiOiAiQnJlYXN0In0seyJ0cmFpdF90eXBlIjogIlNraW4gQ29sb3IiLCAidmFsdWUiOiAiRGFyayBTa2luIn0seyJ0cmFpdF90eXBlIjogIkNsb3RoZXMiLCAidmFsdWUiOiAiVC1TaGlydCJ9LHsidHJhaXRfdHlwZSI6ICJDbG90aGVzIENvbG9yIiwgInZhbHVlIjogIldoaXRlIn0seyJ0cmFpdF90eXBlIjogIkNsb3RoZXMgR3JhcGhpYyIsICJ2YWx1ZSI6ICJHcmFwaHFsIn0seyJ0cmFpdF90eXBlIjogIkV5ZWJyb3cgU2hhcGUiLCAidmFsdWUiOiAiTm9ybWFsIn0seyJ0cmFpdF90eXBlIjogIkV5ZSBTaGFwZSIsICJ2YWx1ZSI6ICJOb3JtYWwifSx7InRyYWl0X3R5cGUiOiAiRmFjaWFsIEhhaXIgVHlwZSIsICJ2YWx1ZSI6ICJTdHViYmxlIn0seyJ0cmFpdF90eXBlIjogIk1vdXRoIFN0eWxlIiwgInZhbHVlIjogIkxpcHMifSx7InRyYWl0X3R5cGUiOiAiTGlwIENvbG9yIiwgInZhbHVlIjogIlB1cnBsZSJ9LHsidHJhaXRfdHlwZSI6ICJMYXNoZXMiLCAidmFsdWUiOiAidHJ1ZSJ9LHsidHJhaXRfdHlwZSI6ICJHZW5lcmF0aW9uIiwgInZhbHVlIjogIjEifV19";

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event MintedGenesis(address indexed owner, uint256 indexed tokenId);

    function setUp() public {
        beanHeads = new BeanHeads(DEPLOYER);
        helpers = new Helpers();

        vm.startPrank(DEPLOYER);
        beanHeads.setRoyaltyInfo(600); // Set royalty to 6%
        vm.stopPrank();

        vm.deal(USER, 10 ether); // Give USER some ether to mint
        vm.deal(USER2, 10 ether); // Give USER2 some ether to mint
    }

    function test_InitialSetup() public view {
        string memory name = beanHeads.name();
        string memory symbol = beanHeads.symbol();

        assertEq(name, "BeanHeads");
        assertEq(symbol, "BEAN");

        // (address receiver, uint256 royaltyAmount) = beanHeads.getRoyaltyInfo(0, 10000);
    }

    function test_mintGenesis_ReturnSVGParams() public {
        vm.startPrank(USER);
        vm.recordLogs();
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
        assertEq(tokenId, 0);
        // assertTrue(tokenId > beanHeads._sequentialUpTo());

        uint256 contractBalance = address(beanHeads).balance;
        assertEq(contractBalance, MINT_PRICE);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2);

        // Decode the Transfer event
        assertEq(entries[0].topics[0], keccak256("Transfer(address,address,uint256)"));
        address from = address(uint160(uint256(entries[0].topics[1])));
        address to = address(uint160(uint256(entries[0].topics[2])));
        uint256 tid = uint256(entries[0].topics[3]);
        assertEq(from, address(0)); // Minting from zero address
        assertEq(to, USER); // Minting to USER
        assertEq(tid, tokenId);

        // Decode the MintedGenesis event
        assertEq(entries[1].topics[0], keccak256("MintedGenesis(address,uint256)"));
        address owner = address(uint160(uint256(entries[1].topics[1])));
        uint256 mintedTokenId = uint256(entries[1].topics[2]);
        assertEq(owner, USER); // Minted to USER
        assertEq(mintedTokenId, tokenId);

        Genesis.SVGParams memory svgParams = beanHeads.getAttributesByTokenId(tokenId);
        string memory svgParamsStr = helpers.getParams(svgParams);
        // console2.logString(svgParamsStr);

        string memory expected = "11312352113003113falsefalsetrue";
        assertEq(svgParamsStr, expected);
        assertEq(accessoryParams.accessoryId, 1);
        assertEq(bodyParams.bodyType, 1);
        assertEq(clothingParams.clothes, 3);
        assertEq(hairParams.hairStyle, 1);
        assertEq(clothingParams.clothesGraphic, 2);
        assertEq(facialFeaturesParams.eyebrowShape, 3);
        assertEq(facialFeaturesParams.eyeShape, 5);
        assertEq(facialFeaturesParams.facialHairType, 2);
        assertEq(accessoryParams.hatStyle, 1);
        assertEq(facialFeaturesParams.mouthStyle, 1);
        assertEq(bodyParams.skinColor, 3);
        assertEq(clothingParams.clothingColor, 0);
        assertEq(hairParams.hairColor, 0);
        assertEq(accessoryParams.hatColor, 3);
        assertEq(otherParams.shapeColor, 1);
        assertEq(facialFeaturesParams.lipColor, 1);
        assertEq(otherParams.faceMaskColor, 3);
        assertEq(otherParams.faceMask, false);
        assertEq(otherParams.shapes, false);
        assertEq(otherParams.lashes, true);

        vm.stopPrank();

        vm.prank(USER2);
        tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER2, params, 1);
        assertEq(tokenId, 1);

        vm.startPrank(DEPLOYER);
        uint256 contractBalanceBefore = address(beanHeads).balance;
        assertEq(contractBalanceBefore, MINT_PRICE * 2);
        beanHeads.withdraw();
        uint256 contractBalanceAfter = address(beanHeads).balance;
        assertEq(contractBalanceAfter, contractBalanceBefore - MINT_PRICE * 2);
        vm.stopPrank();
    }

    function test_tokenURI_ReturnsURI() public {
        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
        string memory uri = beanHeads.tokenURI(tokenId);
        console2.logString(uri);

        assertEq(uri, expectedTokenURI);
    }

    function test_PrintAttributes() public {
        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
        string memory attributes = beanHeads.getAttributes(tokenId);
        console2.logString(attributes);
    }

    function test_getOwnerTokens_ReturnsTokens() public {
        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);

        uint256[] memory tokens = beanHeads.getOwnerTokens(USER);
        // console2.logUint(tokenId);
        // console2.logUint(tokens[0]);

        assertEq(beanHeads.getOwnerTokensCount(USER), 1);
        assertEq(tokens[0], tokenId);
    }

    function test_MintTokensFuzzTest(uint256 count) public {
        bound(count, 1, 100); // Ensure count is between 1 and 100
        vm.assume(count > 0 && count <= 100);

        vm.startPrank(USER);

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
            assertEq(tokenId, i);
        }
        vm.stopPrank();
        uint256[] memory tokens = beanHeads.getOwnerTokens(USER);
        assertEq(tokens.length, count);
        for (uint256 i = 0; i < count; i++) {
            assertEq(tokens[i], i);
        }
    }

    function test_SellTokens_Success() public {
        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
        uint256 price = 1 ether;

        vm.recordLogs();
        beanHeads.sellToken(tokenId, price);
        // assertTrue(beanHeads.getTokenOnSale(tokenId, price));
        assertEq(beanHeads.getTokenSalePrice(tokenId), price);
        _assertSellLogs(tokenId, price);
        vm.stopPrank();

        vm.deal(USER2, 10 ether);
        vm.startPrank(USER2);
        uint256 salePrice = 1 ether;
        uint256 expectedRoyalty = (salePrice * 600) / 10000;

        vm.recordLogs();
        beanHeads.buyToken{value: salePrice}(tokenId, salePrice);
        _assertBuyLogs(tokenId, salePrice, expectedRoyalty);

        assertEq(beanHeads.getOwnerOf(tokenId), USER2);
        // assertFalse(beanHeads.getTokenOnSale(tokenId, salePrice));
        assertEq(beanHeads.getTokenSalePrice(tokenId), 0);

        vm.stopPrank();

        _assertAttributes(tokenId);

        vm.prank(DEPLOYER);
        _assertRoyalty(tokenId, salePrice, expectedRoyalty);
    }

    function test_CancelTokenSale_Success() public {
        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
        uint256 price = 1 ether;

        vm.recordLogs();
        beanHeads.sellToken(tokenId, price);
        // assertTrue(beanHeads.getTokenOnSale(tokenId, price));
        assertEq(beanHeads.getTokenSalePrice(tokenId), price);
        _assertSellLogs(tokenId, price);

        beanHeads.cancelTokenSale(tokenId);
        // assertTrue(beanHeads.getTokenOnSale(tokenId, price));
        assertEq(beanHeads.getTokenSalePrice(tokenId), 0);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2);

        // Transfer event
        assertEq(entries[0].topics[0], keccak256("Transfer(address,address,uint256)"));
        address from = address(uint160(uint256(entries[0].topics[1])));
        address to = address(uint160(uint256(entries[0].topics[2])));
        uint256 tid = uint256(entries[0].topics[3]);
        assertEq(from, address(beanHeads)); // Transfer from contract to USER
        assertEq(to, USER);
        assertEq(tid, tokenId);

        // TokenSaleCancelled event
        assertEq(entries[1].topics[0], keccak256("TokenSaleCancelled(address,uint256)"));
        address saleOwner = address(uint160(uint256(entries[1].topics[1])));
        uint256 cancelledTokenId = uint256(entries[1].topics[2]);
        assertEq(saleOwner, USER);
        assertEq(cancelledTokenId, tokenId);

        vm.stopPrank();
    }

    function test_setRoyaltyInfo_FailWithRevert() public {
        vm.startPrank(DEPLOYER);
        vm.expectRevert(IBeanHeads.IBeanHeads__InvalidRoyaltyFee.selector);
        beanHeads.setRoyaltyInfo(10001); // Royalty fee cannot exceed 10000 bps (100%)
        vm.stopPrank();
    }

    function test_sellToken_FailWithRevert() public {
        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
        uint256 price = 0;

        vm.expectRevert(IBeanHeads.IBeanHeads__PriceMustBeGreaterThanZero.selector);
        beanHeads.sellToken(tokenId, price);

        vm.expectRevert(IBeanHeads.IBeanHeads__TokenDoesNotExist.selector);
        beanHeads.sellToken(tokenId + 1, price); // Trying to sell a token not owned by USER

        vm.stopPrank();

        vm.startPrank(USER2);
        vm.expectRevert(IBeanHeads.IBeanHeads__NotOwner.selector);
        beanHeads.sellToken(tokenId, price); // USER2 trying to sell USER's token
        vm.stopPrank();
    }

    function test_buyToken_FailWithRevert() public {
        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
        uint256 tokenId2 = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
        uint256 price = 1 ether;

        vm.recordLogs();
        beanHeads.sellToken(tokenId, price);
        vm.stopPrank();

        vm.startPrank(USER2);
        vm.deal(USER2, 0.5 ether); // Not enough ether to buy
        vm.expectRevert(IBeanHeads.IBeanHeads__TokenDoesNotExist.selector);
        beanHeads.sellToken(tokenId + 2, price); // Trying to sell a token not owned by USER

        vm.expectRevert(IBeanHeads.IBeanHeads__InsufficientPayment.selector);
        beanHeads.buyToken(tokenId, price); // USER2 trying to buy with insufficient funds
        vm.stopPrank();

        vm.startPrank(USER2);
        vm.deal(USER2, 1 ether); // Enough ether now
        vm.expectRevert(IBeanHeads.IBeanHeads__TokenIsNotForSale.selector);
        beanHeads.buyToken(tokenId2, price); // Trying to buy a token not on sale
        vm.stopPrank();

        vm.startPrank(USER2);
        vm.deal(USER2, 10 ether); // Enough ether now
        vm.expectRevert(IBeanHeads.IBeanHeads__PriceMismatch.selector);
        beanHeads.buyToken(tokenId, price + 1 ether); // Price mismatch
        vm.stopPrank();
    }

    function test_cancelTokenSale_FailWithRevert() public {
        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis{value: MINT_PRICE}(USER, params, 1);
        uint256 price = 1 ether;

        beanHeads.sellToken(tokenId, price);
        vm.stopPrank();

        vm.startPrank(USER2);
        vm.expectRevert(IBeanHeads.IBeanHeads__NotOwner.selector);
        beanHeads.cancelTokenSale(tokenId); // USER2 trying to cancel USER's token sale
        vm.stopPrank();

        vm.startPrank(USER);
        vm.expectRevert(IBeanHeads.IBeanHeads__TokenDoesNotExist.selector);
        beanHeads.cancelTokenSale(tokenId + 1); // USER cancelling their own token sale
        vm.stopPrank();
    }

    // Helper Functions
    function _assertSellLogs(uint256 tokenId, uint256 price) internal {
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2);

        // Transfer event
        assertEq(entries[0].topics[0], keccak256("Transfer(address,address,uint256)"));
        address from = address(uint160(uint256(entries[0].topics[1])));
        address to = address(uint160(uint256(entries[0].topics[2])));
        uint256 tid = uint256(entries[0].topics[3]);
        assertEq(from, USER);
        assertEq(to, address(beanHeads));
        assertEq(tid, tokenId);

        // SetTokenPrice event
        assertEq(entries[1].topics[0], keccak256("SetTokenPrice(address,uint256,uint256)"));
        address owner = address(uint160(uint256(entries[1].topics[1])));
        uint256 setTokenId = uint256(entries[1].topics[2]);
        uint256 setPrice = abi.decode(entries[1].data, (uint256));
        assertEq(owner, USER);
        assertEq(setTokenId, tokenId);
        assertEq(setPrice, price);
    }

    function _assertBuyLogs(uint256 tokenId, uint256 salePrice, uint256 expectedRoyaltyReceived) internal {
        Vm.Log[] memory buyEntries = vm.getRecordedLogs();
        assertEq(buyEntries.length, 3);

        // RoyaltyPaid event
        {
            assertEq(buyEntries[0].topics[0], keccak256("RoyaltyPaid(address,uint256,uint256,uint256)"));
            address royaltyReceiver = address(uint160(uint256(buyEntries[0].topics[1])));
            uint256 royaltyTokenId = uint256(buyEntries[0].topics[2]);
            (uint256 salePriceReceived, uint256 royaltyAmountReceived) =
                abi.decode(buyEntries[0].data, (uint256, uint256));
            assertEq(royaltyReceiver, DEPLOYER);
            assertEq(royaltyTokenId, tokenId);
            assertEq(salePriceReceived, salePrice);
            assertEq(royaltyAmountReceived, expectedRoyaltyReceived);
        }

        // Transfer event
        {
            assertEq(buyEntries[1].topics[0], keccak256("Transfer(address,address,uint256)"));
            address buyerFrom = address(uint160(uint256(buyEntries[1].topics[1])));
            address buyerTo = address(uint160(uint256(buyEntries[1].topics[2])));
            uint256 buyerTid = uint256(buyEntries[1].topics[3]);
            assertEq(buyerFrom, address(beanHeads));
            assertEq(buyerTo, USER2);
            assertEq(buyerTid, tokenId);
        }

        // TokenSold event
        {
            assertEq(buyEntries[2].topics[0], keccak256("TokenSold(address,address,uint256,uint256)"));
            address buyer = address(uint160(uint256(buyEntries[2].topics[1])));
            address seller = address(uint160(uint256(buyEntries[2].topics[2])));
            uint256 soldTokenId = uint256(buyEntries[2].topics[3]);
            uint256 price = abi.decode(buyEntries[2].data, (uint256));
            assertEq(buyer, USER2);
            assertEq(seller, USER);
            assertEq(soldTokenId, tokenId);
            assertEq(price, salePrice);
        }
    }

    function _assertAttributes(uint256 tokenId) internal view {
        string memory tokenAttributes = beanHeads.getAttributes(tokenId);
        assertTrue(bytes(tokenAttributes).length > 0);
    }

    function _assertRoyalty(uint256 tokenId, uint256 salePrice, uint256 expectedRoyalty) internal view {
        (address receiver, uint256 royaltyAmount) = beanHeads.royaltyInfo(tokenId, salePrice);
        assertEq(receiver, DEPLOYER);
        assertEq(royaltyAmount, expectedRoyalty);
    }
}
