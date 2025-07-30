// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BeanHeadsBreeder} from "src/vrf/BeanHeadsBreeder.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract DeployBeanHeadsBreeder is Script {
    HelperConfig helperConfig = new HelperConfig();

    constructor(HelperConfig _helperConfig) {
        helperConfig = _helperConfig;
    }

    function run() public returns (address, address) {
        (,,,, address vrfCoordinator, uint256 subscriptionId, bytes32 keyHash, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        address deployerAddress = vm.addr(config.deployerKey);

        address beanHeads;

        if (block.chainid == helperConfig.LOCAL_CHAIN_ID()) {
            DeployBeanHeads deployBeanHeads = new DeployBeanHeads();
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
        BeanHeadsBreeder beanHeadsBreeder =
            new BeanHeadsBreeder(deployerAddress, beanHeads, vrfCoordinator, subscriptionId, keyHash);
        // beanHeads.authorizeBreeder(address(beanHeadsBreeder));
        vm.stopBroadcast();

        console.log("BeanHeadsBreeder deployed at:", address(beanHeadsBreeder));
        return (address(beanHeadsBreeder), beanHeads);
    }
}
