// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {BeanHeads} from "src/core/BeanHeads.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
// import {Images} from "src/types/Constants.sol";

contract DeployBeanHeads is Script {
    function run() public returns (BeanHeads) {
        vm.startBroadcast();
        BeanHeads beanHeads = new BeanHeads(msg.sender);
        vm.stopBroadcast();
        return beanHeads;
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));

        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }
}
