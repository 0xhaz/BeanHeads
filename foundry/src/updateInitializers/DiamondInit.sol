// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

//******************************************************************************\
//* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
//* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
//*
//* Implementation of a diamond.
/**
 *
 */
import {AggregatorV3Interface} from
    "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

import {BHStorage} from "src/libraries/BHStorage.sol";
import {IERC721Permit} from "src/interfaces/IERC721Permit.sol";
import {IDiamondCut} from "src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "src/interfaces/IDiamondLoupe.sol";
import {IERC165} from "src/interfaces/IERC165.sol";
import {IERC173} from "src/interfaces/IERC173.sol";
import {IERC721AUpgradeable} from "src/interfaces/IERC721AUpgradeable.sol";
import {ERC721AStorage} from "src/libraries/ERC721A/ERC721AStorage.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to

// Adding parameters to the `init` or other functions you add here can make a
// single deployed DiamondInit contract reusable across upgrades, and can be used for
// multiple diamonds

contract DiamondInit {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables

    function init(address _royalty, address _priceFeed) external {
        // add interface IDs to the storage
        BHStorage.BeanHeadsStorage storage ds = BHStorage.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC20Metadata).interfaceId] = true;
        ds.supportedInterfaces[type(IERC2981).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721AUpgradeable).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Receiver).interfaceId] = true;
        ds.supportedInterfaces[type(IERC1271).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Permit).interfaceId] = true;

        // Initialize ERC721A state variables
        ERC721AStorage.Layout storage erc721AStorage = ERC721AStorage.layout();
        erc721AStorage._name = "BeanHeads";
        erc721AStorage._symbol = "BEANS";

        // Initialize the BeanHeads storage
        ds.owner = msg.sender; // Set the contract owner
        ds.mintPriceUsd = 0.01 ether; // Set a default mint price, can be overridden in the deployment script
        ds.royaltyContract = _royalty;
        ds.priceFeed = AggregatorV3Interface(_priceFeed);

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
    }
}
