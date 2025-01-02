// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {BeanHeads} from "src/core/BeanHeads.sol";
import {Helpers} from "test/Helpers.sol";

contract BeanHeadsTest is Test, Helpers {
    BeanHeads beanHeads;

    Helpers helpers;

    function setUp() public {
        beanHeads = new BeanHeads();
        helpers = new Helpers();
    }

    function test_mintGenesis() public {
        uint256 tokenId = beanHeads.mintGenesis(params);
        console.log("tokenId: ", tokenId);
    }
}
