// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {VRFCoordinatorV2_5Mock} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockLinkToken} from "chainlink-brownie-contracts/contracts/src/v0.8/mocks/MockLinkToken.sol";
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

contract BeanHeadsBreederTest is Test, Helpers {
    BeanHeadsBreeder private beanHeadsBreeder;
    IBeanHeads private beanHeads;
    Helpers helpers;
    HelperConfig private helperConfig;

    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");
    uint256 public MINT_PRICE = 0.01 ether;
    uint256 public constant BREEDING_COOLDOWN = 50;

    uint256 tokenId;
    uint256 tokenId2;

    enum BreedingMode {
        NewBreed,
        Mutation,
        Fusion,
        Ascension
    }

    function setUp() public {
        helperConfig = new HelperConfig();
        helpers = new Helpers();

        (,, address linkToken, address vrfCoordinatorMock, uint256 subId, bytes32 keyHash,) =
            helperConfig.activeNetworkConfig();
        DeployBeanHeads deployBeanHeads = new DeployBeanHeads();
        beanHeads = deployBeanHeads.run();
        beanHeadsBreeder = new BeanHeadsBreeder(address(beanHeads), address(vrfCoordinatorMock), subId, keyHash);

        vm.startPrank(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38); // Deployer address
        MockLinkToken(linkToken).transfer(address(beanHeadsBreeder), 10 ether); // Fund the breeder contract with LINK tokens
        VRFCoordinatorV2_5Mock(vrfCoordinatorMock).fundSubscription(subId, 10 ether); // Fund the subscription with LINK tokens
        VRFCoordinatorV2_5Mock(vrfCoordinatorMock).addConsumer(subId, address(beanHeadsBreeder));
        vm.stopPrank();

        beanHeads.authorizeBreeder(address(beanHeadsBreeder));

        vm.deal(USER1, 10 ether);
        vm.deal(USER2, 10 ether);
    }

    modifier MintedBeanHeads() {
        vm.startPrank(USER1);
        tokenId = IBeanHeads(address(beanHeads)).mintGenesis{value: MINT_PRICE}(USER1, params, 1);
        tokenId2 = IBeanHeads(address(beanHeads)).mintGenesis{value: MINT_PRICE}(USER1, params, 1);
        console.log("Minted tokenId: ", tokenId);
        console.log("Minted tokenId2: ", tokenId2);
        vm.stopPrank();
        _;
    }

    function testRequestNewBreed_PairingTokens() public MintedBeanHeads {
        vm.startPrank(USER1);
        beanHeads.approve(address(beanHeadsBreeder), tokenId);
        beanHeads.approve(address(beanHeadsBreeder), tokenId2);
        console.log("Approving tokens for breeding: ", tokenId, tokenId2);

        uint256 tokenBalanceBefore = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceBefore, 2);

        vm.recordLogs();
        beanHeadsBreeder.depositBeanHeads(tokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId2);

        _assertDepositTokenLogs(tokenId, tokenId2);
        uint256 blockConfirmations = block.number + BREEDING_COOLDOWN;
        vm.roll(blockConfirmations);

        uint256 tokenBalanceAfter = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfter, 0); // Tokens should be in the breeder contract

        vm.recordLogs();
        uint256 requestId =
            beanHeadsBreeder.requestBreed{value: MINT_PRICE}(tokenId, tokenId2, IBeanHeadsBreeder.BreedingMode.NewBreed);

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
        string memory newParams = IBeanHeads(address(beanHeads)).getAttributes(mintedTokenId);
        console.log(newParams);

        uint256 rarityPoints = beanHeadsBreeder.getRarityPoints(mintedTokenId);
        uint256 expectedRarityPoints = 68; // Assuming the expected rarity points for this test
        assertEq(rarityPoints, expectedRarityPoints);

        uint256 tokenBalanceAfterBreed = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfterBreed, 3); // User should have 2 tokens + 1 new breed token

        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId), 1);
        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId2), 1);

        beanHeads.approve(address(beanHeadsBreeder), tokenId);
        beanHeads.approve(address(beanHeadsBreeder), mintedTokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId);
        beanHeadsBreeder.depositBeanHeads(mintedTokenId);

        uint256 blockConfirmations2 = block.number + BREEDING_COOLDOWN + 1;
        vm.roll(blockConfirmations2);

        uint256 requestId2 = beanHeadsBreeder.requestBreed{value: MINT_PRICE}(
            tokenId, mintedTokenId, IBeanHeadsBreeder.BreedingMode.NewBreed
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
        string memory newParams2 = IBeanHeads(address(beanHeads)).getAttributes(mintedTokenId2);
        console.log(newParams2);

        uint256 rarityPoints2 = beanHeadsBreeder.getRarityPoints(mintedTokenId2);
        assertEq(rarityPoints2, 86);

        Vm.Log[] memory fulfillmentLogs = _filterLogsForBeanHeadsBreeder();
        assertEq(fulfillmentLogs.length, 2);
        console.logBytes(fulfillmentLogs[0].data);

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
        beanHeads.approve(address(beanHeadsBreeder), tokenId);
        beanHeads.approve(address(beanHeadsBreeder), tokenId2);
        console.log("Approving tokens for breeding: ", tokenId, tokenId2);

        uint256 tokenBalanceBefore = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceBefore, 2);

        vm.recordLogs();
        beanHeadsBreeder.depositBeanHeads(tokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId2);

        _assertDepositTokenLogs(tokenId, tokenId2);
        uint256 blockConfirmations = block.number + BREEDING_COOLDOWN;
        vm.roll(blockConfirmations);

        uint256 tokenBalanceAfter = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfter, 0); // Tokens should be in the breeder contract

        vm.recordLogs();
        uint256 requestId =
            beanHeadsBreeder.requestBreed{value: MINT_PRICE}(tokenId, tokenId2, IBeanHeadsBreeder.BreedingMode.Mutation);

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
        string memory newParams = IBeanHeads(address(beanHeads)).getAttributes(mintedTokenId);
        console.log(newParams);

        uint256 rarityPoints = beanHeadsBreeder.getRarityPoints(mintedTokenId);
        console.log("Rarity Points: ", rarityPoints);
        assertEq(rarityPoints, 118);
        uint256 tokenBalanceAfterBreed = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfterBreed, 2); // User should have 1 parent tokens + 1 new breed token
        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId), 1);
        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId2), 1);

        beanHeads.approve(address(beanHeadsBreeder), tokenId2);
        beanHeads.approve(address(beanHeadsBreeder), mintedTokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId2);
        beanHeadsBreeder.depositBeanHeads(mintedTokenId);

        uint256 blockConfirmations2 = block.number + BREEDING_COOLDOWN + 1;
        vm.roll(blockConfirmations2);

        uint256 requestId2 = beanHeadsBreeder.requestBreed{value: MINT_PRICE}(
            tokenId2, mintedTokenId, IBeanHeadsBreeder.BreedingMode.Mutation
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
        string memory newParams2 = IBeanHeads(address(beanHeads)).getAttributes(mintedTokenId2);
        console.log(newParams2);

        uint256 rarityPoints2 = beanHeadsBreeder.getRarityPoints(mintedTokenId2);
        console.log("Rarity Points 2: ", rarityPoints2);
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
        beanHeads.approve(address(beanHeadsBreeder), tokenId);
        beanHeads.approve(address(beanHeadsBreeder), tokenId2);
        console.log("Approving tokens for breeding: ", tokenId, tokenId2);

        uint256 tokenBalanceBefore = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceBefore, 2);

        vm.recordLogs();
        beanHeadsBreeder.depositBeanHeads(tokenId);
        beanHeadsBreeder.depositBeanHeads(tokenId2);

        _assertDepositTokenLogs(tokenId, tokenId2);
        uint256 blockConfirmations = block.number + BREEDING_COOLDOWN;
        vm.roll(blockConfirmations);

        uint256 tokenBalanceAfter = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfter, 0); // Tokens should be in the breeder contract

        vm.recordLogs();
        uint256 requestId =
            beanHeadsBreeder.requestBreed{value: MINT_PRICE}(tokenId, tokenId2, IBeanHeadsBreeder.BreedingMode.Fusion);

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
        string memory newParams = IBeanHeads(address(beanHeads)).getAttributes(mintedTokenId);
        console.log(newParams);

        uint256 rarityPoints = beanHeadsBreeder.getRarityPoints(mintedTokenId);
        console.log("Rarity Points: ", rarityPoints);
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

        uint256 tokenBalanceAfterBreed = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfterBreed, 1); // User should have 1 parent tokens + 1 new breed token
    }

    function testRequestNewBreed_AscensionMode() public MintedBeanHeads {
        vm.startPrank(USER1);
        beanHeads.approve(address(beanHeadsBreeder), tokenId2);

        uint256 tokenBalanceBefore = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceBefore, 2);

        beanHeadsBreeder.depositBeanHeads(tokenId2);

        uint256 blockConfirmations = block.number + BREEDING_COOLDOWN;
        vm.roll(blockConfirmations);

        uint256 tokenBalanceAfter = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfter, 1);

        vm.recordLogs();
        uint256 requestId =
            beanHeadsBreeder.requestBreed{value: MINT_PRICE}(tokenId2, 0, IBeanHeadsBreeder.BreedingMode.Ascension);

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
        string memory newParams = IBeanHeads(address(beanHeads)).getAttributes(mintedTokenId);
        console.log(newParams);

        uint256 rarityPoints = beanHeadsBreeder.getRarityPoints(mintedTokenId);
        console.log("Rarity Points: ", rarityPoints);
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

        uint256 tokenBalanceAfterBreed = beanHeads.getOwnerTokensCount(USER1);
        assertEq(tokenBalanceAfterBreed, 2); // User should have 1 parent tokens + 1 new breed token
        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId), 1);
        assertEq(beanHeadsBreeder.s_parentBreedingCount(tokenId2), 1);
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
