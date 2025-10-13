// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RegistryModuleOwnerCustom} from
    "chainlink-brownie-contracts/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from
    "chainlink-brownie-contracts/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool, IERC20} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {BeanHeadsBridge, IBeanHeadsBridge} from "src/bridge/BeanHeadsBridge.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";

contract InteractionBridges is Script {
    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (HelperConfig.NetworkConfig memory config,,) = helperConfig.getActiveNetworkConfig();

        vm.startBroadcast(config.deployerKey);

        address arbBridgeAddress;
        address opBridgeAddress;

        if (block.chainid == helperConfig.OPTIMISM_SEPOLIA_CHAIN_ID()) {
            opBridgeAddress = DevOpsTools.get_most_recent_deployment("BeanHeadsBridge", block.chainid);
            arbBridgeAddress =
                DevOpsTools.get_most_recent_deployment("BeanHeadsBridge", helperConfig.ARBITRUM_SEPOLIA_CHAIN_ID());

            console.log("Setting Optimism Sepolia Bridge remote to Arbitrum Sepolia Bridge");
            IBeanHeadsBridge(opBridgeAddress).setRemoteBridge(arbBridgeAddress, true);
        } else if (block.chainid == helperConfig.ARBITRUM_SEPOLIA_CHAIN_ID()) {
            opBridgeAddress =
                DevOpsTools.get_most_recent_deployment("BeanHeadsBridge", helperConfig.OPTIMISM_SEPOLIA_CHAIN_ID());
            arbBridgeAddress = DevOpsTools.get_most_recent_deployment("BeanHeadsBridge", block.chainid);

            console.log("Setting Arbitrum Sepolia Bridge remote to Optimism Sepolia Bridge");
            IBeanHeadsBridge(arbBridgeAddress).setRemoteBridge(opBridgeAddress, true);
        }

        vm.stopBroadcast();
    }
}
