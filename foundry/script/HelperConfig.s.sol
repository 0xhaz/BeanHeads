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
        address routerClient;
        address remoteBridge;
        address linkToken;
        address usdPriceFeed;
        address vrfCoordinator;
        uint256 subscriptionId;
        bytes32 keyHash;
        uint256 deployerKey;
    }

    address public remoteBridge;

    uint8 public constant DECIMALS = 8;
    int256 public constant USD_PRICE_FEED = 1e8;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155420;
    uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint96 public MOCK_BASE_FEE = 0.01 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK/ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;
    uint64 public constant OP_SEPOLIA_CHAIN_SELECTOR = 5224473277236331295;

    // Sepolia Details
    address public constant SEPOLIA_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

    NetworkConfig public activeNetworkConfig;

    VRFCoordinatorV2_5Mock public vrfCoordinatorMock;

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

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

    function _setAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);
        vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);

        uint256 subscriptionId = vrfCoordinatorMock.createSubscription();
        MockLinkToken linkToken = new MockLinkToken();

        MockV3Aggregator usdPriceFeed = new MockV3Aggregator(DECIMALS, USD_PRICE_FEED);

        activeNetworkConfig = NetworkConfig({
            routerClient: address(0),
            remoteBridge: address(0),
            linkToken: address(linkToken),
            usdPriceFeed: address(usdPriceFeed),
            vrfCoordinator: address(vrfCoordinatorMock),
            subscriptionId: subscriptionId,
            keyHash: bytes32(0),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });

        chainIdToNetworkConfig[LOCAL_CHAIN_ID] = activeNetworkConfig;
        vm.stopBroadcast();
        return activeNetworkConfig;
    }

    function _setSepoliaConfig() public returns (NetworkConfig memory) {
        activeNetworkConfig = NetworkConfig({
            routerClient: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
            remoteBridge: address(0),
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            usdPriceFeed: 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            subscriptionId: 5283,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
        chainIdToNetworkConfig[ETH_SEPOLIA_CHAIN_ID] = activeNetworkConfig;
        return activeNetworkConfig;
    }

    function _setOpSepoliaConfig() public returns (NetworkConfig memory) {
        activeNetworkConfig = NetworkConfig({
            routerClient: 0x114A20A10b43D4115e5aeef7345a1A71d2a60C57,
            remoteBridge: address(0),
            linkToken: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
            usdPriceFeed: 0x6e44e50E3cc14DD16e01C590DC1d7020cb36eD4C,
            vrfCoordinator: 0x02667f44a6a44E4BDddCF80e724512Ad3426B17d,
            subscriptionId: 258,
            keyHash: 0xc3d5bc4d5600fa71f7a50b9ad841f14f24f9ca4236fd00bdb5fda56b052b28a4,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
        chainIdToNetworkConfig[OPTIMISM_SEPOLIA_CHAIN_ID] = activeNetworkConfig;
        return activeNetworkConfig;
    }

    function _setArbitrumSepoliaConfig() public returns (NetworkConfig memory) {
        activeNetworkConfig = NetworkConfig({
            routerClient: 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165,
            remoteBridge: address(0),
            linkToken: 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E,
            usdPriceFeed: 0x0153002d20B96532C639313c2d54c3dA09109309,
            vrfCoordinator: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61,
            subscriptionId: 403,
            keyHash: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
        chainIdToNetworkConfig[ARBITRUM_SEPOLIA_CHAIN_ID] = activeNetworkConfig;
        return activeNetworkConfig;
    }

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        if (block.chainid == LOCAL_CHAIN_ID) {
            return chainIdToNetworkConfig[LOCAL_CHAIN_ID];
        } else if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            return chainIdToNetworkConfig[ETH_SEPOLIA_CHAIN_ID];
        } else if (block.chainid == OPTIMISM_SEPOLIA_CHAIN_ID) {
            return chainIdToNetworkConfig[OPTIMISM_SEPOLIA_CHAIN_ID];
        } else if (block.chainid == ARBITRUM_SEPOLIA_CHAIN_ID) {
            return chainIdToNetworkConfig[ARBITRUM_SEPOLIA_CHAIN_ID];
        } else {
            revert("Unsupported chain ID");
        }
    }
}
