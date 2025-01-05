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

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event MintedGenesis(address indexed owner, uint256 indexed tokenId);

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

        Genesis.SVGParams memory svgParams = beanHeads.getAttributesByTokenId(tokenId);
        string memory svgParamsStr = helpers.getParams(svgParams);

        string memory expected = "01212352063003010falsefalsetrue";
        assertEq(svgParamsStr, expected);
        assertEq(svgParams.accessory, 0);
        assertEq(svgParams.bodyType, 1);
        assertEq(svgParams.clothes, 2);
        assertEq(svgParams.hairStyle, 1);
        assertEq(svgParams.clothesGraphic, 2);
        assertEq(svgParams.eyebrowShape, 3);
        assertEq(svgParams.eyeShape, 5);
        assertEq(svgParams.facialHairType, 2);
        assertEq(svgParams.hatStyle, 0);
        assertEq(svgParams.mouthStyle, 6);
        assertEq(svgParams.skinColor, 3);
        assertEq(svgParams.clothingColor, 0);
        assertEq(svgParams.hairColor, 0);
        assertEq(svgParams.hatColor, 3);
        assertEq(svgParams.shapeColor, 0);
        assertEq(svgParams.lipColor, 1);
        assertEq(svgParams.faceMaskColor, 0);
        assertEq(svgParams.faceMask, false);
        assertEq(svgParams.shapes, false);
        assertEq(svgParams.lashes, true);

        vm.stopPrank();

        vm.prank(USER2);
        tokenId = beanHeads.mintGenesis(params);
        assertEq(tokenId, 2);
    }
}
