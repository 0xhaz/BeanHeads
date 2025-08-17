// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BeanHeadsBridge} from "src/bridge/BeanHeadsBridge.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";

contract DeployBeanHeadsBridge is Script {
    function run() public returns (address, address, address) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        address beanHeads;

        if (block.chainid == helperConfig.LOCAL_CHAIN_ID()) {
            DeployBeanHeads deployBeanHeads = new DeployBeanHeads();
            (beanHeads,) = deployBeanHeads.run();
        } else if (block.chainid == helperConfig.ETH_SEPOLIA_CHAIN_ID()) {
            beanHeads = DevOpsTools.get_most_recent_deployment("BeanHeadsDiamond", block.chainid);
        } else if (block.chainid == helperConfig.OPTIMISM_SEPOLIA_CHAIN_ID()) {
            beanHeads = DevOpsTools.get_most_recent_deployment("BeanHeadsDiamond", block.chainid);
        } else if (block.chainid == helperConfig.ARBITRUM_SEPOLIA_CHAIN_ID()) {
            beanHeads = DevOpsTools.get_most_recent_deployment("BeanHeadsDiamond", block.chainid);
        } else {
            revert("Unsupported network");
        }

        address deployerAddress = vm.addr(config.deployerKey);
        console.log("Deployer address:", deployerAddress);

        vm.startBroadcast(config.deployerKey);

        BeanHeadsBridge beanHeadsBridge =
            new BeanHeadsBridge(config.routerClient, config.remoteBridge, deployerAddress, config.linkToken, beanHeads);

        vm.stopBroadcast();

        console.log("BeanHeadsBridge deployed at:", address(beanHeadsBridge));
        console.log("BeanHeads deployed at:", beanHeads);
        return (address(beanHeadsBridge), beanHeads, deployerAddress);
    }
}
