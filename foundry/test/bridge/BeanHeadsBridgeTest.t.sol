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
import {MockTokenPool, Pool} from "src/mocks/MockTokenPool.sol";
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

    HelperConfig public sepoliaHelperConfig;
    HelperConfig public arbHelperConfig;

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

    uint256 public constant MINT_PRICE = 1 ether;
    address public constant NATIVE_TOKEN = address(0);

    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user2");

    uint256 sepoliaFork;
    uint256 arbFork;

    address public ownerSepolia;
    address public ownerArbitrum;
    address[] public allowList;

    AggregatorV3Interface public priceFeedSepolia;
    AggregatorV3Interface public priceFeedArbitrum;

    function setUp() public {
        HelperConfig.NetworkConfig memory config;
        // create fork
        sepoliaFork = vm.createSelectFork("sepolia-eth");

        arbFork = vm.createSelectFork("arb-sepolia");

        // Deploy on Sepolia
        vm.selectFork(sepoliaFork);
        ccipSimulatorSepolia = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipSimulatorSepolia));

        sepoliaNetworkDetails = ccipSimulatorSepolia.getNetworkDetails(block.chainid);
        console.log("Sepolia Network Details: ", block.chainid);

        sepoliaHelperConfig = new HelperConfig();
        config = sepoliaHelperConfig.getActiveNetworkConfig();

        address usdPriceFeedSepolia = config.usdPriceFeed;
        priceFeedSepolia = AggregatorV3Interface(usdPriceFeedSepolia);
        assert(priceFeedSepolia != AggregatorV3Interface(address(0)));
        vm.makePersistent(address(priceFeedSepolia));

        sepoliaHelpers = new Helpers();

        DeployBeanHeadsBridge deploySepoliaBeanHeadsBridge = new DeployBeanHeadsBridge();
        (address sepoliaBeanHeadsBridgeAddr, address sepoliaBeanHeadsAddress, address deployerSepoliaAddress) =
            deploySepoliaBeanHeadsBridge.run();

        sepoliaBeanHeadsBridge = BeanHeadsBridge(payable(sepoliaBeanHeadsBridgeAddr));
        vm.makePersistent(address(sepoliaBeanHeadsBridge));

        sepoliaBeanHeads = IBeanHeads(payable(sepoliaBeanHeadsAddress));
        vm.makePersistent(address(sepoliaBeanHeads));

        ownerSepolia = deployerSepoliaAddress;
        vm.makePersistent(ownerSepolia);
        assertEq(sepoliaBeanHeadsBridge.owner(), ownerSepolia);
        assertEq(sepoliaBeanHeads.owner(), ownerSepolia);

        // Deploy on Arbitrum
        vm.selectFork(arbFork);
        ccipSimulatorArbitrum = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipSimulatorArbitrum));

        arbNetworkDetails = ccipSimulatorArbitrum.getNetworkDetails(block.chainid);
        console.log("Arb Network Details: ", block.chainid);

        arbHelperConfig = new HelperConfig();
        config = arbHelperConfig.getActiveNetworkConfig();

        address usdPriceFeedArbitrum = config.usdPriceFeed;
        priceFeedArbitrum = AggregatorV3Interface(usdPriceFeedArbitrum);
        assert(priceFeedArbitrum != AggregatorV3Interface(address(0)));
        vm.makePersistent(address(priceFeedArbitrum));

        arbHelpers = new Helpers();

        DeployBeanHeadsBridge deployArbBeanHeadsBridge = new DeployBeanHeadsBridge();
        (address arbBeanHeadsBridgeAddr, address arbBeanHeadsAddress, address deployerArbitrumAddress) =
            deployArbBeanHeadsBridge.run();

        arbBeanHeadsBridge = BeanHeadsBridge(payable(arbBeanHeadsBridgeAddr));
        vm.makePersistent(address(arbBeanHeadsBridge));

        arbBeanHeads = IBeanHeads(payable(arbBeanHeadsAddress));
        vm.makePersistent(address(arbBeanHeads));

        ownerArbitrum = deployerArbitrumAddress;
        vm.makePersistent(ownerArbitrum);
        assertEq(arbBeanHeadsBridge.owner(), ownerArbitrum);
        assertEq(arbBeanHeads.owner(), ownerArbitrum);

        vm.selectFork(sepoliaFork);
        vm.startPrank(ownerSepolia);
        console.log("Setting up Sepolia BeanHeadsBridge...");
        mockSepoliaToken = new MockERC20(10_000 ether);
        vm.makePersistent(address(mockSepoliaToken));

        address[] memory sepoliaAllowList = new address[](1);
        sepoliaAllowList[0] = address(sepoliaBeanHeadsBridge);
        sepoliaTokenPool = new MockTokenPool(
            IERC20(address(mockSepoliaToken)),
            sepoliaAllowList,
            sepoliaNetworkDetails.rmnProxyAddress,
            sepoliaNetworkDetails.routerAddress
        );
        vm.makePersistent(address(sepoliaTokenPool));

        mockSepoliaToken.transfer(address(sepoliaTokenPool), 10_000 ether);

        sepoliaBeanHeadsBridge.setRemoteBridge(address(arbBeanHeadsBridge));
        ccipSimulatorSepolia.requestLinkFromFaucet(address(sepoliaBeanHeadsBridge), 100 ether);
        assertEq(sepoliaBeanHeadsBridge.remoteBridgeAddresses(address(arbBeanHeadsBridge)), true);
        vm.stopPrank();

        vm.startPrank(ownerSepolia);
        sepoliaBeanHeads.setAllowedToken(address(mockSepoliaToken), true);
        // sepoliaBeanHeads.setAllowedToken(address(sepoliaLinkToken), true);
        // sepoliaBeanHeads.setAllowedToken(address(mockArbToken), true);
        sepoliaBeanHeads.addPriceFeed(address(mockSepoliaToken), address(priceFeedSepolia));
        // sepoliaBeanHeads.addPriceFeed(address(mockArbToken), address(priceFeedArbitrum));
        sepoliaBeanHeads.setMintPrice(MINT_PRICE);
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(ownerArbitrum);
        console.log("Setting up Arbitrum BeanHeadsBridge...");
        mockArbToken = new MockERC20(10_000 ether);
        vm.makePersistent(address(mockArbToken));

        address[] memory arbAllowList = new address[](1);
        arbAllowList[0] = address(arbBeanHeadsBridge);
        arbTokenPool = new MockTokenPool(
            IERC20(address(mockArbToken)),
            arbAllowList,
            arbNetworkDetails.rmnProxyAddress,
            arbNetworkDetails.routerAddress
        );
        vm.makePersistent(address(arbTokenPool));

        mockArbToken.transfer(address(arbTokenPool), 10_000 ether);

        arbBeanHeadsBridge.setRemoteBridge(address(sepoliaBeanHeadsBridge));
        ccipSimulatorArbitrum.requestLinkFromFaucet(address(arbBeanHeadsBridge), 100 ether);
        assertEq(arbBeanHeadsBridge.remoteBridgeAddresses(address(sepoliaBeanHeadsBridge)), true);
        vm.stopPrank();

        vm.startPrank(ownerArbitrum);
        arbBeanHeads.setAllowedToken(address(mockArbToken), true);
        // arbBeanHeads.setAllowedToken(address(arbLinkToken), true);
        // arbBeanHeads.setAllowedToken(address(mockSepoliaToken), true);
        arbBeanHeads.addPriceFeed(address(mockArbToken), address(priceFeedArbitrum));
        // arbBeanHeads.addPriceFeed(address(mockSepoliaToken), address(priceFeedSepolia));
        arbBeanHeads.setMintPrice(MINT_PRICE);

        vm.mockCall(
            address(priceFeedArbitrum),
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), int256(1e8), uint256(block.timestamp), uint256(block.timestamp), uint80(1))
        );
        vm.stopPrank();

        // Register the token pools
        vm.selectFork(sepoliaFork);
        vm.startPrank(ownerSepolia);

        // Claim role on Sepolia
        console.log("Claiming role on Sepolia");
        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(
            address(mockSepoliaToken)
        );

        // Accept role on Sepolia
        console.log("Accepting role on Sepolia");
        TokenAdminRegistry tokenAdminRegistry = TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress);
        // tokenAdminRegistry.transferAdminRole(address(mockSepoliaToken), ownerSepolia);
        // tokenAdminRegistry.proposeAdministrator(address(mockSepoliaToken), ownerSepolia);
        tokenAdminRegistry.acceptAdminRole(address(mockSepoliaToken));

        // Link token to pool in the token admin registry
        console.log("Linking token to pool in the token admin registry on Sepolia");
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(
            address(mockSepoliaToken), address(sepoliaTokenPool)
        );
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(ownerArbitrum);

        // Claim role on Arbitrum
        console.log("Claiming role on Arbitrum");
        RegistryModuleOwnerCustom(arbNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(
            address(mockArbToken)
        );

        // Accept role on Arbitrum
        console.log("Accepting role on Arbitrum");
        TokenAdminRegistry tokenAdminRegistryArb = TokenAdminRegistry(arbNetworkDetails.tokenAdminRegistryAddress);
        // tokenAdminRegistryArb.transferAdminRole(address(mockArbToken), ownerArbitrum);
        // tokenAdminRegistryArb.proposeAdministrator(address(mockArbToken), ownerArbitrum);
        tokenAdminRegistryArb.acceptAdminRole(address(mockArbToken));

        // Link token to pool in the token admin registry
        console.log("Linking token to pool in the token admin registry on Arbitrum");
        TokenAdminRegistry(arbNetworkDetails.tokenAdminRegistryAddress).setPool(
            address(mockArbToken), address(arbTokenPool)
        );
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

        configureTokenPool(
            sepoliaFork,
            ownerSepolia,
            address(sepoliaTokenPool),
            arbNetworkDetails.chainSelector,
            address(arbTokenPool),
            address(mockArbToken)
        );
        address afterConfigureSepoliaTokenPool =
            abi.decode(TokenPool(address(sepoliaTokenPool)).getRemoteToken(arbNetworkDetails.chainSelector), (address));
        console.log("After configure Sepolia Token Pool: %s", afterConfigureSepoliaTokenPool);

        configureTokenPool(
            arbFork,
            ownerArbitrum,
            address(arbTokenPool),
            sepoliaNetworkDetails.chainSelector,
            address(sepoliaTokenPool),
            address(mockSepoliaToken)
        );
        address afterConfigureArbitrumTokenPool =
            abi.decode(TokenPool(address(arbTokenPool)).getRemoteToken(sepoliaNetworkDetails.chainSelector), (address));
        console.log("After configure Arbitrum Token Pool: %s", afterConfigureArbitrumTokenPool);
    }

    function configureTokenPool(
        uint256 fork,
        address owner,
        address localPool,
        uint64 remoteChainSelector,
        address remotePool,
        address remoteTokenAddress
    ) public {
        vm.selectFork(fork);
        vm.startPrank(owner);
        bytes[] memory remotePoolAddresses = new bytes[](1);
        remotePoolAddresses[0] = abi.encode(remotePool);
        TokenPool.ChainUpdate[] memory chainsToAdd = new TokenPool.ChainUpdate[](1);
        chainsToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector,
            allowed: true,
            remotePoolAddress: abi.encode(remotePool),
            remoteTokenAddress: abi.encode(remoteTokenAddress),
            outboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0}),
            inboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0})
        });
        TokenPool(localPool).applyChainUpdates(chainsToAdd);
        vm.stopPrank();
    }

    function test_Initialize() public {
        vm.selectFork(sepoliaFork);
        vm.startPrank(ownerSepolia);
        assertEq(sepoliaBeanHeadsBridge.owner(), ownerSepolia);
        assertEq(sepoliaBeanHeads.owner(), ownerSepolia);
        assertEq(sepoliaBeanHeads.isTokenAllowed(address(mockSepoliaToken)), true);
        // assertEq(sepoliaBeanHeads.isTokenAllowed(address(mockArbToken)), true);
        assertEq(sepoliaBeanHeadsBridge.remoteBridgeAddresses(address(arbBeanHeadsBridge)), true);
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(ownerArbitrum);
        assertEq(arbBeanHeadsBridge.owner(), ownerArbitrum);
        assertEq(arbBeanHeads.owner(), ownerArbitrum);
        assertEq(arbBeanHeads.isTokenAllowed(address(mockArbToken)), true);
        // assertEq(arbBeanHeads.isTokenAllowed(address(mockSepoliaToken)), true);
        assertEq(arbBeanHeadsBridge.remoteBridgeAddresses(address(sepoliaBeanHeadsBridge)), true);
        vm.stopPrank();
    }

    function test_MintGenesis() public {
        vm.selectFork(sepoliaFork);
        vm.startPrank(USER);
        uint256 tokenAmount = 1;
        // uint256 mintPayment = MINT_PRICE * tokenAmount;

        sepoliaBeanHeads.mintGenesis(USER, params, tokenAmount, address(mockSepoliaToken));

        uint256 userTokenBalance = sepoliaBeanHeads.balanceOf(USER);
        assertEq(userTokenBalance, tokenAmount);

        uint256 userTokenSupply = sepoliaBeanHeads.getTotalSupply();
        assertEq(userTokenSupply, tokenAmount);

        vm.stopPrank();
    }

    function test_sendMintTokenRequest() public {
        vm.selectFork(arbFork);
        vm.startPrank(USER);

        uint256 tokenAmount = 1;
        uint256 mintPayment = MINT_PRICE * tokenAmount;

        bytes32 messageId = arbBeanHeadsBridge.sendMintTokenRequest(
            sepoliaNetworkDetails.chainSelector, USER, params, tokenAmount, address(mockArbToken)
        );
        vm.stopPrank();

        // Force bridge to trust source for this test
        vm.selectFork(sepoliaFork);
        vm.startPrank(ownerSepolia);
        sepoliaBeanHeadsBridge.setRemoteBridge(address(arbBeanHeadsBridge));
        vm.stopPrank();

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: address(mockArbToken), amount: mintPayment});

        bytes memory data =
            abi.encode(IBeanHeadsBridge.ActionType.MINT, USER, params, address(mockArbToken), tokenAmount);

        Client.Any2EVMMessage memory receivedMessage = Client.Any2EVMMessage({
            messageId: messageId,
            sourceChainSelector: arbNetworkDetails.chainSelector,
            sender: abi.encode(address(arbBeanHeadsBridge)),
            data: data,
            destTokenAmounts: tokenAmounts
        });

        vm.prank(sepoliaNetworkDetails.routerAddress);
        sepoliaBeanHeadsBridge.ccipReceive(receivedMessage);

        assertEq(sepoliaBeanHeads.balanceOf(USER), tokenAmount);
    }
}
