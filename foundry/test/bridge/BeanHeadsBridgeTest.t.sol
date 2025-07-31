// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Client} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {CCIPLocalSimulatorFork, Register} from "chainlink-local/ccip/CCIPLocalSimulatorFork.sol";
import {IRouterClient} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {RegistryModuleOwnerCustom} from
    "chainlink-brownie-contracts/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenPool, IERC20} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {TokenAdminRegistry} from
    "chainlink-brownie-contracts/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {Test, console} from "forge-std/Test.sol";
import {Ownable as OwnableOZ} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {MockTokenPool} from "src/mocks/MockTokenPool.sol";
import {BeanHeadsBridge} from "src/bridge/BeanHeadsBridge.sol";
import {IBeanHeadsBridge} from "src/interfaces/IBeanHeadsBridge.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {DeployBeanHeadsBridge} from "script/DeployBeanHeadsBridge.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Genesis} from "src/types/Genesis.sol";
import {Helpers} from "test/Helpers.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";

contract BeanHeadsBridgeTest is Test, Helpers {
    BeanHeadsBridge public sepoliaBeanHeadsBridge;
    BeanHeadsBridge public arbBeanHeadsBridge;

    HelperConfig public sharedHelperConfig;

    Helpers public sepoliaHelpers;
    Helpers public arbHelpers;

    IBeanHeads public sepoliaBeanHeads;
    IBeanHeads public arbBeanHeads;

    CCIPLocalSimulatorFork public ccipSimulatorSepolia;
    CCIPLocalSimulatorFork public ccipSimulatorArbitrum;

    Register.NetworkDetails public sepoliaNetworkDetails;
    Register.NetworkDetails public arbNetworkDetails;

    MockTokenPool public sepoliaTokenPool;
    MockTokenPool public arbTokenPool;

    MockERC20 public mockSepoliaToken;
    MockERC20 public mockArbToken;

    uint64 public constant SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;
    uint64 public constant BASE_CHAIN_SELECTOR = 10344971235874465080;

    uint256 public constant MINT_PRICE = 1 ether;
    address public constant NATIVE_TOKEN = address(0);

    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user2");

    uint256 sepoliaFork;
    uint256 arbFork;

    address public owner;
    address[] public allowList;

    AggregatorV3Interface public priceFeedSepolia;
    AggregatorV3Interface public priceFeedArbitrum;

    function setUp() public {
        sharedHelperConfig = new HelperConfig();

        // create fork
        sepoliaFork = vm.createSelectFork("sepolia-eth");

        arbFork = vm.createSelectFork("arb-sepolia");

        // Deploy on Sepolia
        vm.selectFork(sepoliaFork);
        ccipSimulatorSepolia = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipSimulatorSepolia));

        sepoliaNetworkDetails = ccipSimulatorSepolia.getNetworkDetails(block.chainid);
        console.log("Sepolia Network Details: ", block.chainid);

        address usdPriceFeedSepolia = sharedHelperConfig.getActiveNetworkConfig().usdPriceFeed;
        priceFeedSepolia = AggregatorV3Interface(usdPriceFeedSepolia);

        sepoliaHelpers = new Helpers();
        // address deployerSepoliaAddress = vm.addr(sharedHelperConfig.getActiveNetworkConfig().deployerKey);
        // console.log("Deployer Sepolia Address: ", deployerSepoliaAddress);
        DeployBeanHeadsBridge deploySepoliaBeanHeadsBridge = new DeployBeanHeadsBridge();
        (address sepoliaBeanHeadsBridgeAddr, address sepoliaBeanHeadsAddress, address deployerSepoliaAddress) =
            deploySepoliaBeanHeadsBridge.run();

        sepoliaBeanHeadsBridge = BeanHeadsBridge(payable(sepoliaBeanHeadsBridgeAddr));
        vm.makePersistent(address(sepoliaBeanHeadsBridge));

        sepoliaBeanHeads = IBeanHeads(payable(sepoliaBeanHeadsAddress));
        vm.makePersistent(address(sepoliaBeanHeads));

        owner = deployerSepoliaAddress;
        assertEq(sepoliaBeanHeadsBridge.owner(), owner);
        assertEq(sepoliaBeanHeads.owner(), owner);

        // Deploy on Arbitrum
        vm.selectFork(arbFork);
        ccipSimulatorArbitrum = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipSimulatorArbitrum));

        arbNetworkDetails = ccipSimulatorArbitrum.getNetworkDetails(block.chainid);
        console.log("Arb Network Details: ", block.chainid);

        address usdPriceFeedArbitrum = sharedHelperConfig.getActiveNetworkConfig().usdPriceFeed;
        priceFeedArbitrum = AggregatorV3Interface(usdPriceFeedArbitrum);

        arbHelpers = new Helpers();
        // address deployerArbitrumAddress = vm.addr(sharedHelperConfig.getActiveNetworkConfig().deployerKey);
        // console.log("Deployer Arbitrum Address: ", deployerArbitrumAddress);
        DeployBeanHeadsBridge deployArbBeanHeadsBridge = new DeployBeanHeadsBridge();
        (address arbBeanHeadsBridgeAddr, address arbBeanHeadsAddress, address deployerArbitrumAddress) =
            deployArbBeanHeadsBridge.run();

        arbBeanHeadsBridge = BeanHeadsBridge(payable(arbBeanHeadsBridgeAddr));
        vm.makePersistent(address(arbBeanHeadsBridge));

        arbBeanHeads = IBeanHeads(payable(arbBeanHeadsAddress));
        vm.makePersistent(address(arbBeanHeads));

        owner = deployerArbitrumAddress;
        assertEq(arbBeanHeadsBridge.owner(), owner);
        assertEq(arbBeanHeads.owner(), owner);

        vm.selectFork(sepoliaFork);
        vm.startPrank(owner);
        console.log("Setting up Sepolia BeanHeadsBridge...");
        mockSepoliaToken = new MockERC20(10_000 ether);
        sepoliaBeanHeadsBridge.setRemoteBridge(address(arbBeanHeadsBridge));
        ccipSimulatorSepolia.requestLinkFromFaucet(address(sepoliaBeanHeadsBridge), 100 ether);
        assertEq(sepoliaBeanHeadsBridge.remoteBridgeAddresses(address(arbBeanHeadsBridge)), true);

        sepoliaBeanHeads.setAllowedToken(address(mockSepoliaToken), true);
        sepoliaBeanHeads.addPriceFeed(address(mockSepoliaToken), address(priceFeedSepolia));
        sepoliaBeanHeads.setMintPrice(MINT_PRICE);
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(owner);
        console.log("Setting up Arbitrum BeanHeadsBridge...");
        mockArbToken = new MockERC20(10_000 ether);
        arbBeanHeadsBridge.setRemoteBridge(address(sepoliaBeanHeadsBridge));
        ccipSimulatorArbitrum.requestLinkFromFaucet(address(arbBeanHeadsBridge), 100 ether);
        assertEq(arbBeanHeadsBridge.remoteBridgeAddresses(address(sepoliaBeanHeadsBridge)), true);

        arbBeanHeads.setAllowedToken(address(mockArbToken), true);
        arbBeanHeads.addPriceFeed(address(mockArbToken), address(priceFeedArbitrum));
        arbBeanHeads.setMintPrice(MINT_PRICE);
        vm.stopPrank();

        vm.selectFork(sepoliaFork);
        vm.startPrank(USER);
        vm.deal(USER, 1 ether);
        mockSepoliaToken.mint(100 ether);
        mockSepoliaToken.approve(address(sepoliaBeanHeadsBridge), type(uint256).max);
        mockSepoliaToken.approve(address(sepoliaBeanHeads), type(uint256).max);
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(USER);
        vm.deal(USER, 1 ether);
        mockArbToken.mint(100 ether);
        mockArbToken.approve(address(arbBeanHeadsBridge), type(uint256).max);
        mockArbToken.approve(address(arbBeanHeads), type(uint256).max);
        vm.stopPrank();
    }

    function test_sendMintTokenRequest() public {
        vm.selectFork(arbFork);
        vm.startPrank(USER);
        uint256 tokenAmount = 1;
        uint256 mintPayment = MINT_PRICE * tokenAmount;

        bytes32 messageId = arbBeanHeadsBridge.sendMintTokenRequest(
            SEPOLIA_CHAIN_SELECTOR, USER, params, tokenAmount, address(mockArbToken)
        );

        vm.stopPrank();

        vm.selectFork(sepoliaFork);

        Client.Any2EVMMessage memory receivedMessage = Client.Any2EVMMessage({
            messageId: messageId,
            sourceChainSelector: BASE_CHAIN_SELECTOR,
            sender: abi.encode(address(arbBeanHeadsBridge)),
            data: abi.encode(IBeanHeadsBridge.ActionType.MINT, USER, params, tokenAmount),
            destTokenAmounts: new Client.EVMTokenAmount[](1)
        });
        receivedMessage.destTokenAmounts[0] =
            Client.EVMTokenAmount({token: address(mockSepoliaToken), amount: mintPayment});

        vm.prank(sepoliaNetworkDetails.routerAddress);
        sepoliaBeanHeadsBridge.ccipReceive(receivedMessage);

        uint256 userTokenBalance = sepoliaBeanHeads.balanceOf(USER);
        assertEq(userTokenBalance, tokenAmount);
    }
}
