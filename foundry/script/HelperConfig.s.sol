// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockLinkToken} from "chainlink-brownie-contracts/contracts/src/v0.8/mocks/MockLinkToken.sol";

import {BeanHeads} from "src/core/BeanHeads.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
import {Genesis} from "src/types/Genesis.sol";
import {BeanHeadsBreeder} from "src/vrf/BeanHeadsBreeder.sol";
import {BeanHeadsBridge} from "src/bridge/BeanHeadsBridge.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address routerClient;
        address remoteBridge;
        address linkToken;
        address vrfCoordinator;
        uint256 subscriptionId;
        bytes32 keyHash;
        uint256 deployerKey;
    }

    address public remoteBridge;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint96 public MOCK_BASE_FEE = 0.01 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK/ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    NetworkConfig public activeNetworkConfig;

    VRFCoordinatorV2_5Mock public vrfCoordinatorMock;

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

    constructor() {
        if (block.chainid == LOCAL_CHAIN_ID) {
            _setAnvilConfig();
        } else if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            _setSepoliaConfig();
        } else {
            revert("Unsupported network");
        }
    }

    function _setAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);

        uint256 subscriptionId = vrfCoordinatorMock.createSubscription();
        MockLinkToken linkToken = new MockLinkToken();

        activeNetworkConfig = NetworkConfig({
            routerClient: address(0),
            remoteBridge: address(0),
            linkToken: address(linkToken),
            vrfCoordinator: address(vrfCoordinatorMock),
            subscriptionId: subscriptionId,
            keyHash: bytes32(0),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
        vm.stopBroadcast();
        return activeNetworkConfig;
    }

    function _setSepoliaConfig() public returns (NetworkConfig memory) {
        activeNetworkConfig = NetworkConfig({
            routerClient: address(0),
            remoteBridge: address(0),
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            subscriptionId: 62006562457364504435480039715090775291352508890600299278052625743272861229499,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
        return activeNetworkConfig;
    }
}
