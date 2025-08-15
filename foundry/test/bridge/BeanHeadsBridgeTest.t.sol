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
        assertEq(IERC173(address(sepoliaBeanHeadsBridge)).owner(), ownerSepolia);
        assertEq(IERC173(address(sepoliaBeanHeads)).owner(), ownerSepolia);

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

        // mockSepoliaToken.transfer(address(sepoliaTokenPool), 10_000 ether);
        // mockSepoliaToken.transfer(address(sepoliaBeanHeadsBridge), 10_000 ether);

        sepoliaBeanHeadsBridge.setRemoteBridge(address(arbBeanHeadsBridge));
        ccipSimulatorSepolia.requestLinkFromFaucet(address(sepoliaBeanHeadsBridge), 10 ether);
        assertEq(sepoliaBeanHeadsBridge.remoteBridgeAddresses(address(arbBeanHeadsBridge)), true);
        vm.stopPrank();

        vm.startPrank(ownerSepolia);
        sepoliaBeanHeads.setAllowedToken(address(mockSepoliaToken), true);
        // sepoliaBeanHeads.setAllowedToken(address(sepoliaLinkToken), true);
        // sepoliaBeanHeads.setAllowedToken(address(mockArbToken), true);
        sepoliaBeanHeads.addPriceFeed(address(mockSepoliaToken), address(priceFeedSepolia));
        // sepoliaBeanHeads.addPriceFeed(address(mockArbToken), address(priceFeedArbitrum));
        sepoliaBeanHeads.setMintPrice(MINT_PRICE);

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

        // mockArbToken.transfer(address(arbTokenPool), 10_000 ether);
        // mockArbToken.transfer(address(arbBeanHeadsBridge), 10_000 ether);

        arbBeanHeadsBridge.setRemoteBridge(address(sepoliaBeanHeadsBridge));
        ccipSimulatorArbitrum.requestLinkFromFaucet(address(arbBeanHeadsBridge), 10 ether);
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
        vm.startPrank(ownerSepolia);
        sepoliaBeanHeads.setAllowedToken(address(mockArbToken), true);
        sepoliaBeanHeads.addPriceFeed(address(mockArbToken), address(priceFeedArbitrum));
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(ownerArbitrum);
        arbBeanHeads.setAllowedToken(address(mockSepoliaToken), true);
        arbBeanHeads.addPriceFeed(address(mockSepoliaToken), address(priceFeedSepolia));
        vm.stopPrank();

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
        assertEq(sepoliaBeanHeadsBridge.owner(), ownerSepolia);
        assertEq(IERC173(address(sepoliaBeanHeads)).owner(), ownerSepolia);
        assertEq(sepoliaBeanHeads.isTokenAllowed(address(mockSepoliaToken)), true);
        assertEq(sepoliaBeanHeads.isTokenAllowed(address(mockArbToken)), true);
        assertEq(sepoliaBeanHeadsBridge.remoteBridgeAddresses(address(arbBeanHeadsBridge)), true);
        assertEq(sepoliaBeanHeads.getMintPrice(), MINT_PRICE);
        assertEq(sepoliaBeanHeads.name(), "BeanHeads");
        assertEq(sepoliaBeanHeads.symbol(), "BEANS");
        vm.stopPrank();

        vm.selectFork(arbFork);
        vm.startPrank(ownerArbitrum);
        assertEq(arbBeanHeadsBridge.owner(), ownerArbitrum);
        assertEq(IERC173(address(arbBeanHeads)).owner(), ownerArbitrum);
        assertEq(arbBeanHeads.isTokenAllowed(address(mockArbToken)), true);
        assertEq(arbBeanHeads.isTokenAllowed(address(mockSepoliaToken)), true);
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

        console.log(sepoliaBeanHeads.getOwnerOf(tokenId));
        console.log(owner);
        assertEq(sepoliaBeanHeads.getOwnerOf(tokenId), owner);
        assertEq(sepoliaBeanHeads.isTokenForSale(tokenId), false);
    }

    function test_cancelTokenSale_Remote() public mintedTokens {
        uint256 tokenId = 0;
        uint256 price = 10 ether;

        address owner = MINTER;
        uint256 nonce0 = getTokenNonce(tokenId);
        uint64 sellDeadline = uint64(block.timestamp + 1 hours);
        uint64 permitDeadline = uint64(block.timestamp + 1 hours);
        address spender = address(sepoliaBeanHeads);
        uint256 permitNonce = nonce0 + 1;
        bytes32 domainSeparator = sepoliaBeanHeads.DOMAIN_SEPARATOR();
        {
            // Sell struct
            PermitTypes.Sell memory s =
                PermitTypes.Sell({owner: owner, tokenId: tokenId, price: price, nonce: nonce0, deadline: sellDeadline});

            bytes memory sellSig = _signSellPermit(s, domainSeparator, MINTER_PK);
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
            assertEq(sepoliaBeanHeads.getTokenSalePrice(tokenId), price);
            assertEq(sepoliaBeanHeads.isTokenForSale(tokenId), true);
            assertEq(sepoliaBeanHeads.getOwnerOf(tokenId), address(sepoliaBeanHeads));
        }

        // vm.warp(block.timestamp + 1 hours);
        // {
        //     uint64 cancelDeadline = uint64(block.timestamp + 1 hours);

        //     // Cancel struct
        //     PermitTypes.Cancel memory C =
        //         PermitTypes.Cancel({seller: owner, tokenId: tokenId, listingNonce: nonce0, deadline: cancelDeadline});

        //     bytes memory cancelSig = _signCancelPermit(C, domainSeparator, MINTER_PK);

        //     // cancel sale from ARB
        //     vm.selectFork(arbFork);
        //     vm.startPrank(owner);
        //     arbBeanHeadsBridge.sendCancelTokenSaleRequest(sepoliaNetworkDetails.chainSelector, C, cancelSig);
        //     vm.stopPrank();

        //     vm.warp(block.timestamp + 20 minutes);

        //     ccipSimulatorArbitrum.switchChainAndRouteMessage(sepoliaFork);

        //     vm.selectFork(sepoliaFork);
        //     assertEq(sepoliaBeanHeads.getOwnerOf(tokenId), owner);
        //     assertEq(sepoliaBeanHeads.isTokenForSale(tokenId), false);
        // }
    }

    // function test_sendMintTokenRequest_MoreDetails() public {
    //     vm.selectFork(arbFork);
    //     uint256 tokenAmount = 1;

    //     bytes memory encodeMintPayload = abi.encode(USER, params, tokenAmount);
    //     bytes memory mintGenesisCalldata = abi.encode(ActionType.MINT, encodeMintPayload);

    //     Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
    //     Client.EVMTokenAmount memory tokenAmountData =
    //         Client.EVMTokenAmount({token: address(mockArbToken), amount: tokenAmount});
    //     tokenAmounts[0] = tokenAmountData;

    //     IRouterClient routerArbClient = IRouterClient(arbNetworkDetails.routerAddress);

    //     Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
    //         receiver: abi.encode(arbBeanHeadsBridge),
    //         data: mintGenesisCalldata,
    //         tokenAmounts: tokenAmounts,
    //         feeToken: arbNetworkDetails.linkAddress,
    //         extraArgs: Client._argsToBytes(
    //             Client.EVMExtraArgsV1({
    //                 gasLimit: 500_000 // Set a default gas limit for the callback
    //             })
    //         )
    //     });

    //     uint256 fee = routerArbClient.getFee(sepoliaNetworkDetails.chainSelector, message);

    //     ccipSimulatorArbitrum.requestLinkFromFaucet(USER, 10 ether);
    //     vm.startPrank(USER);
    //     IERC20(address(mockArbToken)).approve(address(arbBeanHeadsBridge), type(uint256).max);
    //     IERC20(address(mockArbToken)).approve(address(routerArbClient), type(uint256).max);
    //     IERC20(arbNetworkDetails.linkAddress).approve(address(routerArbClient), fee);

    //     routerArbClient.ccipSend(sepoliaNetworkDetails.chainSelector, message);
    //     vm.stopPrank();

    //     ccipSimulatorArbitrum.switchChainAndRouteMessage(sepoliaFork);

    //     vm.selectFork(sepoliaFork);
    //     vm.prank(USER);
    //     uint256 userTokenBalance = sepoliaBeanHeads.balanceOf(USER);
    //     assertEq(userTokenBalance, tokenAmount);
    //     uint256 userTokenSupply = sepoliaBeanHeads.getTotalSupply();
    //     assertEq(userTokenSupply, tokenAmount);
    //     assertEq(sepoliaBeanHeads.getOwnerOf(0), USER);
    // }

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
}
