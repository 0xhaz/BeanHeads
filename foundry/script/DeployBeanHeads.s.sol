// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BeanHeads} from "src/core/BeanHeads.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {BeanHeadsRoyalty} from "src/core/BeanHeadsRoyalty.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployBeanHeads is Script {
    uint96 public ROYALTY_FEE_BPS = 500; // 5% royalty fee in basis points
    BeanHeadsRoyalty public royalty;
    BeanHeads public beanHeads;
    HelperConfig public helperConfig;

    constructor(HelperConfig _helperConfig) {
        helperConfig = _helperConfig;
    }

    function run() public returns (address, address) {
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        address deployerAddress = vm.addr(config.deployerKey);
        address priceFeed = config.usdPriceFeed;

        vm.startBroadcast(config.deployerKey);
        royalty = new BeanHeadsRoyalty(deployerAddress, ROYALTY_FEE_BPS);
        beanHeads = new BeanHeads(deployerAddress, address(royalty), priceFeed);
        vm.stopBroadcast();

        console.log("BeanHeads deployed at:", address(beanHeads));
        console.log("BeanHeadsRoyalty deployed at:", address(royalty));
        return (address(beanHeads), address(royalty));
    }
}
