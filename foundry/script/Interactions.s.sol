// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {RegistryModuleOwnerCustom} from
    "chainlink-brownie-contracts/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from
    "chainlink-brownie-contracts/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool, IERC20} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {BeanHeadsBridge, IBeanHeadsBridge} from "src/bridge/BeanHeadsBridge.sol";
import {BeanHeadsAdminFacet} from "src/facets/BeanHeads/BeanHeadsAdminFacet.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";
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
            IBeanHeadsBridge(opBridgeAddress).setRemoteBridge(
                helperConfig.ARBITRUM_CHAIN_SELECTOR(), arbBridgeAddress, true
            );
        } else if (block.chainid == helperConfig.ARBITRUM_SEPOLIA_CHAIN_ID()) {
            opBridgeAddress =
                DevOpsTools.get_most_recent_deployment("BeanHeadsBridge", helperConfig.OPTIMISM_SEPOLIA_CHAIN_ID());
            arbBridgeAddress = DevOpsTools.get_most_recent_deployment("BeanHeadsBridge", block.chainid);

            console.log("Setting Arbitrum Sepolia Bridge remote to Optimism Sepolia Bridge");
            IBeanHeadsBridge(arbBridgeAddress).setRemoteBridge(
                helperConfig.OPTIMISM_CHAIN_SELECTOR(), opBridgeAddress, true
            );
        }

        address adminFacet;

        if (block.chainid == helperConfig.ETH_SEPOLIA_CHAIN_ID()) {
            adminFacet = DevOpsTools.get_most_recent_deployment("BeanHeadsDiamond", block.chainid);
            IBeanHeads(adminFacet).setAllowedToken(config.linkToken, true);
            console.log("Link token allowed:", config.linkToken);
            IBeanHeads(adminFacet).setAllowedToken(helperConfig.SEPOLIA_USDC(), true);
            console.log("Sepolia USDC allowed:", helperConfig.SEPOLIA_USDC());
            IBeanHeads(adminFacet).setAllowedToken(helperConfig.ARBITRUM_SEPOLIA_USDC(), true);
            console.log("Arbitrum Sepolia USDC allowed:", helperConfig.ARBITRUM_SEPOLIA_USDC());
            IBeanHeads(adminFacet).setAllowedToken(helperConfig.OP_SEPOLIA_USDC(), true);
            console.log("Optimism Sepolia USDC allowed:", helperConfig.OP_SEPOLIA_USDC());
            IBeanHeads(adminFacet).addPriceFeed(helperConfig.SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Sepolia USDC price feed added:", config.usdPriceFeed);
            IBeanHeads(adminFacet).addPriceFeed(helperConfig.ARBITRUM_SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Arbitrum Sepolia USDC price feed added:", config.usdPriceFeed);
            IBeanHeads(adminFacet).addPriceFeed(helperConfig.OP_SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Optimism Sepolia USDC price feed added:", config.usdPriceFeed);
        } else if (block.chainid == helperConfig.OPTIMISM_SEPOLIA_CHAIN_ID()) {
            adminFacet = DevOpsTools.get_most_recent_deployment("BeanHeadsDiamond", block.chainid);
            IBeanHeads(adminFacet).setAllowedToken(config.linkToken, true);
            console.log("Link token allowed:", config.linkToken);
            IBeanHeads(adminFacet).setAllowedToken(helperConfig.OP_SEPOLIA_USDC(), true);
            console.log("Optimism Sepolia USDC allowed:", helperConfig.OP_SEPOLIA_USDC());
            IBeanHeads(adminFacet).setAllowedToken(helperConfig.SEPOLIA_USDC(), true);
            console.log("Sepolia USDC allowed:", helperConfig.SEPOLIA_USDC());
            IBeanHeads(adminFacet).setAllowedToken(helperConfig.ARBITRUM_SEPOLIA_USDC(), true);
            console.log("Arbitrum Sepolia USDC allowed:", helperConfig.ARBITRUM_SEPOLIA_USDC());
            IBeanHeads(adminFacet).addPriceFeed(helperConfig.SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Sepolia USDC price feed added:", config.usdPriceFeed);
            IBeanHeads(adminFacet).addPriceFeed(helperConfig.OP_SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Optimism Sepolia USDC price feed added:", config.usdPriceFeed);
            IBeanHeads(adminFacet).addPriceFeed(helperConfig.ARBITRUM_SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Arbitrum Sepolia USDC price feed added:", config.usdPriceFeed);
        } else if (block.chainid == helperConfig.ARBITRUM_SEPOLIA_CHAIN_ID()) {
            adminFacet = DevOpsTools.get_most_recent_deployment("BeanHeadsDiamond", block.chainid);
            IBeanHeads(adminFacet).setAllowedToken(config.linkToken, true);
            console.log("Link token allowed:", config.linkToken);
            IBeanHeads(adminFacet).setAllowedToken(helperConfig.ARBITRUM_SEPOLIA_USDC(), true);
            console.log("Arbitrum Sepolia USDC allowed:", helperConfig.ARBITRUM_SEPOLIA_USDC());
            IBeanHeads(adminFacet).setAllowedToken(helperConfig.SEPOLIA_USDC(), true);
            console.log("Sepolia USDC allowed:", helperConfig.SEPOLIA_USDC());
            IBeanHeads(adminFacet).setAllowedToken(helperConfig.OP_SEPOLIA_USDC(), true);
            console.log("Optimism Sepolia USDC allowed:", helperConfig.OP_SEPOLIA_USDC());
            IBeanHeads(adminFacet).addPriceFeed(helperConfig.SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Sepolia USDC price feed added:", config.usdPriceFeed);
            IBeanHeads(adminFacet).addPriceFeed(helperConfig.OP_SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Optimism Sepolia USDC price feed added:", config.usdPriceFeed);
            IBeanHeads(adminFacet).addPriceFeed(helperConfig.ARBITRUM_SEPOLIA_USDC(), config.usdPriceFeed);
            console.log("Arbitrum Sepolia USDC price feed added:", config.usdPriceFeed);
        }

        vm.stopBroadcast();
    }
}
