// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Client} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {CCIPLocalSimulatorFork, Register} from "chainlink-local/ccip/CCIPLocalSimulatorFork.sol";
import {IRouterClient} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {RegistryModuleOwnerCustom} from
    "chainlink-brownie-contracts/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenPool, Pool} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {Test, console} from "forge-std/Test.sol";

import {BeanHeadsBridge} from "src/bridge/BeanHeadsBridge.sol";
import {IBeanHeadsBridge} from "src/interfaces/IBeanHeadsBridge.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {DeployBeanHeadsBridge} from "script/DeployBeanHeadsBridge.s.sol";
import {BeanHeads} from "src/core/BeanHeads.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Genesis} from "src/types/Genesis.sol";

contract BeanHeadsBridgeTest is Test {
    BeanHeadsBridge public sepoliaBeanHeadsBridge;
    BeanHeadsBridge public baseBeanHeadsBridge;

    HelperConfig public helperConfig;

    BeanHeads public sepoliaBeanHeads;
    BeanHeads public baseBeanHeads;

    CCIPLocalSimulatorFork public ccipSimulatorSepolia;
    CCIPLocalSimulatorFork public ccipSimulatorBase;

    Register.NetworkDetails public sepoliaNetworkDetails;
    Register.NetworkDetails public baseNetworkDetails;

    address public DEPLOYER = makeAddr("deployer");
    address public USER = makeAddr("user");

    uint256 sepoliaFork;
    uint256 baseFork;

    function setUp() public {
        // create fork
        sepoliaFork = vm.createSelectFork("sepolia-eth");
        baseFork = vm.createSelectFork("base-sepolia");

        // Initialize CCIP simulator for Sepolia
        ccipSimulatorSepolia = new CCIPLocalSimulatorFork();

        // Deploy on Sepolia
        vm.selectFork(sepoliaFork);
        vm.startPrank(DEPLOYER);
        helperConfig = new HelperConfig();
        DeployBeanHeads deploySepoliaBeanHeads = new DeployBeanHeads();

        // Deploy BeanHeads contract
        (address sepoliaBeanHeadsAddress, address sepoliaRoyaltyAddress) = deploySepoliaBeanHeads.run();
        sepoliaBeanHeads = BeanHeads(payable(sepoliaBeanHeadsAddress));
        DeployBeanHeadsBridge deploySepoliaBeanHeadsBridge = new DeployBeanHeadsBridge();
        sepoliaBeanHeadsBridge = BeanHeadsBridge(deploySepoliaBeanHeadsBridge.run());
    }

    function test_initialization() public {
        // assertEq(beanHeadsBridge.remoteBridge(), helperConfig.activeNetworkConfig().remoteBridge);
    }
}
