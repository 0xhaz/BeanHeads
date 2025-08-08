// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {BeanHeadsRoyalty} from "src/core/BeanHeadsRoyalty.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {DeployBeanHeads, HelperConfig} from "script/DeployBeanHeads.s.sol";
import {Helpers} from "test/Helpers.sol";
import {Genesis} from "src/types/Genesis.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {IBeanHeadsMarketplace} from "src/interfaces/IBeanHeadsMarketplace.sol";
import {IBeanHeadsMint} from "src/interfaces/IBeanHeadsMint.sol";
import {IBeanHeadsView} from "src/interfaces/IBeanHeadsView.sol";
import {IBeanHeadsBreeding} from "src/interfaces/IBeanHeadsBreeding.sol";
import {IBeanHeadsAdmin} from "src/interfaces/IBeanHeadsAdmin.sol";
import {BeanHeadsBase} from "src/abstracts/BeanHeadsBase.sol";
import {Vm} from "forge-std/Vm.sol";

contract BeanHeadsTest is Test, Helpers {
    IBeanHeads beanHeads;
    BeanHeadsRoyalty royalty;
    MockERC20 mockERC20;
    DeployBeanHeads deployBeanHeads;
    HelperConfig helperConfig;

    Helpers helpers;

    address public USER = makeAddr("USER");
    address public USER2 = makeAddr("USER2");

    bytes32 TRANSFER_SIG = keccak256("Transfer(address,address,uint256)");
    bytes32 ROYALTY_PAID_SIG = keccak256("RoyaltyPaid(address,uint256,uint256,uint256)");
    bytes32 TOKEN_SOLD_SIG = keccak256("TokenSold(address,address,uint256,uint256)");
    bytes32 APPROVAL_SIG = keccak256("Approval(address,address,uint256)");
    bytes32 MINTED_GENESIS_SIG = keccak256("MintedGenesis(address,uint256)");

    uint256 public MINT_PRICE;
    AggregatorV3Interface priceFeed;
    uint8 tokenDecimals;
    address deployerAddress;

    string public expectedTokenURI =
        "data:application/json;base64,eyJuYW1lIjoiQmVhbkhlYWRzICMwIiwiZGVzY3JpcHRpb24iOiJCZWFuSGVhZHMgaXMgYSBjdXN0b21pemFibGUgYXZhdGFyIG9uLWNoYWluIE5GVCBjb2xsZWN0aW9uIiwiaW1hZ2UiOiJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUI0Yld4dWN6MGlhSFIwY0RvdkwzZDNkeTUzTXk1dmNtY3ZNakF3TUM5emRtY2lJSFpwWlhkQ2IzZzlJakFnTUNBMU1EQWdOVEF3SWo0OGNtVmpkQ0IzYVdSMGFEMGlOVEF3SWlCb1pXbG5hSFE5SWpVd01DSWdabWxzYkQwaUF5SXZQangwWlhoMElIZzlJalV3SlNJZ2VUMGlOVEFsSWlCa2IyMXBibUZ1ZEMxaVlYTmxiR2x1WlQwaWJXbGtaR3hsSWlCMFpYaDBMV0Z1WTJodmNqMGliV2xrWkd4bElpQm1iMjUwTFhOcGVtVTlJakkwSWo1Q1pXRnVTR1ZoWkhNZ1FYWmhkR0Z5UEM5MFpYaDBQand2YzNablBnPT0iLCJhdHRyaWJ1dGVzIjpbeyJ0cmFpdF90eXBlIjogIkhhaXIgU3R5bGUiLCAidmFsdWUiOiAiQWZybyJ9LHsidHJhaXRfdHlwZSI6ICJIYWlyIENvbG9yIiwgInZhbHVlIjogIkJsb25kZSJ9LHsidHJhaXRfdHlwZSI6ICJBY2Nlc3NvcnkiLCAidmFsdWUiOiAiUm91bmQgR2xhc3NlcyJ9LHsidHJhaXRfdHlwZSI6ICJIYXQgU3R5bGUiLCAidmFsdWUiOiAiQmVhbmllIn0seyJ0cmFpdF90eXBlIjogIkhhdCBDb2xvciIsICJ2YWx1ZSI6ICJHcmVlbiJ9LHsidHJhaXRfdHlwZSI6ICJCb2R5IFR5cGUiLCAidmFsdWUiOiAiQnJlYXN0In0seyJ0cmFpdF90eXBlIjogIlNraW4gQ29sb3IiLCAidmFsdWUiOiAiRGFyayBTa2luIn0seyJ0cmFpdF90eXBlIjogIkNsb3RoZXMiLCAidmFsdWUiOiAiVC1TaGlydCJ9LHsidHJhaXRfdHlwZSI6ICJDbG90aGVzIENvbG9yIiwgInZhbHVlIjogIldoaXRlIn0seyJ0cmFpdF90eXBlIjogIkNsb3RoZXMgR3JhcGhpYyIsICJ2YWx1ZSI6ICJHcmFwaHFsIn0seyJ0cmFpdF90eXBlIjogIkV5ZWJyb3cgU2hhcGUiLCAidmFsdWUiOiAiTm9ybWFsIn0seyJ0cmFpdF90eXBlIjogIkV5ZSBTaGFwZSIsICJ2YWx1ZSI6ICJOb3JtYWwifSx7InRyYWl0X3R5cGUiOiAiRmFjaWFsIEhhaXIgVHlwZSIsICJ2YWx1ZSI6ICJTdHViYmxlIn0seyJ0cmFpdF90eXBlIjogIk1vdXRoIFN0eWxlIiwgInZhbHVlIjogIkxpcHMifSx7InRyYWl0X3R5cGUiOiAiTGlwIENvbG9yIiwgInZhbHVlIjogIlB1cnBsZSJ9LHsidHJhaXRfdHlwZSI6ICJMYXNoZXMiLCAidmFsdWUiOiAidHJ1ZSJ9LHsidHJhaXRfdHlwZSI6ICJHZW5lcmF0aW9uIiwgInZhbHVlIjogIjEifV19";

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event MintedGenesis(address indexed owner, uint256 indexed tokenId);

    function setUp() public {
        helpers = new Helpers();
        helperConfig = new HelperConfig();
        mockERC20 = new MockERC20(1000000 ether);

        address usdcPriceFeed = helperConfig.getActiveNetworkConfig().usdPriceFeed;
        priceFeed = AggregatorV3Interface(usdcPriceFeed);
        tokenDecimals = mockERC20.decimals();

        // vm.startPrank(DEPLOYER);
        deployBeanHeads = new DeployBeanHeads();
        (address beanHeadsAddress,) = deployBeanHeads.run();
        beanHeads = IBeanHeads(beanHeadsAddress);

        mockERC20.approve(address(beanHeads), type(uint256).max); // Approve BeanHeads to spend mock ERC20 tokens

        deployerAddress = vm.addr(helperConfig.getActiveNetworkConfig().deployerKey);
        vm.startPrank(deployerAddress);
        beanHeads.setAllowedToken(address(mockERC20), true); // Allow mock ERC20 token for minting
        beanHeads.setMintPrice(1 * 1e18); // Set mint price to 0.01 ether
        beanHeads.addPriceFeed(address(mockERC20), usdcPriceFeed); // Add mock ERC20 price feed

        royalty = deployBeanHeads.royalty();
        royalty.setRoyaltyInfo(600); // Set royalty to 6%
        vm.stopPrank();

        MINT_PRICE = beanHeads.getMintPrice();

        vm.startPrank(USER);
        mockERC20.mint(USER, 100 ether);
        mockERC20.approve(address(beanHeads), type(uint256).max);
        vm.stopPrank();

        // vm.startPrank(USER2);
        // mockERC20.mint(100 ether);
        // mockERC20.approve(address(beanHeads), type(uint256).max);
        // vm.stopPrank();

        vm.deal(USER, 10 ether);
        // vm.deal(USER2, 10 ether);
    }

    function test_InitialSetup() public view {
        string memory name = beanHeads.name();
        string memory symbol = beanHeads.symbol();

        assertEq(name, "BeanHeads");
        assertEq(symbol, "BEANS");

        (address receiver, uint256 royaltyAmount) = royalty.royaltyInfo(0, 10000 ether);
        assertEq(receiver, deployerAddress);
        assertEq(royaltyAmount, 600 ether); // 6% of 10000 ether
    }

    function test_mintGenesis_ReturnSVGParams() public {
        vm.startPrank(USER);

        // Record logs before minting
        vm.recordLogs();

        // Execute mint
        uint256 tokenId = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));
        assertEq(tokenId, 0);

        // Compute expected token amount in ERC20 based on USD price
        uint256 expectedAmount = getAdjustedTokenAmount(priceFeed, MINT_PRICE, tokenDecimals);

        // Assert contract balance
        uint256 actualBalance = mockERC20.balanceOf(address(beanHeads));
        assertEq(actualBalance, expectedAmount);

        // Decode logs
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 4);

        bool foundERC20Transfer;
        bool foundERC721Transfer;
        bool foundApproval;
        bool foundMintedEvent;

        for (uint256 i = 0; i < entries.length; i++) {
            Vm.Log memory log = entries[i];

            if (log.topics[0] == TRANSFER_SIG && log.emitter == address(mockERC20)) {
                // ERC20 Transfer
                address from = address(uint160(uint256(log.topics[1])));
                address to = address(uint160(uint256(log.topics[2])));
                uint256 amount = abi.decode(log.data, (uint256));

                assertEq(from, USER);
                assertEq(to, address(beanHeads));
                assertEq(amount, expectedAmount);
                foundERC20Transfer = true;
            }

            if (log.topics[0] == TRANSFER_SIG && log.emitter == address(beanHeads)) {
                // ERC721 Transfer (mint)
                address from = address(uint160(uint256(log.topics[1])));
                address to = address(uint160(uint256(log.topics[2])));
                uint256 mintedTokenId = uint256(log.topics[3]);

                assertEq(from, address(0));
                assertEq(to, USER);
                assertEq(mintedTokenId, tokenId);
                foundERC721Transfer = true;
            }

            if (log.topics[0] == APPROVAL_SIG && log.emitter == address(mockERC20)) {
                address owner = address(uint160(uint256(log.topics[1])));
                address spender = address(uint160(uint256(log.topics[2])));
                uint256 value = abi.decode(log.data, (uint256));

                assertEq(owner, USER);
                assertEq(spender, address(beanHeads));
                assertTrue(value > expectedAmount); // could be type(uint256).max
                foundApproval = true;
            }

            if (log.topics[0] == MINTED_GENESIS_SIG && log.emitter == address(beanHeads)) {
                address owner = address(uint160(uint256(log.topics[1])));
                uint256 eventTokenId = uint256(log.topics[2]);

                assertEq(owner, USER);
                assertEq(eventTokenId, tokenId);
                foundMintedEvent = true;
            }
        }

        assertTrue(foundERC20Transfer, "ERC20 Transfer not found");
        assertTrue(foundERC721Transfer, "ERC721 Transfer not found");
        assertTrue(foundApproval, "Approval not found");
        assertTrue(foundMintedEvent, "MintedGenesis event not found");

        // SVG param validation
        Genesis.SVGParams memory svgParams = beanHeads.getAttributesByTokenId(tokenId);
        string memory svgStr = helpers.getParams(svgParams);
        assertEq(svgStr, "11312352113003113falsefalsetrue");

        assertEq(svgParams.accessoryParams.accessoryId, 1);
        assertEq(svgParams.bodyParams.bodyType, 1);
        assertEq(svgParams.clothingParams.clothes, 3);
        assertEq(svgParams.hairParams.hairStyle, 1);
        assertEq(svgParams.clothingParams.clothesGraphic, 2);
        assertEq(svgParams.facialFeaturesParams.eyebrowShape, 3);
        assertEq(svgParams.facialFeaturesParams.eyeShape, 5);
        assertEq(svgParams.facialFeaturesParams.facialHairType, 2);
        assertEq(svgParams.accessoryParams.hatStyle, 1);
        assertEq(svgParams.facialFeaturesParams.mouthStyle, 1);
        assertEq(svgParams.bodyParams.skinColor, 3);
        assertEq(svgParams.clothingParams.clothingColor, 0);
        assertEq(svgParams.hairParams.hairColor, 0);
        assertEq(svgParams.accessoryParams.hatColor, 3);
        assertEq(svgParams.otherParams.shapeColor, 1);
        assertEq(svgParams.facialFeaturesParams.lipColor, 1);
        assertEq(svgParams.otherParams.faceMaskColor, 3);
        assertEq(svgParams.otherParams.faceMask, false);
        assertEq(svgParams.otherParams.shapes, false);
        assertEq(svgParams.otherParams.lashes, true);

        vm.stopPrank();
    }

    function test_mintGenesis_MultipleAmount() public {
        vm.startPrank(USER);

        Genesis.SVGParams memory multiParams = params;
        uint256 amount = 3;
        // uint256 totalPrice = MINT_PRICE * amount;
        uint256 tokenId = beanHeads.mintGenesis(USER, multiParams, amount, address(mockERC20));
        assertEq(tokenId, 0); // First token ID should be 0
        assertEq(beanHeads.balanceOf(USER), amount); // USER should own 3 tokens
        assertEq(beanHeads.getOwnerTokensCount(USER), amount); // USER should have 3 tokens in their collection
        assertEq(beanHeads.getOwnerOf(0), USER); // First token should be owned by USER
        assertEq(beanHeads.getOwnerOf(1), USER); // Second token should be owned by USER
        assertEq(beanHeads.getOwnerOf(2), USER); // Third token should be owned by USER

        Genesis.SVGParams memory fetchedParams0 = beanHeads.getAttributesByTokenId(0);
        string memory paramsStr0 = helpers.getParams(fetchedParams0);
        assertEq(paramsStr0, helpers.getParams(multiParams));

        vm.stopPrank();
    }

    function test_tokenURI_ReturnsURI() public {
        vm.prank(USER);

        uint256 tokenId = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));
        string memory uri = beanHeads.tokenURI(tokenId);
        console2.logString(uri);

        assertEq(uri, expectedTokenURI);
    }

    function test_PrintAttributes() public {
        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));
        string memory attributes = beanHeads.getAttributes(tokenId);
        console2.logString(attributes);
    }

    function test_getOwnerTokens_ReturnsTokens() public {
        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));

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
            uint256 tokenId = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));
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
        uint256 tokenId = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));
        uint256 salePrice = 1 ether;
        beanHeads.sellToken(tokenId, salePrice);
        vm.stopPrank();

        vm.deal(USER2, 10 ether);
        vm.startPrank(USER2);
        mockERC20.approve(address(beanHeads), type(uint256).max);
        mockERC20.mint(USER2, 100 ether);
        uint256 expectedRoyalty = (salePrice * 600) / 10_000;
        vm.recordLogs();
        beanHeads.buyToken(tokenId, address(mockERC20));
        vm.stopPrank();

        Vm.Log[] memory logs = vm.getRecordedLogs();

        bool erc20Transferred;
        bool erc721Transferred;
        bool royaltyPaid;
        bool tokenSold;

        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory log = logs[i];
            if (log.topics[0] == TRANSFER_SIG && log.emitter == address(mockERC20)) {
                _checkERC20Transfer(log, USER, salePrice - expectedRoyalty);
                erc20Transferred = true;
            }
            if (log.topics[0] == TRANSFER_SIG && log.emitter == address(beanHeads)) {
                _checkERC721Transfer(log, USER2, tokenId);
                erc721Transferred = true;
            }
            if (log.topics[0] == ROYALTY_PAID_SIG && log.emitter == address(beanHeads)) {
                _checkRoyaltyPaid(log, deployerAddress, tokenId, salePrice, expectedRoyalty);
                royaltyPaid = true;
            }
            if (log.topics[0] == TOKEN_SOLD_SIG && log.emitter == address(beanHeads)) {
                _checkTokenSold(log, USER2, USER, tokenId, salePrice);
                tokenSold = true;
            }
        }

        assertTrue(erc20Transferred, "ERC20 Transfer (to seller) not found");
        assertTrue(erc721Transferred, "ERC721 Transfer (to buyer) not found");
        assertTrue(royaltyPaid, "RoyaltyPaid event not found");
        assertTrue(tokenSold, "TokenSold event not found");

        assertEq(beanHeads.getOwnerOf(tokenId), USER2);
        assertEq(beanHeads.isTokenForSale(tokenId), false);
        _assertAttributes(tokenId);

        vm.prank(deployerAddress);
        _assertRoyalty(tokenId, salePrice, expectedRoyalty);
    }

    function test_CancelTokenSale_Success() public {
        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));
        uint256 price = 1 ether;

        vm.recordLogs();
        beanHeads.sellToken(tokenId, price);
        // assertTrue(beanHeads.getTokenOnSale(tokenId, price));
        assertEq(beanHeads.getTokenSalePrice(tokenId), price);
        _assertSellLogs(tokenId, price);

        beanHeads.cancelTokenSale(tokenId);
        // assertTrue(beanHeads.getTokenOnSale(tokenId, price));
        assertEq(beanHeads.isTokenForSale(tokenId), false);

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

    function test_authorizedBreeder_Success() public {
        address breeder = makeAddr("Breeder");
        vm.startPrank(deployerAddress);
        beanHeads.authorizeBreeder(breeder);
        assertTrue(beanHeads.getAuthorizedBreeders(breeder));
        vm.stopPrank();
    }

    function test_authorizeBreeder_OnlyOwner() public {
        address breeder = makeAddr("BREEDER");
        vm.expectRevert(); // Ownable revert
        vm.prank(USER);
        beanHeads.authorizeBreeder(breeder);
    }

    function test_mintFromBreeders_Success() public {
        address breeder = makeAddr("BREEDER");
        vm.prank(deployerAddress);
        beanHeads.authorizeBreeder(breeder);

        vm.startPrank(breeder);
        vm.recordLogs();
        Genesis.SVGParams memory breedParams = params;
        uint256 generation = 2;
        uint256 tokenId = beanHeads.mintFromBreeders(USER, breedParams, generation);
        assertEq(tokenId, 0); // First token
        assertEq(beanHeads.getOwnerOf(tokenId), USER);
        assertEq(beanHeads.getGeneration(tokenId), generation);
        assertTrue(beanHeads.getAuthorizedBreeders(USER)); // Authorized after mint

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2); // Transfer and MintedNewBreed

        // Decode the MintedNewBreed event
        assertEq(entries[1].topics[0], keccak256("MintedNewBreed(address,uint256)"));
        address owner = address(uint160(uint256(entries[1].topics[1])));
        uint256 mintedTokenId = uint256(entries[1].topics[2]);
        assertEq(owner, USER);
        assertEq(mintedTokenId, tokenId);

        Genesis.SVGParams memory fetchedParams = beanHeads.getAttributesByTokenId(tokenId);
        string memory paramsStr = helpers.getParams(fetchedParams);
        assertEq(paramsStr, "11312352113003113falsefalsetrue");

        vm.stopPrank();
    }

    function test_setRoyaltyInfo_Success() public {
        vm.startPrank(deployerAddress);
        vm.recordLogs();
        uint96 newFee = 1000; // 10%
        royalty.setRoyaltyInfo(newFee);

        (address receiver, uint256 royaltyAmount) = royalty.royaltyInfo(0, 10000 ether);
        assertEq(royaltyAmount, 1000 ether);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);

        assertEq(entries[0].topics[0], keccak256("RoyaltyInfoUpdated(address,uint96)"));

        address eventReceiver = address(uint160(uint256(entries[0].topics[1])));
        uint256 eventFee = abi.decode(entries[0].data, (uint96));

        assertEq(eventReceiver, receiver);
        assertEq(eventFee, newFee);

        vm.stopPrank();
    }

    function test_getMintPrice() public view {
        assertEq(beanHeads.getMintPrice(), MINT_PRICE);
    }

    function test_setRoyaltyInfo_FailWithRevert() public {
        vm.startPrank(deployerAddress);
        vm.expectRevert(BeanHeadsRoyalty.BeanHeadsRoyalty__InvalidRoyaltyFee.selector);
        royalty.setRoyaltyInfo(10001); // Royalty fee cannot exceed 10000 bps (100%)
        vm.stopPrank();
    }

    function test_sellToken_FailWithRevert() public {
        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));
        uint256 price = 0;

        vm.expectRevert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__PriceMustBeGreaterThanZero.selector);
        beanHeads.sellToken(tokenId, price);

        vm.expectRevert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__TokenDoesNotExist.selector);
        beanHeads.sellToken(tokenId + 1, price); // Trying to sell a token not owned by USER

        vm.stopPrank();

        vm.startPrank(USER2);
        vm.expectRevert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__NotOwner.selector);
        beanHeads.sellToken(tokenId, price); // USER2 trying to sell USER's token
        vm.stopPrank();
    }

    function test_buyToken_FailWithRevert() public {
        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));
        uint256 tokenId2 = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));
        uint256 price = 1 ether;

        vm.recordLogs();
        beanHeads.sellToken(tokenId, price);
        vm.stopPrank();

        vm.startPrank(USER2);
        vm.deal(USER2, 0.5 ether); // Not enough ether to buy

        vm.expectRevert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__TokenDoesNotExist.selector);
        beanHeads.sellToken(tokenId + 2, price); // Trying to sell a token not owned by USER

        mockERC20.approve(address(beanHeads), type(uint256).max);
        vm.expectRevert(BeanHeadsBase.IBeanHeadsBase__InsufficientPayment.selector);
        beanHeads.buyToken(tokenId, address(mockERC20)); // USER2 trying to buy with insufficient funds
        vm.stopPrank();

        vm.startPrank(USER2);
        vm.deal(USER2, 1 ether); // Enough ether now
        mockERC20.approve(address(beanHeads), type(uint256).max);
        mockERC20.mint(USER2, 10 ether); // Mint some mock ERC20 tokens for USER2
        vm.expectRevert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__TokenNotForSale.selector);
        beanHeads.buyToken(tokenId2, address(mockERC20)); // Trying to buy a token not on sale
        vm.stopPrank();
    }

    function test_cancelTokenSale_FailWithRevert() public {
        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));
        uint256 price = 1 ether;

        beanHeads.sellToken(tokenId, price);
        vm.stopPrank();

        vm.startPrank(USER2);
        vm.expectRevert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__NotOwner.selector);
        beanHeads.cancelTokenSale(tokenId); // USER2 trying to cancel USER's token sale
        vm.stopPrank();

        vm.startPrank(USER);
        vm.expectRevert(IBeanHeadsMarketplace.IBeanHeadsMarketplace__TokenDoesNotExist.selector);
        beanHeads.cancelTokenSale(tokenId + 1); // USER cancelling their own token sale
        vm.stopPrank();
    }

    function test_mintGenesis_FailedWithReverts() public {
        vm.startPrank(USER2);
        mockERC20.mint(USER2, 0.5 ether); // Mint some tokens for USER2
        mockERC20.approve(address(beanHeads), type(uint256).max);
        vm.expectRevert(IBeanHeadsMint.IBeanHeadsMint__InvalidAmount.selector);
        beanHeads.mintGenesis(USER2, params, 0, address(mockERC20)); // Invalid amount of 0

        MockERC20 newMockERC20 = new MockERC20(100 ether);
        newMockERC20.mint(USER2, 100 ether);
        newMockERC20.approve(address(beanHeads), type(uint256).max);
        vm.expectRevert(IBeanHeadsMint.IBeanHeadsMint__TokenNotAllowed.selector);
        beanHeads.mintGenesis(USER2, params, 1, address(newMockERC20)); // Trying to mint with a token not allowed
        vm.stopPrank();
    }

    function test_mintFromBreeders_Unauthorized() public {
        vm.expectRevert(IBeanHeadsBreeding.IBeanHeadsBreeding__UnauthorizedBreeders.selector);
        vm.prank(USER);
        beanHeads.mintFromBreeders(USER, params, 2);
    }

    function test_withdraw_ZeroBalance() public {
        vm.startPrank(deployerAddress);
        vm.expectRevert(IBeanHeadsAdmin.IBeanHeadsAdmin__WithdrawFailed.selector);
        beanHeads.withdraw(address(mockERC20));
        vm.stopPrank();
    }

    function test_tokenURI_NonExistent() public {
        vm.expectRevert(IBeanHeadsView.IBeanHeadsView__TokenDoesNotExist.selector);
        beanHeads.tokenURI(999);
    }

    function test_getAttributesByOwner_WrongOwner() public {
        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis(USER, params, 1, address(mockERC20));

        vm.expectRevert(IBeanHeadsView.IBeanHeadsView__NotOwner.selector);
        beanHeads.getAttributesByOwner(USER2, tokenId);
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
            assertEq(royaltyReceiver, deployerAddress);
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
        (address receiver, uint256 royaltyAmount) = royalty.royaltyInfo(tokenId, salePrice);
        assertEq(receiver, deployerAddress);
        assertEq(royaltyAmount, expectedRoyalty);
    }

    function _checkERC20Transfer(Vm.Log memory log, address expectedTo, uint256 expectedAmount) internal view {
        address from = address(uint160(uint256(log.topics[1])));
        address to = address(uint160(uint256(log.topics[2])));
        uint256 amount = abi.decode(log.data, (uint256));

        if (to == expectedTo) {
            assertEq(from, address(beanHeads));
            assertEq(amount, expectedAmount);
        }
    }

    function _checkERC721Transfer(Vm.Log memory log, address expectedTo, uint256 expectedTokenId) internal view {
        address from = address(uint160(uint256(log.topics[1])));
        address to = address(uint160(uint256(log.topics[2])));
        uint256 tid = uint256(log.topics[3]);

        assertEq(from, address(beanHeads));
        assertEq(to, expectedTo);
        assertEq(tid, expectedTokenId);
    }

    function _checkRoyaltyPaid(
        Vm.Log memory log,
        address expectedReceiver,
        uint256 expectedTokenId,
        uint256 expectedSalePrice,
        uint256 expectedRoyalty
    ) internal pure {
        address receiver = address(uint160(uint256(log.topics[1])));
        uint256 tokenId1 = uint256(log.topics[2]);
        (uint256 salePrice1, uint256 royaltyAmount) = abi.decode(log.data, (uint256, uint256));

        assertEq(receiver, expectedReceiver);
        assertEq(tokenId1, expectedTokenId);
        assertEq(salePrice1, expectedSalePrice);
        assertEq(royaltyAmount, expectedRoyalty);
    }

    function _checkTokenSold(
        Vm.Log memory log,
        address expectedBuyer,
        address expectedSeller,
        uint256 expectedTokenId,
        uint256 expectedPrice
    ) internal pure {
        address buyer = address(uint160(uint256(log.topics[1])));
        address seller = address(uint160(uint256(log.topics[2])));
        uint256 tid = uint256(log.topics[3]);
        uint256 decodedPrice = abi.decode(log.data, (uint256));

        assertEq(buyer, expectedBuyer);
        assertEq(seller, expectedSeller);
        assertEq(tid, expectedTokenId);
        assertEq(decodedPrice, expectedPrice);
    }

    // helper function to convert the getMintPrice to an USD equivalent
    function getAdjustedTokenAmount(AggregatorV3Interface feed, uint256 usdAmount, uint8 tokenDecimals_)
        public
        view
        returns (uint256)
    {
        (, int256 answer,,,) = feed.latestRoundData();
        uint256 price = uint256(answer) * 1e10;
        uint256 tokenAmountIn18 = (usdAmount * 1e18) / price;

        if (tokenDecimals_ < 18) {
            return tokenAmountIn18 / (10 ** (18 - tokenDecimals_));
        } else if (tokenDecimals_ > 18) {
            return tokenAmountIn18 * (10 ** (tokenDecimals_ - 18));
        } else {
            return tokenAmountIn18;
        }
    }
}
