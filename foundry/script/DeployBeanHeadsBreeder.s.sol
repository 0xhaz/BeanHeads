// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BeanHeadsBreeder} from "src/vrf/BeanHeadsBreeder.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {BeanHeads} from "src/core/BeanHeads.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployBeanHeadsBreeder is Script {
    function run() public returns (BeanHeadsBreeder) {
        HelperConfig helperConfig = new HelperConfig();
        (,,, address vrfCoordinator, uint256 subscriptionId, bytes32 keyHash, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();

        DeployBeanHeads deployBeanHeads = new DeployBeanHeads();
        BeanHeads beanHeads = deployBeanHeads.run();

        vm.startBroadcast(deployerKey);
        BeanHeadsBreeder beanHeadsBreeder =
            new BeanHeadsBreeder(address(beanHeads), vrfCoordinator, subscriptionId, keyHash);
        // beanHeads.authorizeBreeder(address(beanHeadsBreeder));
        vm.stopBroadcast();

        return beanHeadsBreeder;
    }
}
