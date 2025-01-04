// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {BeanHeads} from "src/core/BeanHeads.sol";
import {Helpers} from "test/Helpers.sol";
import {Genesis} from "src/types/Genesis.sol";

contract BeanHeadsTest is Test, Helpers {
    BeanHeads beanHeads;

    Helpers helpers;

    address public USER = makeAddr("USER");
    address public USER2 = makeAddr("USER2");

    function setUp() public {
        beanHeads = new BeanHeads();
        helpers = new Helpers();
    }

    function test_InitialSetup() public view {
        string memory name = beanHeads.name();
        string memory symbol = beanHeads.symbol();

        assertEq(name, "BeanHeads");
        assertEq(symbol, "BEAN");
    }

    function test_mintGenesis_ReturnSVGParams() public {
        vm.startPrank(USER);
        uint256 tokenId = beanHeads.mintGenesis(params);
        assertEq(tokenId, 1);

        Genesis.SVGParams memory svgParams = beanHeads.getAttributesByTokenId(1);
        string memory svgParamsStr = helpers.getParams(svgParams);
        console.log(svgParamsStr);

        vm.prank(USER2);
        tokenId = beanHeads.mintGenesis(params);
        assertEq(tokenId, 2);
    }
}
