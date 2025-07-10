// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {VRFCoordinatorV2_5Mock} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockLinkToken} from "chainlink-brownie-contracts/contracts/src/v0.8/mocks/MockLinkToken.sol";

import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {DeployBeanHeadsBreeder} from "script/DeployBeanHeadsBreeder.s.sol";
import {BeanHeadsBreeder} from "src/vrf/BeanHeadsBreeder.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {Test, console} from "forge-std/Test.sol";
import {Helpers} from "test/Helpers.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract BeanHeadsBreederTest is Test, Helpers {
    BeanHeadsBreeder private beanHeadsBreeder;
    MockLinkToken private linkToken;
    IBeanHeads private beanHeads;
    Helpers helpers;
    HelperConfig private helperConfig;

    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");
    uint256 public MINT_PRICE = 0.01 ether;

    uint256 tokenId;
    uint256 tokenId2;

    function setUp() public {
        helperConfig = new HelperConfig();
        helpers = new Helpers();

        (,,, address vrfCoordinatorMock, uint256 subId, bytes32 keyHash,) = helperConfig.activeNetworkConfig();
        DeployBeanHeads deployBeanHeads = new DeployBeanHeads();
        beanHeads = deployBeanHeads.run();
        beanHeadsBreeder = new BeanHeadsBreeder(address(beanHeads), address(vrfCoordinatorMock), subId, keyHash);

        vm.startPrank(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38); // Deployer address
        VRFCoordinatorV2_5Mock(vrfCoordinatorMock).addConsumer(subId, address(beanHeadsBreeder));
        vm.stopPrank();

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

    function testRequestBreed() public MintedBeanHeads {
        // vm.startPrank(USER1);
        // uint256 requestId = beanHeadsBreeder.requestBreed(tokenId, tokenId2);
        // console.log("Breed request ID: ", requestId);
        // (address owner, uint256 parent1Id, uint256 parent2Id) = beanHeadsBreeder.s_breedRequests(requestId);
        // assertEq(owner, USER1, "Owner should match USER1");
        // assertEq(parent1Id, tokenId, "Parent 1 ID should match tokenId");
        // assertEq(parent2Id, tokenId2, "Parent 2 ID should match tokenId2");
        // vm.stopPrank();
    }
}
