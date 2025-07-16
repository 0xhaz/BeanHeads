// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BeanHeadsBridge} from "src/bridge/BeanHeadsBridge.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {BeanHeads} from "src/core/BeanHeads.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployBeanHeadsBridge is Script {
    function run() public returns (address) {
        HelperConfig helperConfig = new HelperConfig();
        (address routerClient, address remoteBridge, address linkToken,,,, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();

        DeployBeanHeads deployBeanHeads = new DeployBeanHeads();
        (address beanHeads,) = deployBeanHeads.run();

        vm.startBroadcast(deployerKey);
        BeanHeadsBridge beanHeadsBridge =
            new BeanHeadsBridge(routerClient, remoteBridge, msg.sender, linkToken, beanHeads);
        vm.stopBroadcast();

        console.log("BeanHeadsBridge deployed at:", address(beanHeadsBridge));
        return address(beanHeadsBridge);
    }
}
