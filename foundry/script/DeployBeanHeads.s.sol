// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BeanHeadsDiamond} from "src/BeanHeadsDiamond.sol";
import {DiamondInit} from "src/updateInitializers/DiamondInit.sol";
import {DiamondCutFacet} from "src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "src/facets/DiamondLoupeFacet.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BeanHeadsRoyalty} from "src/core/BeanHeadsRoyalty.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployBeanHeads is Script {
    uint96 public ROYALTY_FEE_BPS = 500; // 5% royalty fee in basis points
    BeanHeadsRoyalty public royalty;
    BeanHeads public beanHeads;

    function run() public returns (address, address) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        address deployerAddress = vm.addr(config.deployerKey);
        console.log("Deployer address:", deployerAddress);
        console.log("Deployer balance:", deployerAddress.balance);
        address priceFeed = config.usdPriceFeed;

        vm.startBroadcast(config.deployerKey);
        royalty = new BeanHeadsRoyalty(deployerAddress, ROYALTY_FEE_BPS);
        BeanHeads implementation = new BeanHeads();

        bytes memory initData =
            abi.encodeWithSelector(BeanHeads.initialize.selector, deployerAddress, address(royalty), priceFeed);

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        vm.stopBroadcast();

        console.log("BeanHeads implementation deployed at:", address(implementation));
        console.log("BeanHeadsRoyalty deployed at:", address(royalty));
        console.log("BeanHeadsProxy deployed at:", address(proxy));

        return (address(proxy), address(royalty));
    }
}
