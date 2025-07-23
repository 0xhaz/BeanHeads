// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BeanHeadsBridge} from "src/bridge/BeanHeadsBridge.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {BeanHeads} from "src/core/BeanHeads.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract DeployBeanHeadsBridge is Script {
    HelperConfig helperConfig;

    constructor(HelperConfig _helperConfig) {
        helperConfig = _helperConfig;
    }

    function run() public returns (address, address) {
        (address routerClient, address remoteBridge, address linkToken,,,,, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();

        address beanHeads;
        address deployerAddress = vm.addr(deployerKey);

        if (block.chainid == helperConfig.LOCAL_CHAIN_ID()) {
            DeployBeanHeads deployBeanHeads = new DeployBeanHeads(helperConfig);
            (beanHeads,) = deployBeanHeads.run();
        } else if (block.chainid == helperConfig.ETH_SEPOLIA_CHAIN_ID()) {
            beanHeads = DevOpsTools.get_most_recent_deployment("BeanHeads", block.chainid);
        } else if (block.chainid == helperConfig.OPTIMISM_SEPOLIA_CHAIN_ID()) {
            beanHeads = DevOpsTools.get_most_recent_deployment("BeanHeads", block.chainid);
        } else if (block.chainid == helperConfig.ARBITRUM_SEPOLIA_CHAIN_ID()) {
            beanHeads = DevOpsTools.get_most_recent_deployment("BeanHeads", block.chainid);
        } else {
            revert("Unsupported network");
        }

        vm.startBroadcast(deployerKey);
        BeanHeadsBridge beanHeadsBridge =
            new BeanHeadsBridge(routerClient, remoteBridge, deployerAddress, linkToken, beanHeads);
        vm.stopBroadcast();

        console.log("BeanHeadsBridge deployed at:", address(beanHeadsBridge));
        return (address(beanHeadsBridge), beanHeads);
    }
}
