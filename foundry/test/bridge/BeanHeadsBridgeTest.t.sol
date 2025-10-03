// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Client} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {CCIPLocalSimulatorFork, Register, IRouterFork} from "chainlink-local/ccip/CCIPLocalSimulatorFork.sol";
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
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import {IBeanHeads, IBeanHeadsView, IBeanHeadsMint, IBeanHeadsMarketplace} from "src/interfaces/IBeanHeads.sol";
import {MockTokenPool, Pool} from "src/mocks/MockTokenPool.sol";
import {BeanHeadsBridge} from "src/bridge/BeanHeadsBridge.sol";
import {IBeanHeadsBridge} from "src/interfaces/IBeanHeadsBridge.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {DeployBeanHeadsBridge} from "script/DeployBeanHeadsBridge.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Genesis} from "src/types/Genesis.sol";
import {Helpers} from "test/Helpers.sol";
import {MockERC20} from "src/mocks/MockERC20.sol";
import {IERC173} from "src/interfaces/IERC173.sol";
import {Vm} from "forge-std/Vm.sol";
import {IDiamondLoupe} from "src/interfaces/IDiamondLoupe.sol";
import {PermitTypes} from "src/types/PermitTypes.sol";

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
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    address public USER;
    address public USER2 = makeAddr("user2");
    address public MINTER;
    uint256 public MINTER_PK;
    uint256 public USER_PK;

    uint256 sepoliaFork;
    uint256 arbFork;

    address public ownerSepolia;
    address public ownerArbitrum;
    address[] public allowList;

    AggregatorV3Interface public priceFeedSepolia;
    AggregatorV3Interface public priceFeedArbitrum;

    enum ActionType {
        MINT,
        SELL,
        BUY,
        CANCEL,
        TRANSFER
    }

    uint256 sepoliaSnapshot;
    uint256 arbSnapshot;

    event DebugLog(bytes32 indexed topic, bytes data);

    function setUp() public {
        HelperConfig.NetworkConfig memory config;
        HelperConfig.CrossChainConfig memory crossChainConfig;
        // create fork
        sepoliaFork = vm.createSelectFork("sepolia-eth");
        arbFork = vm.createSelectFork("arb-sepolia");

        (MINTER, MINTER_PK) = makeAddrAndKey("minter");
        (USER, USER_PK) = makeAddrAndKey("user");

        // Deploy on Sepolia
        vm.selectFork(sepoliaFork);
        ccipSimulatorSepolia = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipSimulatorSepolia));

        sepoliaNetworkDetails = ccipSimulatorSepolia.getNetworkDetails(block.chainid);
        console.log("Sepolia Network Details: ", block.chainid);

        sepoliaHelperConfig = new HelperConfig();
        (config,, crossChainConfig) = sepoliaHelperConfig.getActiveNetworkConfig();

        address usdPriceFeedSepolia = config.usdPriceFeed;
        priceFeedSepolia = AggregatorV3Interface(usdPriceFeedSepolia);
        assert(priceFeedSepolia != AggregatorV3Interface(address(0)));
        vm.makePersistent(address(priceFeedSepolia));

        sepoliaHelpers = new Helpers();

        console.log("Deploying BeanHeadsBridge on Sepolia...");
        DeployBeanHeadsBridge deploySepoliaBeanHeadsBridge = new DeployBeanHeadsBridge();
        (address sepoliaBeanHeadsBridgeAddr, address sepoliaBeanHeadsAddress, address deployerSepoliaAddress) =
            deploySepoliaBeanHeadsBridge.run();

        sepoliaBeanHeadsBridge = BeanHeadsBridge(payable(sepoliaBeanHeadsBridgeAddr));
        vm.makePersistent(address(sepoliaBeanHeadsBridge));

        sepoliaBeanHeads = IBeanHeads(payable(sepoliaBeanHeadsAddress));
        vm.makePersistent(address(sepoliaBeanHeads));

        ownerSepolia = deployerSepoliaAddress;
        vm.makePersistent(ownerSepolia);
        assertEq(IERC173(address(sepoliaBeanHeadsBridge)).owner(), ownerSepolia);
        assertEq(IERC173(address(sepoliaBeanHeads)).owner(), ownerSepolia);

        // Deploy on Arbitrum
        vm.selectFork(arbFork);
        ccipSimulatorArbitrum = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipSimulatorArbitrum));

        arbNetworkDetails = ccipSimulatorArbitrum.getNetworkDetails(block.chainid);
        console.log("Arb Network Details: ", block.chainid);

        arbHelperConfig = new HelperConfig();
        (config,, crossChainConfig) = arbHelperConfig.getActiveNetworkConfig();

        address usdPriceFeedArbitrum = config.usdPriceFeed;
        priceFeedArbitrum = AggregatorV3Interface(usdPriceFeedArbitrum);
        assert(priceFeedArbitrum != AggregatorV3Interface(address(0)));
        vm.makePersistent(address(priceFeedArbitrum));

        arbHelpers = new Helpers();

        console.log("Deploying BeanHeadsBridge on Arbitrum...");
        DeployBeanHeadsBridge deployArbBeanHeadsBridge = new DeployBeanHeadsBridge();
        (address arbBeanHeadsBridgeAddr, address arbBeanHeadsAddress, address deployerArbitrumAddress) =
            deployArbBeanHeadsBridge.run();

        arbBeanHeadsBridge = BeanHeadsBridge(payable(arbBeanHeadsBridgeAddr));
        vm.makePersistent(address(arbBeanHeadsBridge));

        arbBeanHeads = IBeanHeads(payable(arbBeanHeadsAddress));
        vm.makePersistent(address(arbBeanHeads));

        ownerArbitrum = deployerArbitrumAddress;
        vm.makePersistent(ownerArbitrum);
        assertEq(IERC173(address(arbBeanHeadsBridge)).owner(), ownerArbitrum);
        assertEq(IERC173(address(arbBeanHeads)).owner(), ownerArbitrum);

        vm.selectFork(sepoliaFork);
        vm.startPrank(ownerSepolia);
        console.log("Setting up Sepolia BeanHeadsBridge...");
        mockSepoliaToken = new MockERC20(100_000 ether);
        vm.makePersistent(address(mockSepoliaToken));

        address[] memory sepoliaAllowList = new address[](2);
        sepoliaAllowList[0] = address(sepoliaBeanHeadsBridge);
        sepoliaAllowList[1] = USER;
        sepoliaTokenPool = new MockTokenPool(
            IERC20(address(mockSepoliaToken)),
            sepoliaAllowList,
            sepoliaNetworkDetails.rmnProxyAddress,
            sepoliaNetworkDetails.routerAddress
        );
        vm.makePersistent(address(sepoliaTokenPool));

        uint64 arbChainId = arbHelperConfig.ARBITRUM_SEPOLIA_CHAIN_ID();

        sepoliaBeanHeadsBridge.setRemoteBridge(arbChainId, address(arbBeanHeadsBridge), true);
        ccipSimulatorSepolia.requestLinkFromFaucet(address(sepoliaBeanHeadsBridge), 10 ether);
        assertEq(sepoliaBeanHeadsBridge.remoteBridgeAddresses(arbChainId, address(arbBeanHeadsBridge)), true);
        vm.stopPrank();

        vm.mockCall(
            address(priceFeedSepolia),
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), int256(1e8), uint256(block.timestamp), uint256(block.timestamp), uint80(1))
        );
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(ownerArbitrum);
        console.log("Setting up Arbitrum BeanHeadsBridge...");
        mockArbToken = new MockERC20(100_000 ether);
        vm.makePersistent(address(mockArbToken));

        address[] memory arbAllowList = new address[](2);
        arbAllowList[0] = address(arbBeanHeadsBridge);
        arbAllowList[1] = USER;
        arbTokenPool = new MockTokenPool(
            IERC20(address(mockArbToken)),
            arbAllowList,
            arbNetworkDetails.rmnProxyAddress,
            arbNetworkDetails.routerAddress
        );
        vm.makePersistent(address(arbTokenPool));

        uint64 sepoliaChainId = sepoliaHelperConfig.ETH_SEPOLIA_CHAIN_ID();

        arbBeanHeadsBridge.setRemoteBridge(sepoliaChainId, address(sepoliaBeanHeadsBridge), true);
        ccipSimulatorArbitrum.requestLinkFromFaucet(address(arbBeanHeadsBridge), 10 ether);
        assertEq(arbBeanHeadsBridge.remoteBridgeAddresses(sepoliaChainId, address(sepoliaBeanHeadsBridge)), true);
        vm.stopPrank();

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
        tokenAdminRegistryArb.acceptAdminRole(address(mockArbToken));

        // Link token to pool in the token admin registry
        console.log("Linking token to pool in the token admin registry on Arbitrum");
        TokenAdminRegistry(arbNetworkDetails.tokenAdminRegistryAddress).setPool(
            address(mockArbToken), address(arbTokenPool)
        );
        vm.stopPrank();

        console.log("Setting up BeanHeads contracts...");
        vm.selectFork(sepoliaFork);
        vm.startPrank(ownerSepolia);
        sepoliaBeanHeads.setAllowedToken(address(mockSepoliaToken), true);
        sepoliaBeanHeads.setAllowedToken(address(mockArbToken), true);
        sepoliaBeanHeads.addPriceFeed(address(mockSepoliaToken), address(priceFeedSepolia));
        sepoliaBeanHeads.addPriceFeed(address(mockArbToken), address(priceFeedArbitrum));
        sepoliaBeanHeads.setRemoteBridge(arbNetworkDetails.chainSelector, address(sepoliaBeanHeadsBridge));
        assertEq(
            sepoliaBeanHeads.isBridgeAuthorized(arbNetworkDetails.chainSelector, address(sepoliaBeanHeadsBridge)), true
        );
        sepoliaBeanHeads.setMintPrice(MINT_PRICE);
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(ownerArbitrum);
        arbBeanHeads.setAllowedToken(address(mockArbToken), true);
        arbBeanHeads.setAllowedToken(address(mockSepoliaToken), true);
        arbBeanHeads.addPriceFeed(address(mockArbToken), address(priceFeedArbitrum));
        arbBeanHeads.addPriceFeed(address(mockSepoliaToken), address(priceFeedSepolia));
        arbBeanHeads.setRemoteBridge(sepoliaNetworkDetails.chainSelector, address(arbBeanHeadsBridge));
        assertEq(
            arbBeanHeads.isBridgeAuthorized(sepoliaNetworkDetails.chainSelector, address(arbBeanHeadsBridge)), true
        );
        arbBeanHeads.setMintPrice(MINT_PRICE);
        vm.stopPrank();

        console.log("Setting up token pools and user balance...");
        vm.selectFork(sepoliaFork);
        vm.startPrank(USER);
        vm.deal(USER, 1 ether);
        mockSepoliaToken.mint(USER, 100 ether);
        mockSepoliaToken.approve(address(sepoliaBeanHeadsBridge), type(uint256).max);
        mockSepoliaToken.approve(address(sepoliaBeanHeads), type(uint256).max);
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(USER);
        vm.deal(USER, 1 ether);
        mockArbToken.mint(USER, 100 ether);
        mockArbToken.approve(address(arbBeanHeadsBridge), type(uint256).max);
        mockArbToken.approve(address(arbBeanHeads), type(uint256).max);
        vm.stopPrank();

        vm.selectFork(sepoliaFork);
        vm.startPrank(MINTER);
        vm.deal(MINTER, 1 ether);
        mockSepoliaToken.mint(MINTER, 100 ether);
        mockSepoliaToken.approve(address(sepoliaBeanHeadsBridge), type(uint256).max);
        mockSepoliaToken.approve(address(sepoliaBeanHeads), type(uint256).max);
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(MINTER);
        vm.deal(MINTER, 1 ether);
        mockArbToken.mint(MINTER, 100 ether);
        mockArbToken.approve(address(arbBeanHeadsBridge), type(uint256).max);
        mockArbToken.approve(address(arbBeanHeads), type(uint256).max);
        vm.stopPrank();

        vm.selectFork(sepoliaFork);
        vm.prank(address(sepoliaBeanHeadsBridge));
        mockSepoliaToken.approve(address(sepoliaBeanHeads), type(uint256).max);
        vm.prank(address(sepoliaBeanHeadsBridge));
        mockArbToken.approve(address(sepoliaBeanHeads), type(uint256).max);

        vm.selectFork(arbFork);
        vm.prank(address(arbBeanHeadsBridge));
        mockArbToken.approve(address(arbBeanHeads), type(uint256).max);
        vm.prank(address(arbBeanHeadsBridge));
        mockSepoliaToken.approve(address(arbBeanHeads), type(uint256).max);

        configureTokenPool(
            sepoliaFork,
            ownerSepolia,
            address(sepoliaTokenPool),
            arbNetworkDetails.chainSelector,
            address(arbTokenPool),
            address(mockArbToken)
        );

        configureTokenPool(
            arbFork,
            ownerArbitrum,
            address(arbTokenPool),
            sepoliaNetworkDetails.chainSelector,
            address(sepoliaTokenPool),
            address(mockSepoliaToken)
        );

        vm.selectFork(sepoliaFork);
        sepoliaSnapshot = vm.snapshotState();
        vm.selectFork(arbFork);
        arbSnapshot = vm.snapshotState();
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
        uint64 sepChainId = sepoliaHelperConfig.ETH_SEPOLIA_CHAIN_ID();
        assertEq(sepoliaBeanHeadsBridge.owner(), ownerSepolia);
        assertEq(IERC173(address(sepoliaBeanHeads)).owner(), ownerSepolia);
        assertEq(sepoliaBeanHeads.isTokenAllowed(address(mockSepoliaToken)), true);
        assertEq(sepoliaBeanHeads.isTokenAllowed(address(mockArbToken)), true);
        assertEq(sepoliaBeanHeadsBridge.remoteBridgeAddresses(sepChainId, address(arbBeanHeadsBridge)), true);
        assertEq(sepoliaBeanHeads.getMintPrice(), MINT_PRICE);
        assertEq(sepoliaBeanHeads.name(), "BeanHeads");
        assertEq(sepoliaBeanHeads.symbol(), "BEANS");
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(ownerArbitrum);
        uint64 arbChainId = arbHelperConfig.ARBITRUM_SEPOLIA_CHAIN_ID();
        assertEq(arbBeanHeadsBridge.owner(), ownerArbitrum);
        assertEq(IERC173(address(arbBeanHeads)).owner(), ownerArbitrum);
        assertEq(arbBeanHeads.isTokenAllowed(address(mockArbToken)), true);
        assertEq(arbBeanHeads.isTokenAllowed(address(mockSepoliaToken)), true);
        assertEq(arbBeanHeadsBridge.remoteBridgeAddresses(arbChainId, address(sepoliaBeanHeadsBridge)), true);
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

        uint256 nextMintToken = sepoliaBeanHeads.mintGenesis(USER, params, tokenAmount, address(mockSepoliaToken));
        assertEq(nextMintToken, tokenAmount);

        uint256 nextTokenId = sepoliaBeanHeads.getNextTokenId();
        assertEq(nextTokenId, tokenAmount + 1);

        vm.stopPrank();
    }

    function test_sendMintTokenRequest() public {
        vm.selectFork(arbFork);

        uint256 tokenAmount = 1;

        ccipSimulatorArbitrum.requestLinkFromFaucet(USER, 10 ether);

        vm.prank(USER);
        IERC20(address(mockArbToken)).approve(address(arbBeanHeadsBridge), type(uint256).max);

        vm.prank(USER);
        arbBeanHeadsBridge.sendMintTokenRequest(
            sepoliaNetworkDetails.chainSelector, USER, params, tokenAmount, address(mockArbToken)
        );

        vm.warp(block.timestamp + 20 minutes);

        ccipSimulatorArbitrum.switchChainAndRouteMessage(sepoliaFork);

        vm.selectFork(sepoliaFork);
        vm.prank(USER);
        uint256 userTokenBalance = sepoliaBeanHeads.balanceOf(USER);
        assertEq(userTokenBalance, tokenAmount);
        uint256 userTokenSupply = sepoliaBeanHeads.getTotalSupply();
        assertEq(userTokenSupply, tokenAmount);
        assertEq(sepoliaBeanHeads.getOwnerOf(0), USER);
    }

    modifier mintedTokens() {
        vm.selectFork(sepoliaFork);
        vm.startPrank(MINTER);
        uint256 tokenAmount = 1;
        sepoliaBeanHeads.mintGenesis(MINTER, params, tokenAmount, address(mockSepoliaToken));
        assertEq(sepoliaBeanHeads.getOwnerOf(0), MINTER);
        vm.stopPrank();
        // vm.selectFork(arbFork);
        // arbBeanHeads.mintGenesis(USER, params, tokenAmount, address(mockArbToken));
        _;
    }

    function test_sendSellTokenRequest_WithPermit() public mintedTokens {
        uint256 tokenId = 0;
        uint256 price = 10 ether;

        address owner = MINTER;
        uint256 nonce0 = getTokenNonce(tokenId);
        uint64 sellDeadline = uint64(block.timestamp + 1 hours);
        bytes32 domainSeparator = sepoliaBeanHeads.DOMAIN_SEPARATOR();

        // Sell struct
        PermitTypes.Sell memory s =
            PermitTypes.Sell({owner: owner, tokenId: tokenId, price: price, nonce: nonce0, deadline: sellDeadline});

        bytes memory sellSig = _signSellPermit(s, domainSeparator, MINTER_PK);

        // build permit signature
        uint256 permitNonce = nonce0 + 1;
        uint64 permitDeadline = uint64(block.timestamp + 1 hours);
        address spender = address(sepoliaBeanHeads);

        bytes memory permitSig =
            _signERC721Permit(domainSeparator, spender, tokenId, permitNonce, permitDeadline, MINTER_PK);

        // send signal from ARB
        vm.selectFork(arbFork);
        vm.prank(MINTER);

        arbBeanHeadsBridge.sendSellTokenRequest(
            sepoliaNetworkDetails.chainSelector, s, sellSig, permitDeadline, permitSig
        );

        vm.warp(block.timestamp + 20 minutes);

        ccipSimulatorArbitrum.switchChainAndRouteMessage(sepoliaFork);

        vm.selectFork(sepoliaFork);

        uint256 newTokenPrice = sepoliaBeanHeads.getTokenSalePrice(tokenId);
        assertEq(newTokenPrice, price);
        assertEq(sepoliaBeanHeads.isTokenForSale(tokenId), true);
    }

    function test_buyTokenRequest() public mintedTokens {
        uint256 tokenId = 0;
        uint256 price = 10 ether;

        vm.selectFork(sepoliaFork);
        address owner = MINTER;
        vm.startPrank(owner);
        sepoliaBeanHeads.sellToken(tokenId, price);
        vm.stopPrank();

        assertEq(sepoliaBeanHeads.isTokenForSale(tokenId), true);
        assertEq(sepoliaBeanHeads.getTokenSalePrice(tokenId), price);

        // send signal from ARB
        vm.selectFork(arbFork);
        vm.startPrank(USER);
        mockArbToken.approve(address(arbBeanHeadsBridge), type(uint256).max);
        arbBeanHeadsBridge.sendBuyTokenRequest(
            sepoliaNetworkDetails.chainSelector, tokenId, address(mockArbToken), price
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 20 minutes);

        ccipSimulatorArbitrum.switchChainAndRouteMessage(sepoliaFork);

        vm.selectFork(sepoliaFork);
        uint256 userTokenBalance = sepoliaBeanHeads.balanceOf(USER);
        assertEq(userTokenBalance, 1);
        uint256 userTokenSupply = sepoliaBeanHeads.getTotalSupply();
        assertEq(userTokenSupply, 1);
        assertEq(sepoliaBeanHeads.getOwnerOf(tokenId), USER);
        assertEq(sepoliaBeanHeads.isTokenForSale(tokenId), false);
    }

    function test_cancelTokenSale_Local() public mintedTokens {
        uint256 tokenId = 0;

        vm.selectFork(sepoliaFork);
        address owner = MINTER;
        vm.startPrank(owner);
        sepoliaBeanHeads.sellToken(tokenId, 10 ether);
        vm.stopPrank();

        console.log(sepoliaBeanHeads.getOwnerOf(tokenId));
        assertEq(sepoliaBeanHeads.isTokenForSale(tokenId), true);

        uint256 nonce0 = getTokenNonce(tokenId);
        uint64 cancelDeadline = uint64(block.timestamp + 1 hours);
        bytes32 domainSeparator = sepoliaBeanHeads.DOMAIN_SEPARATOR();

        // Cancel struct
        PermitTypes.Cancel memory C =
            PermitTypes.Cancel({seller: owner, tokenId: tokenId, listingNonce: nonce0, deadline: cancelDeadline});

        bytes memory cancelSig = _signCancelPermit(C, domainSeparator, MINTER_PK);

        // cancel sale from ARB
        vm.selectFork(arbFork);
        vm.startPrank(owner);
        arbBeanHeadsBridge.sendCancelTokenSaleRequest(sepoliaNetworkDetails.chainSelector, C, cancelSig);
        vm.stopPrank();

        vm.warp(block.timestamp + 20 minutes);

        ccipSimulatorArbitrum.switchChainAndRouteMessage(sepoliaFork);

        vm.selectFork(sepoliaFork);

        assertEq(sepoliaBeanHeads.getOwnerOf(tokenId), owner);
        assertEq(sepoliaBeanHeads.isTokenForSale(tokenId), false);
    }

    function test_sendTransferTokenRequest_MintOnDest() public mintedTokens {
        uint256 tokenId = 0;

        vm.selectFork(sepoliaFork);
        address owner = MINTER;

        assertEq(sepoliaBeanHeads.getOwnerOf(tokenId), owner);

        // Sending tokenId from Sepolia to Arbitrum
        vm.startPrank(owner);
        mockSepoliaToken.approve(address(sepoliaBeanHeadsBridge), type(uint256).max);
        sepoliaBeanHeads.approve(address(sepoliaBeanHeadsBridge), tokenId);
        sepoliaBeanHeadsBridge.sendTransferTokenRequest(arbNetworkDetails.chainSelector, tokenId, USER);

        vm.warp(block.timestamp + 20 minutes);

        ccipSimulatorSepolia.switchChainAndRouteMessage(arbFork);

        vm.selectFork(arbFork);
        vm.startPrank(USER);
        assertEq(arbBeanHeads.getOwnerOf(tokenId), USER);
        assertEq(arbBeanHeads.balanceOf(USER), 1);
        assertEq(arbBeanHeads.getTotalSupply(), 1);
        vm.stopPrank();

        vm.selectFork(sepoliaFork);
        assertEq(sepoliaBeanHeads.isTokenLocked(tokenId), true);
    }

    function test_sendTransferTokenRequest_ReturnToSource() public mintedTokens {
        uint256 tokenId = 0;

        vm.selectFork(sepoliaFork);
        address owner = MINTER;

        assertEq(sepoliaBeanHeads.getOwnerOf(tokenId), owner);

        // Sending tokenId from Sepolia to Arbitrum
        vm.startPrank(owner);
        mockSepoliaToken.approve(address(sepoliaBeanHeadsBridge), type(uint256).max);
        sepoliaBeanHeads.approve(address(sepoliaBeanHeadsBridge), tokenId);
        sepoliaBeanHeadsBridge.sendTransferTokenRequest(arbNetworkDetails.chainSelector, tokenId, USER);

        vm.warp(block.timestamp + 20 minutes);

        ccipSimulatorSepolia.switchChainAndRouteMessage(arbFork);

        vm.selectFork(sepoliaFork);
        assertEq(sepoliaBeanHeads.isTokenLocked(tokenId), true);

        vm.selectFork(arbFork);
        vm.startPrank(USER);
        assertEq(arbBeanHeads.getOwnerOf(tokenId), USER);
        assertEq(arbBeanHeads.balanceOf(USER), 1);
        assertEq(arbBeanHeads.getTotalSupply(), 1);
        vm.stopPrank();

        // Now sending the token back to Sepolia
        vm.selectFork(arbFork);
        vm.startPrank(USER);
        mockArbToken.approve(address(arbBeanHeadsBridge), type(uint256).max);
        arbBeanHeads.approve(address(arbBeanHeadsBridge), tokenId);
        arbBeanHeadsBridge.sendTransferTokenRequest(sepoliaNetworkDetails.chainSelector, tokenId, owner);

        vm.warp(block.timestamp + 20 minutes);
        ccipSimulatorArbitrum.switchChainAndRouteMessage(sepoliaFork);

        vm.selectFork(sepoliaFork);
        vm.startPrank(owner);
        assertEq(sepoliaBeanHeads.getOwnerOf(tokenId), owner);
        assertEq(sepoliaBeanHeads.balanceOf(owner), 1);
        assertEq(sepoliaBeanHeads.getTotalSupply(), 1);
        assertEq(sepoliaBeanHeads.isTokenLocked(tokenId), false);
    }

    modifier mintedMultipleTokens() {
        vm.selectFork(sepoliaFork);
        vm.startPrank(MINTER);
        uint256 tokenAmount = 3;
        sepoliaBeanHeads.mintGenesis(MINTER, params, tokenAmount, address(mockSepoliaToken));
        assertEq(sepoliaBeanHeads.balanceOf(MINTER), tokenAmount);
        assertEq(sepoliaBeanHeads.getTotalSupply(), tokenAmount);
        vm.stopPrank();

        _;
    }

    function test_sendBatchSellTokenRequest() public mintedMultipleTokens {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;

        uint256 price = 10 ether;
        address owner = MINTER;
        uint64 sellDeadline = uint64(block.timestamp + 1 hours);
        address spender = address(sepoliaBeanHeads);
        bytes32 domainSeparator = sepoliaBeanHeads.DOMAIN_SEPARATOR();

        PermitTypes.Sell[] memory sellPermits = new PermitTypes.Sell[](tokenIds.length);
        bytes[] memory sellSigs = new bytes[](tokenIds.length);
        uint256[] memory permitDeadlines = new uint256[](tokenIds.length);
        uint256[] memory permitNonces = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 nonce = getTokenNonce(tokenId);
            sellPermits[i] =
                PermitTypes.Sell({owner: owner, tokenId: tokenId, price: price, nonce: nonce, deadline: sellDeadline});
            sellSigs[i] = _signSellPermit(sellPermits[i], domainSeparator, MINTER_PK);
            permitDeadlines[i] = block.timestamp + 1 hours;
            permitNonces[i] = nonce + 1;
        }

        bytes[] memory permitSigs = _signERC721Permits(
            domainSeparator, spender, tokenIds, permitNonces, toUint64Array(permitDeadlines), MINTER_PK
        );

        // send signal from ARB
        vm.selectFork(arbFork);
        vm.startPrank(owner);
        mockArbToken.approve(address(arbBeanHeadsBridge), type(uint256).max);
        arbBeanHeadsBridge.sendBatchSellTokenRequest(
            sepoliaNetworkDetails.chainSelector, sellPermits, sellSigs, permitDeadlines, permitSigs
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 20 minutes);
        ccipSimulatorArbitrum.switchChainAndRouteMessage(sepoliaFork);

        vm.selectFork(sepoliaFork);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 newTokenPrice = sepoliaBeanHeads.getTokenSalePrice(tokenId);
            assertEq(newTokenPrice, price);
            assertEq(sepoliaBeanHeads.isTokenForSale(tokenId), true);
            assertEq(sepoliaBeanHeads.getTokenSalePrice(tokenId), price);
            assertEq(sepoliaBeanHeads.getOwnerOf(tokenId), owner);
        }
    }

    function test_sendBatchBuyTokenRequest() public mintedMultipleTokens {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;

        uint256 price = 10 ether;

        vm.selectFork(sepoliaFork);
        address owner = MINTER;
        vm.startPrank(owner);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            sepoliaBeanHeads.sellToken(tokenIds[i], price);
        }
        vm.stopPrank();

        assertEq(sepoliaBeanHeads.isTokenForSale(tokenIds[0]), true);
        assertEq(sepoliaBeanHeads.getTokenSalePrice(tokenIds[0]), price);

        mockSepoliaToken.mint(address(sepoliaBeanHeadsBridge), 100 ether);

        vm.prank(address(sepoliaBeanHeadsBridge));
        mockSepoliaToken.approve(address(sepoliaBeanHeads), type(uint256).max);

        // send signal from ARB
        vm.selectFork(arbFork);
        uint256[] memory prices = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            prices[i] = price;
        }

        vm.startPrank(USER);
        mockArbToken.mint(USER, 100 ether);
        mockArbToken.approve(address(arbBeanHeadsBridge), type(uint256).max);
        arbBeanHeadsBridge.sendBatchBuyTokenRequest(
            sepoliaNetworkDetails.chainSelector, tokenIds, prices, address(mockArbToken)
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 20 minutes);

        ccipSimulatorArbitrum.switchChainAndRouteMessage(sepoliaFork);

        vm.selectFork(sepoliaFork);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 userTokenBalance = sepoliaBeanHeads.balanceOf(USER);
            assertEq(userTokenBalance, 3);
            uint256 userTokenSupply = sepoliaBeanHeads.getTotalSupply();
            assertEq(userTokenSupply, 3);
            assertEq(sepoliaBeanHeads.getOwnerOf(tokenIds[i]), USER);
            assertEq(sepoliaBeanHeads.isTokenForSale(tokenIds[i]), false);
        }
    }

    function test_sendBatchCancelTokenSaleRequest() public mintedMultipleTokens {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;

        address owner = MINTER;
        uint64[] memory cancelDeadline = new uint64[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            cancelDeadline[i] = uint64(block.timestamp + 1 hours);
        }

        PermitTypes.Cancel[] memory cancelPermits = new PermitTypes.Cancel[](tokenIds.length);
        uint256[] memory nonces = new uint256[](tokenIds.length);
        bytes[] memory cancelSigs = new bytes[](tokenIds.length);
        bytes32 domainSeparator = sepoliaBeanHeads.DOMAIN_SEPARATOR();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 nonce = getTokenNonce(tokenId);
            cancelPermits[i] =
                PermitTypes.Cancel({seller: owner, tokenId: tokenId, listingNonce: nonce, deadline: cancelDeadline[i]});
            nonces[i] = nonce;
            cancelSigs[i] = _signCancelPermit(cancelPermits[i], domainSeparator, MINTER_PK);
        }

        // Get destination chain's domain separator before generating signatures
        vm.selectFork(sepoliaFork);

        // Send batch cancel from ARB
        vm.selectFork(arbFork);
        vm.startPrank(owner);
        arbBeanHeadsBridge.sendBatchCancelTokenSaleRequest(
            sepoliaNetworkDetails.chainSelector, cancelPermits, cancelSigs
        );
        vm.stopPrank();

        // Process CCIP message
        vm.warp(block.timestamp + 10 minutes);
        ccipSimulatorArbitrum.switchChainAndRouteMessage(sepoliaFork);

        vm.selectFork(sepoliaFork);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(sepoliaBeanHeads.getOwnerOf(tokenIds[i]), owner);
            assertEq(sepoliaBeanHeads.isTokenForSale(tokenIds[i]), false);
        }
    }

    // sanity check on the facet selector
    function testFacetSelector() public {
        vm.selectFork(sepoliaFork);
        bytes4 sel = bytes4(keccak256("balanceOf(address)"));
        address facet = IDiamondLoupe(address(sepoliaBeanHeads)).facetAddress(sel);
        console.log("Facet address for balanceOf:", facet);
        assert(facet != address(0));
    }

    // helper function to get the current nonce
    function getTokenNonce(uint256 tokenId) internal view returns (uint256) {
        (bool ok, bytes memory data) =
            address(sepoliaBeanHeads).staticcall(abi.encodeWithSignature("nonces(uint256)", tokenId));
        require(ok, "Failed to get token nonce");
        return abi.decode(data, (uint256));
    }

    function _signSellPermit(PermitTypes.Sell memory s, bytes32 domainSeparator, uint256 privateKey)
        internal
        pure
        returns (bytes memory)
    {
        bytes32 structHash =
            keccak256(abi.encode(PermitTypes.SELL_TYPEHASH, s.owner, s.tokenId, s.price, s.nonce, s.deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s_) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s_, v);
    }

    function _signERC721Permit(
        bytes32 domainSeparator,
        address spender,
        uint256 tokenId,
        uint256 nonce,
        uint64 deadline,
        uint256 privateKey
    ) internal pure returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s_) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s_, v);
    }

    function _signERC721Permits(
        bytes32 domainSeparator,
        address spender,
        uint256[] memory tokenIds,
        uint256[] memory nonces,
        uint64[] memory deadlines,
        uint256 privateKey
    ) internal pure returns (bytes[] memory sigs) {
        require(tokenIds.length == nonces.length && tokenIds.length == deadlines.length, "Mismatched lengths");

        sigs = new bytes[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            bytes32 structHash = keccak256(
                abi.encode(
                    keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"),
                    spender,
                    tokenIds[i],
                    nonces[i],
                    deadlines[i]
                )
            );

            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

            sigs[i] = abi.encodePacked(r, s, v);
        }

        return sigs;
    }

    function _signCancelPermit(PermitTypes.Cancel memory c, bytes32 domainSeparator, uint256 privateKey)
        internal
        pure
        returns (bytes memory)
    {
        bytes32 structHash =
            keccak256(abi.encode(PermitTypes.CANCEL_TYPEHASH, c.seller, c.tokenId, c.listingNonce, c.deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s_) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s_, v);
    }

    function toUint64Array(uint256[] memory input) internal pure returns (uint64[] memory output) {
        output = new uint64[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = uint64(input[i]);
        }
    }
}
