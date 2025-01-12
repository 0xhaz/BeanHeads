// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {BeanHeads} from "src/core/BeanHeads.sol";
import {Helpers} from "test/Helpers.sol";
import {Genesis} from "src/types/Genesis.sol";

contract BeanHeadsTest is Test, Helpers {
    BeanHeads beanHeads;

    Helpers helpers;

    address public USER = makeAddr("USER");
    address public USER2 = makeAddr("USER2");

    string public expectedTokenURI =
        "data:application/json;base64,eyJuYW1lIjogIkJlYW5IZWFkcyAjMSIsICJkZXNjcmlwdGlvbiI6ICJCZWFuSGVhZHMgaXMgYSBjdXN0b21pemFibGUgYXZhdGFyIG9uIGNoYWluIE5GVCBjb2xsZWN0aW9uIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjRiV3h1Y3owaWFIUjBjRG92TDNkM2R5NTNNeTV2Y21jdk1qQXdNQzl6ZG1jaUlIWnBaWGRDYjNnOUlqQWdNQ0ExTURBZ05UQXdJajQ4Y21WamRDQjNhV1IwYUQwaU5UQXdJaUJvWldsbmFIUTlJalV3TUNJZ1ptbHNiRDBpQXlJdlBqeDBaWGgwSUhnOUlqVXdKU0lnZVQwaU5UQWxJaUJrYjIxcGJtRnVkQzFpWVhObGJHbHVaVDBpYldsa1pHeGxJaUIwWlhoMExXRnVZMmh2Y2owaWJXbGtaR3hsSWlCbWIyNTBMWE5wZW1VOUlqSTBJajVDWldGdVNHVmhaSE1nUVhaaGRHRnlQQzkwWlhoMFBqd3ZjM1puUGc9PSIsICJhdHRyaWJ1dGVzIjpbeyJ0cmFpdF90eXBlIjogIkhhaXIgU3R5bGUiLCAidmFsdWUiOiAiQWZybyJ9LHsidHJhaXRfdHlwZSI6ICJIYWlyIENvbG9yIiwgInZhbHVlIjogIkJsb25kZSJ9LHsidHJhaXRfdHlwZSI6ICJBY2Nlc3NvcnkiLCAidmFsdWUiOiAiUm91bmQgR2xhc3NlcyJ9LHsidHJhaXRfdHlwZSI6ICJIYXQgU3R5bGUiLCAidmFsdWUiOiAiIn0seyJ0cmFpdF90eXBlIjogIkhhdCBDb2xvciIsICJ2YWx1ZSI6ICIzIn0seyJ0cmFpdF90eXBlIjogIkJvZHkgVHlwZSIsICJ2YWx1ZSI6ICJCcmVhc3QifSx7InRyYWl0X3R5cGUiOiAiU2tpbiBDb2xvciIsICJ2YWx1ZSI6ICJEYXJrIFNraW4ifSx7InRyYWl0X3R5cGUiOiAiQ2xvdGhlcyIsICJ2YWx1ZSI6ICJULVNoaXJ0In0seyJ0cmFpdF90eXBlIjogIkNsb3RoZXMgQ29sb3IiLCAidmFsdWUiOiAiV2hpdGUifSx7InRyYWl0X3R5cGUiOiAiQ2xvdGhlcyBHcmFwaGljIiwgInZhbHVlIjogIkdyYXBocWwifSx7InRyYWl0X3R5cGUiOiAiRXllYnJvdyBTaGFwZSIsICJ2YWx1ZSI6ICJOb3JtYWwifSx7InRyYWl0X3R5cGUiOiAiRXllIFNoYXBlIiwgInZhbHVlIjogIk5vcm1hbCJ9LHsidHJhaXRfdHlwZSI6ICJGYWNpYWwgSGFpciBUeXBlIiwgInZhbHVlIjogIlN0dWJibGUifSx7InRyYWl0X3R5cGUiOiAiTW91dGggU3R5bGUiLCAidmFsdWUiOiAiNiJ9LHsidHJhaXRfdHlwZSI6ICJMaXAgQ29sb3IiLCAidmFsdWUiOiAiMSJ9LHsidHJhaXRfdHlwZSI6ICJGYWNlIE1hc2siLCAidmFsdWUiOiAiZmFsc2UifSx7InRyYWl0X3R5cGUiOiAiRmFjZSBNYXNrIENvbG9yIiwgInZhbHVlIjogIjAifSx7InRyYWl0X3R5cGUiOiAiU2hhcGVzIiwgInZhbHVlIjogImZhbHNlIn0seyJ0cmFpdF90eXBlIjogIlNoYXBlIENvbG9yIiwgInZhbHVlIjogIjAifSx7InRyYWl0X3R5cGUiOiAiTGFzaGVzIiwgInZhbHVlIjogInRydWUifV19";

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
        // assertTrue(tokenId > beanHeads._sequentialUpTo());

        // Genesis.SVGParams memory svgParams = beanHeads.getAttributesByTokenId(tokenId);
        // string memory svgParamsStr = helpers.getParams(svgParams);

        // string memory expected = "01212352063003010falsefalsetrue";
        // assertEq(svgParamsStr, expected);
        assertEq(accessoryParams.accessoryId, 1);
        assertEq(bodyParams.bodyType, 1);
        assertEq(clothingParams.clothes, 3);
        assertEq(hairParams.hairStyle, 1);
        assertEq(clothingParams.clothesGraphic, 2);
        assertEq(facialFeaturesParams.eyebrowShape, 3);
        assertEq(facialFeaturesParams.eyeShape, 5);
        assertEq(facialFeaturesParams.facialHairType, 2);
        assertEq(accessoryParams.hatStyle, 1);
        assertEq(facialFeaturesParams.mouthStyle, 6);
        assertEq(bodyParams.skinColor, 3);
        assertEq(clothingParams.clothingColor, 0);
        assertEq(hairParams.hairColor, 0);
        assertEq(accessoryParams.hatColor, 3);
        assertEq(otherParams.shapeColor, 0);
        assertEq(facialFeaturesParams.lipColor, 1);
        assertEq(otherParams.faceMaskColor, 0);
        assertEq(otherParams.faceMask, false);
        assertEq(otherParams.shapes, false);
        assertEq(otherParams.lashes, true);

        vm.stopPrank();

        vm.prank(USER2);
        tokenId = beanHeads.mintGenesis(params);
        assertEq(tokenId, 2);
    }

    function test_tokenURI_ReturnsURI() public {
        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis(params);
        string memory uri = beanHeads.tokenURI(tokenId);
        console2.logString(uri);

        assertEq(uri, expectedTokenURI);
    }

    function test_getOwnerTokens_ReturnsTokens() public {
        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis(params);

        uint256[] memory tokens = beanHeads.getOwnerTokens(USER);
        // console2.logUint(tokenId);
        // console2.logUint(tokens[0]);

        assertEq(tokens.length, 1);
        assertEq(tokens[0], tokenId);
    }
}
