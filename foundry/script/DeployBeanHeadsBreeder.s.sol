// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BeanHeadsBreeder} from "src/vrf/BeanHeadsBreeder.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    IVRFCoordinatorV2Plus,
    IVRFSubscriptionV2Plus
} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFCoordinatorV2_5.sol";
import {IBeanHeads} from "src/interfaces/IBeanHeads.sol";

contract DeployBeanHeadsBreeder is Script {
    HelperConfig helperConfig = new HelperConfig();

    // constructor(HelperConfig _helperConfig) {
    //     helperConfig = _helperConfig;
    // }

    function run() public returns (address, address) {
        (
            ,
            ,
            ,
            ,
            address vrfCoordinator,
            uint256 subscriptionId,
            bytes32 keyHash,
            uint256 deployerKey,
            uint32 gasLimit,
            uint16 requestConfirmations,
            uint256 breedCoolDown,
            uint256 maxBreedRequests
        ) = helperConfig.activeNetworkConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

        address deployerAddress = vm.addr(config.deployerKey);

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

        vm.startBroadcast(deployerKey);
        BeanHeadsBreeder beanHeadsBreeder = new BeanHeadsBreeder(
            deployerAddress,
            beanHeads,
            gasLimit,
            requestConfirmations,
            breedCoolDown,
            maxBreedRequests,
            vrfCoordinator,
            subscriptionId,
            keyHash
        );

        vm.stopBroadcast();

        console.log("BeanHeadsBreeder deployed at:", address(beanHeadsBreeder));

        vm.startBroadcast(deployerKey);
        // beanHeadsBreeder.acceptOwnership();
        // console.log("BeanHeadsBreeder ownership accepted by:", address(beanHeadsBreeder));
        IBeanHeads(beanHeads).authorizeBreeder(address(beanHeadsBreeder));
        console.log("BeanHeadsBreeder authorized in BeanHeads at:", beanHeads);
        // addFundLink(config.linkToken, address(beanHeadsBreeder));
        // beanHeadsBreeder.addVrfConsumer(vrfCoordinator, uint64(subscriptionId), address(beanHeadsBreeder));
        vm.stopBroadcast();

        return (address(beanHeadsBreeder), beanHeads);
    }

    function addFundLink(address linkToken, address to) public {
        uint256 amount = 3 ether;
        (,,,,,,, uint256 deployerKey,,,,) = helperConfig.activeNetworkConfig();
        vm.startBroadcast(deployerKey);
        bool ok = IERC20(linkToken).transfer(to, amount);
        vm.stopBroadcast();
        require(ok, "Transfer failed");
        console.log("Funded LINK to:", to, "with amount:", amount);
    }

    function addVrfConsumer(address vrfCoordinator, uint64 subId, address consumer) public {
        (,,,,,,, uint256 deployerKey,,,,) = helperConfig.activeNetworkConfig();
        vm.startBroadcast(deployerKey);
        // Create a new subscription
        IVRFCoordinatorV2Plus vrfCoord = IVRFCoordinatorV2Plus(vrfCoordinator);
        vrfCoord.addConsumer(subId, consumer);
        console.log("Added consumer:", consumer, "to subscription:", subId);
        vm.stopBroadcast();
    }
}
