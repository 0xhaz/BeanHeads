// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockLinkToken} from "chainlink-brownie-contracts/contracts/src/v0.8/mocks/MockLinkToken.sol";
import {MockV3Aggregator} from "chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol";

// import {BeanHeads} from "src/core/BeanHeads.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
// import {BeanHeadsBreeder} from "src/vrf/BeanHeadsBreeder.sol";
// import {BeanHeadsBridge} from "src/bridge/BeanHeadsBridge.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address linkToken;
        address usdPriceFeed;
        uint256 deployerKey;
    }

    struct VrfConfig {
        address vrfCoordinator;
        uint256 subscriptionId;
        bytes32 keyHash;
        uint32 gasLimit;
        uint16 requestConfirmations;
        uint256 breedCoolDown;
        uint256 maxBreedRequest;
    }

    struct CrossChainConfig {
        address routerClient;
        address usdcToken;
        address registryModule;
        address tokenAdminRegistry;
        address usdcTokenPool;
    }

    NetworkConfig public activeNetworkConfig;
    VrfConfig public activeVrfConfig;
    CrossChainConfig public activeCrossChainConfig;
    VRFCoordinatorV2_5Mock public vrfCoordinatorMock;

    address public remoteBridge;

    uint8 public constant DECIMALS = 8;
    int256 public constant USD_PRICE_FEED = 1e8;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint64 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint64 public constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155420;
    uint64 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint64 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint64 public constant LOCAL_CHAIN_ID = 31337;
    uint96 public MOCK_BASE_FEE = 0.01 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;

    // VRF Init
    uint32 public constant GAS_LIMIT = 1_200_000;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint256 public constant BREED_COOLDOWN = 50;
    uint256 public constant MAX_BREED_REQUEST = 5;

    // VRF Coordinator
    address public constant SEPOLIA_VRF_COORDINATOR = 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61;
    address public constant ARBITRUM_VRF_COORDINATOR = 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61;
    address public constant OPTIMISM_VRF_COORDINATOR = 0x02667f44a6a44E4BDddCF80e724512Ad3426B17d;

    // Subscription ID
    uint256 public constant SEPOLIA_VRF_SUB_ID =
        62006562457364504435480039715090775291352508890600299278052625743272861229499;
    uint256 public constant ARBITRUM_VRF_SUB_ID =
        67358612661498263543516139562168295078269238317925272370889272572573929337815;
    uint256 public constant OPTIMISM_VRF_SUB_ID =
        83615733694144098481723925549149254030585331773564248453894784102817899297545;

    // Key Hash
    bytes32 public constant SEPOLIA_KEY_HASH = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    bytes32 public constant ARBITRUM_KEY_HASH = 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be;
    bytes32 public constant OPTIMISM_KEY_HASH = 0xc3d5bc4d5600fa71f7a50b9ad841f14f24f9ca4236fd00bdb5fda56b052b28a4;

    // LINK/ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;
    uint64 public constant OP_SEPOLIA_CHAIN_SELECTOR = 5224473277236331295;

    // USDC Details
    address public constant SEPOLIA_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address public constant OP_SEPOLIA_USDC = 0x5fd84259d66Cd46123540766Be93DFE6D43130D7;
    address public constant ARBITRUM_SEPOLIA_USDC = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;

    // Token Registry
    address public constant SEPOLIA_TOKEN_ADMIN_REGISTRY = 0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82;
    address public constant OP_SEPOLIA_TOKEN_ADMIN_REGISTRY = 0x1d702b1FA12F347f0921C722f9D9166F00DEB67A;
    address public constant ARBITRUM_SEPOLIA_TOKEN_ADMIN_REGISTRY = 0x8126bE56454B628a88C17849B9ED99dd5a11Bd2f;

    // Token Registry Modules
    address public constant SEPOLIA_REGISTRY_MODULE = 0x62e731218d0D47305aba2BE3751E7EE9E5520790;
    address public constant OP_SEPOLIA_REGISTRY_MODULE = 0x49c4ba01dc6F5090f9df43Ab8F79449Db91A0CBB;
    address public constant ARBITRUM_SEPOLIA_REGISTRY_MODULE = 0xE625f0b8b0Ac86946035a7729Aba124c8A64cf69;

    // USDC Token Pool
    address public constant SEPOLIA_USDC_TOKEN_POOL = 0x02eef4b366225362180d704C917c50f6c46af9e0;
    address public constant OP_SEPOLIA_USDC_TOKEN_POOL = 0x18591F40d9981C395fb85aB1982441F14657903f;
    address public constant ARBITRUM_SEPOLIA_USDC_TOKEN_POOL = 0xbfd2b0b21bd22fD9aB482BAAbc815ef4974F769f;

    // USDC Price FEED
    address public constant SEPOLIA_USDC_USD_PRICE_FEED = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
    address public constant OP_SEPOLIA_USDC_USD_PRICE_FEED = 0x6e44e50E3cc14DD16e01C590DC1d7020cb36eD4C;
    address public constant ARBITRUM_SEPOLIA_USDC_USD_PRICE_FEED = 0x0153002d20B96532C639313c2d54c3dA09109309;

    // Link Token Address
    address public constant SEPOLIA_LINK_TOKEN = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address public constant OP_SEPOLIA_LINK_TOKEN = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    address public constant ARBITRUM_SEPOLIA_LINK_TOKEN = 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;

    // Router Client
    address public constant SEPOLIA_ROUTER_CLIENT = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    address public constant OP_SEPOLIA_ROUTER_CLIENT = 0x114A20A10b43D4115e5aeef7345a1A71d2a60C57;
    address public constant ARBITRUM_SEPOLIA_ROUTER_CLIENT = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;

    // Chain Selector
    uint64 public constant SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;
    uint64 public constant ARBITRUM_CHAIN_SELECTOR = 3478487238524512106;
    uint64 public constant OPTIMISM_CHAIN_SELECTOR = 5224473277236331295;

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;
    mapping(uint256 => VrfConfig) public chainIdToVrfConfig;
    mapping(uint256 => CrossChainConfig) public chainIdToCrossChainConfig;

    constructor() {
        if (block.chainid == LOCAL_CHAIN_ID) {
            _setAnvilConfig();
        } else if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            _setSepoliaConfig();
        } else if (block.chainid == OPTIMISM_SEPOLIA_CHAIN_ID) {
            _setOpSepoliaConfig();
        } else if (block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID) {
            _setArbitrumSepoliaConfig();
        } else {
            revert("Unsupported chain ID");
        }

        uint256 current = block.chainid;
        activeNetworkConfig = chainIdToNetworkConfig[current];

        console.log("Active network config set for chain ID:", current);
    }

    function _setAnvilConfig() public returns (NetworkConfig memory, VrfConfig memory, CrossChainConfig memory) {
        if (activeVrfConfig.vrfCoordinator != address(0)) {
            return (activeNetworkConfig, activeVrfConfig, activeCrossChainConfig);
        }

        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);
        vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);

        uint256 subscriptionId = vrfCoordinatorMock.createSubscription();
        MockLinkToken linkToken = new MockLinkToken();

        MockV3Aggregator usdPriceFeed = new MockV3Aggregator(DECIMALS, USD_PRICE_FEED);

        activeNetworkConfig = NetworkConfig({
            linkToken: address(linkToken),
            usdPriceFeed: address(usdPriceFeed),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });

        activeVrfConfig = VrfConfig({
            vrfCoordinator: address(vrfCoordinatorMock),
            subscriptionId: subscriptionId,
            keyHash: bytes32(0),
            gasLimit: GAS_LIMIT,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            breedCoolDown: BREED_COOLDOWN,
            maxBreedRequest: MAX_BREED_REQUEST
        });

        activeCrossChainConfig = CrossChainConfig({
            routerClient: address(0xdead),
            usdcToken: address(0xbeef),
            registryModule: address(0xcafe),
            tokenAdminRegistry: address(0xbabe),
            usdcTokenPool: address(0xfeed)
        });

        chainIdToNetworkConfig[LOCAL_CHAIN_ID] = activeNetworkConfig;
        chainIdToVrfConfig[LOCAL_CHAIN_ID] = activeVrfConfig;
        chainIdToCrossChainConfig[LOCAL_CHAIN_ID] = activeCrossChainConfig;

        vm.stopBroadcast();
        return (activeNetworkConfig, activeVrfConfig, activeCrossChainConfig);
    }

    function _setSepoliaConfig() public returns (NetworkConfig memory, VrfConfig memory, CrossChainConfig memory) {
        activeNetworkConfig = NetworkConfig({
            linkToken: SEPOLIA_LINK_TOKEN,
            usdPriceFeed: SEPOLIA_USDC_USD_PRICE_FEED,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });

        activeVrfConfig = VrfConfig({
            vrfCoordinator: SEPOLIA_VRF_COORDINATOR,
            subscriptionId: SEPOLIA_VRF_SUB_ID,
            keyHash: SEPOLIA_KEY_HASH,
            gasLimit: GAS_LIMIT,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            breedCoolDown: BREED_COOLDOWN,
            maxBreedRequest: MAX_BREED_REQUEST
        });

        activeCrossChainConfig = CrossChainConfig({
            routerClient: SEPOLIA_ROUTER_CLIENT,
            usdcToken: SEPOLIA_USDC,
            registryModule: SEPOLIA_REGISTRY_MODULE,
            tokenAdminRegistry: SEPOLIA_TOKEN_ADMIN_REGISTRY,
            usdcTokenPool: SEPOLIA_USDC_TOKEN_POOL
        });

        chainIdToNetworkConfig[ETH_SEPOLIA_CHAIN_ID] = activeNetworkConfig;
        chainIdToVrfConfig[ETH_SEPOLIA_CHAIN_ID] = activeVrfConfig;
        chainIdToCrossChainConfig[ETH_SEPOLIA_CHAIN_ID] = activeCrossChainConfig;
        return (activeNetworkConfig, activeVrfConfig, activeCrossChainConfig);
    }

    function _setOpSepoliaConfig() public returns (NetworkConfig memory, VrfConfig memory, CrossChainConfig memory) {
        activeNetworkConfig = NetworkConfig({
            linkToken: OP_SEPOLIA_LINK_TOKEN,
            usdPriceFeed: OP_SEPOLIA_USDC_USD_PRICE_FEED,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });

        activeVrfConfig = VrfConfig({
            vrfCoordinator: OPTIMISM_VRF_COORDINATOR,
            subscriptionId: OPTIMISM_VRF_SUB_ID,
            keyHash: OPTIMISM_KEY_HASH,
            gasLimit: GAS_LIMIT,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            breedCoolDown: BREED_COOLDOWN,
            maxBreedRequest: MAX_BREED_REQUEST
        });

        activeCrossChainConfig = CrossChainConfig({
            routerClient: OP_SEPOLIA_ROUTER_CLIENT,
            usdcToken: OP_SEPOLIA_USDC,
            registryModule: OP_SEPOLIA_REGISTRY_MODULE,
            tokenAdminRegistry: OP_SEPOLIA_TOKEN_ADMIN_REGISTRY,
            usdcTokenPool: OP_SEPOLIA_USDC_TOKEN_POOL
        });

        chainIdToNetworkConfig[OPTIMISM_SEPOLIA_CHAIN_ID] = activeNetworkConfig;
        chainIdToVrfConfig[OPTIMISM_SEPOLIA_CHAIN_ID] = activeVrfConfig;
        chainIdToCrossChainConfig[OPTIMISM_SEPOLIA_CHAIN_ID] = activeCrossChainConfig;

        return (activeNetworkConfig, activeVrfConfig, activeCrossChainConfig);
    }

    function _setArbitrumSepoliaConfig()
        public
        returns (NetworkConfig memory, VrfConfig memory, CrossChainConfig memory)
    {
        activeNetworkConfig = NetworkConfig({
            linkToken: ARBITRUM_SEPOLIA_LINK_TOKEN,
            usdPriceFeed: ARBITRUM_SEPOLIA_USDC_USD_PRICE_FEED,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });

        activeVrfConfig = VrfConfig({
            vrfCoordinator: ARBITRUM_VRF_COORDINATOR,
            subscriptionId: ARBITRUM_VRF_SUB_ID,
            keyHash: ARBITRUM_KEY_HASH,
            gasLimit: GAS_LIMIT,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            breedCoolDown: BREED_COOLDOWN,
            maxBreedRequest: MAX_BREED_REQUEST
        });

        activeCrossChainConfig = CrossChainConfig({
            routerClient: ARBITRUM_SEPOLIA_ROUTER_CLIENT,
            usdcToken: ARBITRUM_SEPOLIA_USDC,
            registryModule: ARBITRUM_SEPOLIA_REGISTRY_MODULE,
            tokenAdminRegistry: ARBITRUM_SEPOLIA_TOKEN_ADMIN_REGISTRY,
            usdcTokenPool: ARBITRUM_SEPOLIA_USDC_TOKEN_POOL
        });

        chainIdToNetworkConfig[ARBITRUM_SEPOLIA_CHAIN_ID] = activeNetworkConfig;
        chainIdToVrfConfig[ARBITRUM_SEPOLIA_CHAIN_ID] = activeVrfConfig;
        chainIdToCrossChainConfig[ARBITRUM_SEPOLIA_CHAIN_ID] = activeCrossChainConfig;

        return (activeNetworkConfig, activeVrfConfig, activeCrossChainConfig);
    }

    function getActiveNetworkConfig()
        public
        view
        returns (NetworkConfig memory, VrfConfig memory, CrossChainConfig memory)
    {
        if (block.chainid == LOCAL_CHAIN_ID) {
            return (
                chainIdToNetworkConfig[LOCAL_CHAIN_ID],
                chainIdToVrfConfig[LOCAL_CHAIN_ID],
                chainIdToCrossChainConfig[LOCAL_CHAIN_ID]
            );
        } else if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            return (
                chainIdToNetworkConfig[ETH_SEPOLIA_CHAIN_ID],
                chainIdToVrfConfig[ETH_SEPOLIA_CHAIN_ID],
                chainIdToCrossChainConfig[ETH_SEPOLIA_CHAIN_ID]
            );
        } else if (block.chainid == OPTIMISM_SEPOLIA_CHAIN_ID) {
            return (
                chainIdToNetworkConfig[OPTIMISM_SEPOLIA_CHAIN_ID],
                chainIdToVrfConfig[OPTIMISM_SEPOLIA_CHAIN_ID],
                chainIdToCrossChainConfig[OPTIMISM_SEPOLIA_CHAIN_ID]
            );
        } else if (block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID) {
            return (
                chainIdToNetworkConfig[ARBITRUM_SEPOLIA_CHAIN_ID],
                chainIdToVrfConfig[ARBITRUM_SEPOLIA_CHAIN_ID],
                chainIdToCrossChainConfig[ARBITRUM_SEPOLIA_CHAIN_ID]
            );
        } else {
            revert("Unsupported chain ID");
        }
    }
}
