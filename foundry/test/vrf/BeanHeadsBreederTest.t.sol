// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {VRFCoordinatorV2_5Mock} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockLinkToken} from "chainlink-brownie-contracts/contracts/src/v0.8/mocks/MockLinkToken.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Vm} from "forge-std/Vm.sol";

import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {DeployBeanHeadsBreeder} from "script/DeployBeanHeadsBreeder.s.sol";
import {BeanHeadsBreeder} from "src/vrf/BeanHeadsBreeder.sol";
import {IBeanHeadsBreeder} from "src/interfaces/IBeanHeadsBreeder.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {Test, console} from "forge-std/Test.sol";
import {Helpers} from "test/Helpers.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";

contract BeanHeadsBreederTest is Test, Helpers {
    BeanHeadsBreeder private beanHeadsBreeder;
    // IBeanHeads private beanHeads;
    Helpers helpers;
    HelperConfig private helperConfig;
    DeployBeanHeads private deployBeanHeads;
    MockERC20 private mockERC20;
    address beanHeads;

    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");
    address public deployerAddress;
    uint256 public MINT_PRICE = 0.01 ether;
    uint256 public constant BREEDING_COOLDOWN = 50;
    uint256 public constant MAX_BREED_REQUESTS = 5;
    AggregatorV3Interface public priceFeed;
    uint8 tokenDecimals;
    uint256 tokenId;
    uint256 tokenId2;

    enum BreedingMode {
        NewBreed,
        Mutation,
        Fusion,
        Ascension
    }

    receive() external payable {}

    function setUp() public {
        helperConfig = new HelperConfig();
        helpers = new Helpers();
        mockERC20 = new MockERC20(1000 ether); // Create a mock ERC20 token with 1000 tokens

        (,, address linkToken, address usdPriceFeed, address vrfCoordinatorMock, uint256 subId, bytes32 keyHash,) =
            helperConfig.activeNetworkConfig();

        priceFeed = AggregatorV3Interface(usdPriceFeed);
        tokenDecimals = mockERC20.decimals();

        deployerAddress = vm.addr(helperConfig.getActiveNetworkConfig().deployerKey);
        deployBeanHeads = new DeployBeanHeads();
        (address beanHeadsContract,) = deployBeanHeads.run();
        beanHeads = beanHeadsContract;
        beanHeadsBreeder = new BeanHeadsBreeder(deployerAddress, address(beanHeads), vrfCoordinatorMock, subId, keyHash);

        vm.startPrank(deployerAddress); // Deployer address
        beanHeadsBreeder.acceptOwnership(); // Accept ownership of the breeder contract

        IBeanHeads(beanHeads).setAllowedToken(address(mockERC20), true);
        IBeanHeads(beanHeads).addPriceFeed(address(mockERC20), address(priceFeed));
        IBeanHeads(beanHeads).setMintPrice(1 ether);

        MockLinkToken(linkToken).setBalance(deployerAddress, 1000 ether); // Fund the deployer with LINK tokens
        MockLinkToken(linkToken).transfer(address(beanHeadsBreeder), 100 ether); // Fund the breeder contract with LINK tokens
        VRFCoordinatorV2_5Mock(vrfCoordinatorMock).fundSubscription(subId, 100 ether); // Fund the subscription with LINK tokens
        VRFCoordinatorV2_5Mock(vrfCoordinatorMock).addConsumer(subId, address(beanHeadsBreeder));
        IBeanHeads(beanHeads).authorizeBreeder(address(beanHeadsBreeder));

        IBeanHeads(beanHeads).setAllowedToken(address(mockERC20), true); // Allow the mock ERC20 token in BeanHeads
        vm.stopPrank();

        vm.startPrank(USER1);
        mockERC20.mint(100 ether);
        mockERC20.approve(address(beanHeads), type(uint256).max);
        mockERC20.approve(address(beanHeadsBreeder), type(uint256).max);
        vm.stopPrank();

        vm.deal(USER1, 100 ether);
        // vm.deal(USER2, 10 ether);
    }

    modifier MintedBeanHeads() {
        vm.startPrank(USER1);
        tokenId = IBeanHeads(beanHeads).mintGenesis(USER1, params, 1, address(mockERC20));
        tokenId2 = IBeanHeads(beanHeads).mintGenesis(USER1, params, 1, address(mockERC20));

        vm.stopPrank();
        _;
    }

    function testRequestNewBreed_PairingTokens() public MintedBeanHeads {
        vm.startPrank(USER1);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId2);

        uint256 tokenBalanceBefore = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceBefore, 2);

        vm.recordLogs();
        beanHeadsBreeder.depositBeanHeads(tokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId2);

        _assertDepositTokenLogs(tokenId, tokenId2);
        uint256 blockConfirmations = block.number + BREEDING_COOLDOWN;
        vm.roll(blockConfirmations);

        uint256 tokenBalanceAfter = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfter, 0); // Tokens should be in the breeder contract

        vm.recordLogs();
        uint256 requestId = beanHeadsBreeder.requestBreed(
            tokenId, tokenId2, IBeanHeadsBreeder.BreedingMode.NewBreed, address(mockERC20)
        );

        Vm.Log[] memory requestIdLogs = _filterLogsForBeanHeadsBreeder();
        assertEq(requestIdLogs.length, 1);

        bytes32 expectedTopic0 = keccak256("RequestBreed(address,uint256,uint256,uint256,uint8)");
        bytes32 expectedTopic1 = bytes32(uint256(uint160(USER1)));
        bytes memory expectedData =
            abi.encode(tokenId, tokenId2, requestId, uint8(IBeanHeadsBreeder.BreedingMode.NewBreed));

        assertEq(requestIdLogs[0].topics[0], expectedTopic0);
        assertEq(requestIdLogs[0].topics[1], expectedTopic1);
        assertEq(requestIdLogs[0].data, expectedData);

        // Check if the breed request is stored correctly
        IBeanHeadsBreeder.BreedRequest memory request = beanHeadsBreeder.getBreedRequest(requestId);
        assertEq(request.owner, USER1);
        assertEq(request.parent1Id, tokenId);
        assertEq(request.parent2Id, tokenId2);
        assertEq(uint8(request.mode), uint8(IBeanHeadsBreeder.BreedingMode.NewBreed));

        // Simulate the VRF response
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = VRFCoordinatorV2_5Mock(helperConfig.vrfCoordinatorMock());
        VRFCoordinatorV2_5Mock(vrfCoordinatorMock).fulfillRandomWords(requestId, address(beanHeadsBreeder));

        uint256 mintedTokenId = 2; // Assuming the new breed token ID is 2 for this test

        uint256 rarityPoints = beanHeadsBreeder.getRarityPoints(mintedTokenId);
        uint256 expectedRarityPoints = 68; // Assuming the expected rarity points for this test
        assertEq(rarityPoints, expectedRarityPoints);

        uint256 tokenBalanceAfterBreed = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfterBreed, 3); // User should have 2 tokens + 1 new breed token

        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId), 1);
        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId2), 1);

        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), mintedTokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId);
        beanHeadsBreeder.depositBeanHeads(mintedTokenId);

        uint256 blockConfirmations2 = block.number + BREEDING_COOLDOWN + 1;
        vm.roll(blockConfirmations2);

        uint256 requestId2 = beanHeadsBreeder.requestBreed(
            tokenId, mintedTokenId, IBeanHeadsBreeder.BreedingMode.NewBreed, address(mockERC20)
        );

        // Check if the breed request is stored correctly
        IBeanHeadsBreeder.BreedRequest memory request2 = beanHeadsBreeder.getBreedRequest(requestId2);
        assertEq(request2.owner, USER1);
        assertEq(request2.parent1Id, tokenId);
        assertEq(request2.parent2Id, mintedTokenId);
        assertEq(uint8(request2.mode), uint8(IBeanHeadsBreeder.BreedingMode.NewBreed));

        // Simulate the VRF response for the second breed request
        vm.recordLogs();
        vrfCoordinatorMock.fulfillRandomWords(requestId2, address(beanHeadsBreeder));

        uint256 mintedTokenId2 = 3; // Assuming the new breed token ID is 3 for this test

        uint256 rarityPoints2 = beanHeadsBreeder.getRarityPoints(mintedTokenId2);
        assertEq(rarityPoints2, 86);

        Vm.Log[] memory fulfillmentLogs = _filterLogsForBeanHeadsBreeder();
        assertEq(fulfillmentLogs.length, 2);

        // Check the first fulfillment log for the NewBreed event
        bytes32 expectedTopicNewBreed0 =
            keccak256("NewBreedCompleted(address,uint256,uint256,uint256,uint256,uint256,uint256)");
        bytes32 expectedTopicNewBreed1 = bytes32(uint256(uint160(USER1)));
        bytes32 expectedTopicNewBreed2 = bytes32(uint256(requestId2));
        bytes memory expectedDataNewBreed =
            abi.encode(request2.parent1Id, request2.parent2Id, mintedTokenId2, 3, rarityPoints2);
        assertEq(fulfillmentLogs[0].topics[0], expectedTopicNewBreed0);
        assertEq(fulfillmentLogs[0].topics[1], expectedTopicNewBreed1);
        assertEq(fulfillmentLogs[0].topics[2], expectedTopicNewBreed2);
        assertEq(fulfillmentLogs[0].data, expectedDataNewBreed);

        // Check the second fulfillment log for the BreedRequestFulfilled event
        bytes32 expectedTopicFulfilled0 = keccak256("BreedRequestFulfilled(address,uint256,uint8,uint256)");
        bytes32 expectedTopicFulfilled1 = bytes32(uint256(uint160(USER1)));
        bytes memory expectedDataFulfilled =
            abi.encode(requestId2, uint8(IBeanHeadsBreeder.BreedingMode.NewBreed), mintedTokenId2);
        assertEq(fulfillmentLogs[1].topics[0], expectedTopicFulfilled0);
        assertEq(fulfillmentLogs[1].topics[1], expectedTopicFulfilled1);
        assertEq(fulfillmentLogs[1].data, expectedDataFulfilled);

        vm.stopPrank();
    }

    function testRequestNewBreed_MutationMode() public MintedBeanHeads {
        vm.startPrank(USER1);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId2);

        uint256 tokenBalanceBefore = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceBefore, 2);

        vm.recordLogs();
        beanHeadsBreeder.depositBeanHeads(tokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId2);

        _assertDepositTokenLogs(tokenId, tokenId2);
        uint256 blockConfirmations = block.number + BREEDING_COOLDOWN;
        vm.roll(blockConfirmations);

        uint256 tokenBalanceAfter = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfter, 0); // Tokens should be in the breeder contract

        vm.recordLogs();
        uint256 requestId = beanHeadsBreeder.requestBreed(
            tokenId, tokenId2, IBeanHeadsBreeder.BreedingMode.Mutation, address(mockERC20)
        );

        Vm.Log[] memory requestIdLogs = _filterLogsForBeanHeadsBreeder();
        assertEq(requestIdLogs.length, 1);

        bytes32 expectedTopic0 = keccak256("RequestBreed(address,uint256,uint256,uint256,uint8)");
        bytes32 expectedTopic1 = bytes32(uint256(uint160(USER1)));
        bytes memory expectedData =
            abi.encode(tokenId, tokenId2, requestId, uint8(IBeanHeadsBreeder.BreedingMode.Mutation));

        assertEq(requestIdLogs[0].topics[0], expectedTopic0);
        assertEq(requestIdLogs[0].topics[1], expectedTopic1);
        assertEq(requestIdLogs[0].data, expectedData);

        // Check if the breed request is stored correctly
        IBeanHeadsBreeder.BreedRequest memory request = beanHeadsBreeder.getBreedRequest(requestId);
        assertEq(request.owner, USER1);
        assertEq(request.parent1Id, tokenId);
        assertEq(request.parent2Id, tokenId2);
        assertEq(uint8(request.mode), uint8(IBeanHeadsBreeder.BreedingMode.Mutation));

        // Simulate the VRF response
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = VRFCoordinatorV2_5Mock(helperConfig.vrfCoordinatorMock());
        VRFCoordinatorV2_5Mock(vrfCoordinatorMock).fulfillRandomWords(requestId, address(beanHeadsBreeder));
        uint256 mintedTokenId = 2; // Assuming the new breed token ID is 2 for this test

        uint256 rarityPoints = beanHeadsBreeder.getRarityPoints(mintedTokenId);
        assertEq(rarityPoints, 118);
        uint256 tokenBalanceAfterBreed = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfterBreed, 2); // User should have 1 parent tokens + 1 new breed token
        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId), 1);
        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId2), 1);

        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId2);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), mintedTokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId2);
        beanHeadsBreeder.depositBeanHeads(mintedTokenId);

        uint256 blockConfirmations2 = block.number + BREEDING_COOLDOWN + 1;
        vm.roll(blockConfirmations2);

        uint256 requestId2 = beanHeadsBreeder.requestBreed(
            tokenId2, mintedTokenId, IBeanHeadsBreeder.BreedingMode.Mutation, address(mockERC20)
        );

        // Check if the breed request is stored correctly
        IBeanHeadsBreeder.BreedRequest memory request2 = beanHeadsBreeder.getBreedRequest(requestId2);
        assertEq(request2.owner, USER1);
        assertEq(request2.parent1Id, tokenId2);
        assertEq(request2.parent2Id, mintedTokenId);
        assertEq(uint8(request2.mode), uint8(IBeanHeadsBreeder.BreedingMode.Mutation));

        // Simulate the VRF response for the second breed request
        vm.recordLogs();
        vrfCoordinatorMock.fulfillRandomWords(requestId2, address(beanHeadsBreeder));
        uint256 mintedTokenId2 = 3; // Assuming the new breed token ID is 3 for this test

        uint256 rarityPoints2 = beanHeadsBreeder.getRarityPoints(mintedTokenId2);
        assertEq(rarityPoints2, 127);

        Vm.Log[] memory fulfillmentLogs = _filterLogsForBeanHeadsBreeder();
        assertEq(fulfillmentLogs.length, 2);

        bytes32 expectedTopicMutation0 =
            keccak256("MutationCompleted(address,uint256,uint256,uint256,uint256,uint256,uint256)");
        bytes32 expectedTopicMutation1 = bytes32(uint256(uint160(USER1)));
        bytes32 expectedTopicMutation2 = bytes32(uint256(requestId2));
        bytes memory expectedDataMutation =
            abi.encode(request2.parent1Id, request2.parent2Id, mintedTokenId2, 2, rarityPoints2);
        assertEq(fulfillmentLogs[0].topics[0], expectedTopicMutation0);
        assertEq(fulfillmentLogs[0].topics[1], expectedTopicMutation1);
        assertEq(fulfillmentLogs[0].topics[2], expectedTopicMutation2);
        assertEq(fulfillmentLogs[0].data, expectedDataMutation);

        // Check the second fulfillment log for the BreedRequestFulfilled event
        bytes32 expectedTopicFulfilled0 = keccak256("BreedRequestFulfilled(address,uint256,uint8,uint256)");
        bytes32 expectedTopicFulfilled1 = bytes32(uint256(uint160(USER1)));
        bytes memory expectedDataFulfilled =
            abi.encode(requestId2, uint8(IBeanHeadsBreeder.BreedingMode.Mutation), mintedTokenId2);
        assertEq(fulfillmentLogs[1].topics[0], expectedTopicFulfilled0);
        assertEq(fulfillmentLogs[1].topics[1], expectedTopicFulfilled1);
        assertEq(fulfillmentLogs[1].data, expectedDataFulfilled);

        vm.stopPrank();
    }

    function testRequestNewBreed_FusionMode() public MintedBeanHeads {
        vm.startPrank(USER1);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId2);

        uint256 tokenBalanceBefore = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceBefore, 2);

        vm.recordLogs();
        beanHeadsBreeder.depositBeanHeads(tokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId2);

        _assertDepositTokenLogs(tokenId, tokenId2);
        uint256 blockConfirmations = block.number + BREEDING_COOLDOWN;
        vm.roll(blockConfirmations);

        uint256 tokenBalanceAfter = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfter, 0); // Tokens should be in the breeder contract

        vm.recordLogs();
        uint256 requestId =
            beanHeadsBreeder.requestBreed(tokenId, tokenId2, IBeanHeadsBreeder.BreedingMode.Fusion, address(mockERC20));

        Vm.Log[] memory requestIdLogs = _filterLogsForBeanHeadsBreeder();
        assertEq(requestIdLogs.length, 1);

        bytes32 expectedTopic0 = keccak256("RequestBreed(address,uint256,uint256,uint256,uint8)");
        bytes32 expectedTopic1 = bytes32(uint256(uint160(USER1)));
        bytes memory expectedData =
            abi.encode(tokenId, tokenId2, requestId, uint8(IBeanHeadsBreeder.BreedingMode.Fusion));

        assertEq(requestIdLogs[0].topics[0], expectedTopic0);
        assertEq(requestIdLogs[0].topics[1], expectedTopic1);
        assertEq(requestIdLogs[0].data, expectedData);

        // Check if the breed request is stored correctly
        IBeanHeadsBreeder.BreedRequest memory request = beanHeadsBreeder.getBreedRequest(requestId);
        assertEq(request.owner, USER1);
        assertEq(request.parent1Id, tokenId);
        assertEq(request.parent2Id, tokenId2);
        assertEq(uint8(request.mode), uint8(IBeanHeadsBreeder.BreedingMode.Fusion));

        // Simulate the VRF response
        vm.recordLogs();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = VRFCoordinatorV2_5Mock(helperConfig.vrfCoordinatorMock());
        VRFCoordinatorV2_5Mock(vrfCoordinatorMock).fulfillRandomWords(requestId, address(beanHeadsBreeder));

        uint256 mintedTokenId = 2; // Assuming the new breed token ID is 2 for this test

        uint256 rarityPoints = beanHeadsBreeder.getRarityPoints(mintedTokenId);
        assertEq(rarityPoints, 188);

        Vm.Log[] memory fulfillmentLogs = _filterLogsForBeanHeadsBreeder();
        assertEq(fulfillmentLogs.length, 2);

        bytes32 expectedTopicFusion0 =
            keccak256("FusionCompleted(address,uint256,uint256,uint256,uint256,uint256,uint256)");
        bytes32 expectedTopicFusion1 = bytes32(uint256(uint160(USER1)));
        bytes32 expectedTopicFusion2 = bytes32(uint256(requestId));
        bytes memory expectedDataFusion =
            abi.encode(request.parent1Id, request.parent2Id, mintedTokenId, 2, rarityPoints);
        assertEq(fulfillmentLogs[0].topics[0], expectedTopicFusion0);
        assertEq(fulfillmentLogs[0].topics[1], expectedTopicFusion1);
        assertEq(fulfillmentLogs[0].topics[2], expectedTopicFusion2);
        assertEq(fulfillmentLogs[0].data, expectedDataFusion);

        uint256 tokenBalanceAfterBreed = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfterBreed, 1); // User should have 1 parent tokens + 1 new breed token
    }

    function testRequestNewBreed_AscensionMode() public MintedBeanHeads {
        vm.startPrank(USER1);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId2);

        uint256 tokenBalanceBefore = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceBefore, 2);

        beanHeadsBreeder.depositBeanHeads(tokenId2);

        uint256 blockConfirmations = block.number + BREEDING_COOLDOWN;
        vm.roll(blockConfirmations);

        uint256 tokenBalanceAfter = IBeanHeads(beanHeads).balanceOf(USER1);
        assertEq(tokenBalanceAfter, 1);

        vm.recordLogs();
        uint256 requestId =
            beanHeadsBreeder.requestBreed(tokenId2, 0, IBeanHeadsBreeder.BreedingMode.Ascension, address(mockERC20));

        Vm.Log[] memory requestIdLogs = _filterLogsForBeanHeadsBreeder();
        assertEq(requestIdLogs.length, 1);

        bytes32 expectedTopic0 = keccak256("RequestBreed(address,uint256,uint256,uint256,uint8)");
        bytes32 expectedTopic1 = bytes32(uint256(uint160(USER1)));
        bytes memory expectedData = abi.encode(tokenId2, 0, requestId, uint8(IBeanHeadsBreeder.BreedingMode.Ascension));

        assertEq(requestIdLogs[0].topics[0], expectedTopic0);
        assertEq(requestIdLogs[0].topics[1], expectedTopic1);
        assertEq(requestIdLogs[0].data, expectedData);

        // Check if the breed request is stored correctly
        IBeanHeadsBreeder.BreedRequest memory request = beanHeadsBreeder.getBreedRequest(requestId);
        assertEq(request.owner, USER1);
        assertEq(request.parent1Id, tokenId2);
        assertEq(uint8(request.mode), uint8(IBeanHeadsBreeder.BreedingMode.Ascension));

        // Simulate the VRF response
        vm.recordLogs();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = VRFCoordinatorV2_5Mock(helperConfig.vrfCoordinatorMock());
        VRFCoordinatorV2_5Mock(vrfCoordinatorMock).fulfillRandomWords(requestId, address(beanHeadsBreeder));
        uint256 mintedTokenId = 2; // Assuming the new breed token ID is 2 for this test

        uint256 rarityPoints = beanHeadsBreeder.getRarityPoints(mintedTokenId);
        assertEq(rarityPoints, 111);

        Vm.Log[] memory fulfillmentLogs = _filterLogsForBeanHeadsBreeder();
        assertEq(fulfillmentLogs.length, 2);

        bytes32 expectedTopicAscension0 =
            keccak256("AscensionCompleted(address,uint256,uint256,uint256,uint256,uint256)");
        bytes32 expectedTopicAscension1 = bytes32(uint256(uint160(USER1)));
        bytes32 expectedTopicAscension2 = bytes32(uint256(requestId));
        bytes memory expectedDataAscension = abi.encode(request.parent1Id, mintedTokenId, 2, rarityPoints);
        assertEq(fulfillmentLogs[0].topics[0], expectedTopicAscension0);
        assertEq(fulfillmentLogs[0].topics[1], expectedTopicAscension1);
        assertEq(fulfillmentLogs[0].topics[2], expectedTopicAscension2);
        assertEq(fulfillmentLogs[0].data, expectedDataAscension);

        uint256 tokenBalanceAfterBreed = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfterBreed, 2); // User should have 1 parent tokens + 1 new breed token
        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId), 1);
        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId2), 1);
        vm.stopPrank();
    }

    function test_WithdrawTokens() public MintedBeanHeads {
        vm.startPrank(USER1);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId2);

        uint256 tokenBalanceBefore = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceBefore, 2);

        vm.recordLogs();
        beanHeadsBreeder.depositBeanHeads(tokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId2);

        assertEq(beanHeadsBreeder.s_escrowedTokens(tokenId), USER1);
        assertEq(beanHeadsBreeder.s_escrowedTokens(tokenId2), USER1);

        _assertDepositTokenLogs(tokenId, tokenId2);

        uint256 tokenBalanceAfter = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfter, 0); // Tokens should be in the breeder contract

        beanHeadsBreeder.withdrawBeanHeads(tokenId);

        vm.recordLogs();
        beanHeadsBreeder.withdrawBeanHeads(tokenId2);
        Vm.Log[] memory withdrawalLogs = _filterLogsForBeanHeadsBreeder();
        assertEq(withdrawalLogs.length, 1);

        bytes32 expectedTopic3 = keccak256("BeanHeadsWithdrawn(address,uint256)");
        bytes32 expectedTopic4 = bytes32(uint256(uint160(USER1)));
        bytes memory expectedData2 = abi.encode(tokenId2);
        assertEq(withdrawalLogs[0].topics[0], expectedTopic3);
        assertEq(withdrawalLogs[0].topics[1], expectedTopic4);
        assertEq(withdrawalLogs[0].data, expectedData2);

        uint256 tokenBalanceAfterWithdrawal = IBeanHeads(beanHeads).getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfterWithdrawal, 2); // User should have 2 tokens back
    }

    function testDepositBeanHeads_FailedWithReverts() public MintedBeanHeads {
        vm.startPrank(USER1);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId2);

        // Attempt to deposit a non-owned token
        vm.expectRevert(IBeanHeadsBreeder.IBeanHeadsBreeder__InvalidTokenId.selector);
        beanHeadsBreeder.depositBeanHeads(9999); // Non-existent token ID

        // Attempt to deposit a token that is not the owner
        vm.stopPrank();
        vm.startPrank(USER2);
        vm.expectRevert(IBeanHeadsBreeder.IBeanHeadsBreeder__NotOwner.selector);
        beanHeadsBreeder.depositBeanHeads(tokenId); // USER2 tries to deposit USER1
    }

    function testWithdrawTokens_FailedWithReverts() public MintedBeanHeads {
        vm.startPrank(USER1);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId2);

        // Deposit tokens
        beanHeadsBreeder.depositBeanHeads(tokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId2);

        // Attempt to withdraw a token that is not the owner
        vm.stopPrank();
        vm.startPrank(USER2);
        vm.expectRevert(IBeanHeadsBreeder.IBeanHeadsBreeder__TokensNotEscrowedBySender.selector);
        beanHeadsBreeder.withdrawBeanHeads(tokenId); // USER2 tries to withdraw USER1's token
        vm.stopPrank();
    }

    function testRequestBreed_FailedWithReverts() public MintedBeanHeads {
        vm.startPrank(USER1);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId2);

        // Deposit tokens
        beanHeadsBreeder.depositBeanHeads(tokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId2);

        // Attempt to request breed with a Ascension mode without a second token
        vm.expectRevert(IBeanHeadsBreeder.IBeanHeadsBreeder__InvalidRequestId.selector);
        beanHeadsBreeder.requestBreed(tokenId, tokenId2, IBeanHeadsBreeder.BreedingMode.Ascension, address(mockERC20));

        // Attempt to request breed with the same token
        vm.expectRevert(IBeanHeadsBreeder.IBeanHeadsBreeder__CannotBreedSameBeanHead.selector);
        beanHeadsBreeder.requestBreed(tokenId, tokenId, IBeanHeadsBreeder.BreedingMode.NewBreed, address(mockERC20));
        vm.stopPrank();
        vm.startPrank(USER2);
        mockERC20.mint(2 ether); // Mint some mock ERC20 tokens for USER2
        mockERC20.approve(address(beanHeadsBreeder), type(uint256).max);
        mockERC20.approve(address(beanHeads), type(uint256).max);

        vm.expectRevert(IBeanHeadsBreeder.IBeanHeadsBreeder__TokensNotEscrowedBySender.selector);
        beanHeadsBreeder.requestBreed(tokenId, tokenId2, IBeanHeadsBreeder.BreedingMode.NewBreed, address(mockERC20)); // USER2 tries to breed USER1's tokens

        uint256 t1 = IBeanHeads(address(beanHeads)).mintGenesis(USER2, params, 1, address(mockERC20));
        uint256 t2 = IBeanHeads(address(beanHeads)).mintGenesis(USER2, params, 1, address(mockERC20));

        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), t1);
        IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), t2);

        // Deposit tokens for USER2
        beanHeadsBreeder.depositBeanHeads(t1);
        beanHeadsBreeder.depositBeanHeads(t2);

        assertEq(beanHeadsBreeder.getEscrowedTokenOwner(t1), USER2);
        assertEq(beanHeadsBreeder.getEscrowedTokenOwner(t2), USER2);

        uint256 lastBlock = block.number;
        vm.roll(lastBlock + BREEDING_COOLDOWN + 1);
        // Attempt to request breed with insufficient ether
        vm.expectRevert(IBeanHeadsBreeder.IBeanHeadsBreeder__InsufficientBalance.selector);
        beanHeadsBreeder.requestBreed(t1, t2, IBeanHeadsBreeder.BreedingMode.NewBreed, address(mockERC20));
        vm.stopPrank();

        vm.startPrank(USER2);

        mockERC20.approve(address(beanHeadsBreeder), type(uint256).max);
        mockERC20.approve(address(beanHeads), type(uint256).max);
        mockERC20.mint(100 ether); // Mint some mock ERC20 tokens for USER2

        beanHeadsBreeder.requestBreed(t1, t2, IBeanHeadsBreeder.BreedingMode.NewBreed, address(mockERC20));
        // Attempt to request breed with prior block.number
        vm.roll(lastBlock + BREEDING_COOLDOWN - 1); // Roll back to the block before the cooldown period
        vm.expectRevert(IBeanHeadsBreeder.IBeanHeadsBreeder__CoolDownNotPassed.selector);
        beanHeadsBreeder.requestBreed(t1, t2, IBeanHeadsBreeder.BreedingMode.NewBreed, address(mockERC20));
        vm.stopPrank();
    }

    function testRequestBreed_FailedWithReverts_BreedMaxLimit() public MintedBeanHeads {
        vm.startPrank(USER1);
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = VRFCoordinatorV2_5Mock(helperConfig.vrfCoordinatorMock());
        uint256 reqId;
        uint256 lastBlock = block.number;

        for (uint256 i = 0; i < MAX_BREED_REQUESTS; i++) {
            IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId);
            IBeanHeads(beanHeads).approve(address(beanHeadsBreeder), tokenId2);

            // Deposit tokens
            beanHeadsBreeder.depositBeanHeads(tokenId);
            beanHeadsBreeder.depositBeanHeads(tokenId2);

            // increase the block number to ensure enough confirmations for each breed request
            lastBlock = lastBlock + BREEDING_COOLDOWN + 1000;
            vm.roll(lastBlock);

            reqId = beanHeadsBreeder.requestBreed(
                tokenId, tokenId2, IBeanHeadsBreeder.BreedingMode.NewBreed, address(mockERC20)
            );

            VRFCoordinatorV2_5Mock(vrfCoordinatorMock).fulfillRandomWords(reqId, address(beanHeadsBreeder));
        }

        vm.roll(lastBlock + BREEDING_COOLDOWN + 1); // Roll to the next block after the last breeding block

        // Attempt to request breed with max breeding count
        vm.expectRevert(IBeanHeadsBreeder.IBeanHeadsBreeder__BreedLimitReached.selector);
        beanHeadsBreeder.requestBreed(tokenId, tokenId2, IBeanHeadsBreeder.BreedingMode.NewBreed, address(mockERC20));
        vm.stopPrank();

        vm.startPrank(deployerAddress);
        // Withdraw balance from the breeder contract
        uint256 breederBalance = address(beanHeadsBreeder).balance;
        beanHeadsBreeder.withdrawFunds(address(mockERC20));
        uint256 userBalanceAfter = address(deployerAddress).balance;
        assertEq(userBalanceAfter, breederBalance);
        assertEq(address(beanHeadsBreeder).balance, 0); // Ensure the breeder contract balance is zero after withdrawal
        vm.stopPrank();
    }

    // Helper functions
    /// @notice Helper function of recorded logs
    function _assertDepositTokenLogs(uint256 token1Id, uint256 token2Id) internal {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 4);

        bytes32 TRANSFER_EVENT_SELECTOR = keccak256("Transfer(address,address,uint256)");
        bytes32 DEPOSIT_EVENT_SELECTOR = keccak256("BeanHeadsDeposited(address,uint256)");

        // First Transfer
        assertEq(logs[0].topics[0], TRANSFER_EVENT_SELECTOR);
        address from1 = address(uint160(uint256(logs[0].topics[1])));
        address to1 = address(uint160(uint256(logs[0].topics[2])));
        uint256 tid1 = uint256(logs[0].topics[3]);
        assertEq(from1, USER1);
        assertEq(to1, address(beanHeadsBreeder));
        assertEq(tid1, token1Id);

        // First Deposit
        assertEq(logs[1].topics[0], DEPOSIT_EVENT_SELECTOR);
        address owner1 = address(uint160(uint256(logs[1].topics[1])));
        uint256 deposited1 = uint256(bytes32(logs[1].data));
        assertEq(owner1, USER1);
        assertEq(deposited1, token1Id);

        // Second Transfer
        assertEq(logs[2].topics[0], TRANSFER_EVENT_SELECTOR);
        address from2 = address(uint160(uint256(logs[2].topics[1])));
        address to2 = address(uint160(uint256(logs[2].topics[2])));
        uint256 tid2 = uint256(logs[2].topics[3]);
        assertEq(from2, USER1);
        assertEq(to2, address(beanHeadsBreeder));
        assertEq(tid2, token2Id);

        // Second Deposit
        assertEq(logs[3].topics[0], DEPOSIT_EVENT_SELECTOR);
        address owner2 = address(uint160(uint256(logs[3].topics[1])));
        uint256 deposited2 = uint256(bytes32(logs[3].data));
        assertEq(owner2, USER1);
        assertEq(deposited2, token2Id);
    }

    /// @notice Helper function to filter logs only for the BeanHeadsBreeder contract
    function _filterLogsForBeanHeadsBreeder() internal returns (Vm.Log[] memory logs) {
        Vm.Log[] memory allLogs = vm.getRecordedLogs();
        uint256 count = 0;
        for (uint256 i = 0; i < allLogs.length; i++) {
            if (allLogs[i].emitter == address(beanHeadsBreeder)) {
                count++;
            }
        }
        logs = new Vm.Log[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allLogs.length; i++) {
            if (allLogs[i].emitter == address(beanHeadsBreeder)) {
                logs[index] = allLogs[i];
                index++;
            }
        }
    }
}
