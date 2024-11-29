// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {BeanHeads} from "src/core/BeanHeads.sol";

contract BeanHeadsTest is Test {
    DeployBeanHeads deployer;
    BeanHeads beanHeads;

    function setUp() public {
        deployer = new DeployBeanHeads();
        beanHeads = deployer.run();
    }

    function test_Name() public view {
        assertEq(beanHeads.name(), "BeanHeads");
    }

    function test_Symbol() public view {
        assertEq(beanHeads.symbol(), "BEAN");
    }
}
