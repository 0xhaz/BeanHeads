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
        "data:application/json;base64,eyJuYW1lIjogIkJlYW5IZWFkcyAjMSIsICJkZXNjcmlwdGlvbiI6ICJCZWFuSGVhZHMgaXMgYSBjdXN0b21pemFibGUgYXZhdGFyIG9uIGNoYWluIE5GVCBjb2xsZWN0aW9uIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjRiV3h1Y3owaWFIUjBjRG92TDNkM2R5NTNNeTV2Y21jdk1qQXdNQzl6ZG1jaUlIWnBaWGRDYjNnOUlqQWdNQ0ExTURBZ05UQXdJajQ4Y21WamRDQjNhV1IwYUQwaU5UQXdJaUJvWldsbmFIUTlJalV3TUNJZ1ptbHNiRDBpQXlJdlBqeDBaWGgwSUhnOUlqVXdKU0lnZVQwaU5UQWxJaUJrYjIxcGJtRnVkQzFpWVhObGJHbHVaVDBpYldsa1pHeGxJaUIwWlhoMExXRnVZMmh2Y2owaWJXbGtaR3hsSWlCbWIyNTBMWE5wZW1VOUlqSTBJajVDWldGdVNHVmhaSE1nUVhaaGRHRnlQQzkwWlhoMFBqd3ZjM1puUGc9PSIsICJhdHRyaWJ1dGVzIjpbeyJ0cmFpdF90eXBlIjogIkhhaXIgU3R5bGUiLCAidmFsdWUiOiAiQWZybyJ9LHsidHJhaXRfdHlwZSI6ICJIYWlyIENvbG9yIiwgInZhbHVlIjogIkJsb25kZSJ9LHsidHJhaXRfdHlwZSI6ICJBY2Nlc3NvcnkiLCAidmFsdWUiOiAiUm91bmQgR2xhc3NlcyJ9LHsidHJhaXRfdHlwZSI6ICJIYXQgU3R5bGUiLCAidmFsdWUiOiAiQmVhbmllIn0seyJ0cmFpdF90eXBlIjogIkhhdCBDb2xvciIsICJ2YWx1ZSI6ICJHcmVlbiJ9LHsidHJhaXRfdHlwZSI6ICJCb2R5IFR5cGUiLCAidmFsdWUiOiAiQnJlYXN0In0seyJ0cmFpdF90eXBlIjogIlNraW4gQ29sb3IiLCAidmFsdWUiOiAiRGFyayBTa2luIn0seyJ0cmFpdF90eXBlIjogIkNsb3RoZXMiLCAidmFsdWUiOiAiVC1TaGlydCJ9LHsidHJhaXRfdHlwZSI6ICJDbG90aGVzIENvbG9yIiwgInZhbHVlIjogIldoaXRlIn0seyJ0cmFpdF90eXBlIjogIkNsb3RoZXMgR3JhcGhpYyIsICJ2YWx1ZSI6ICJHcmFwaHFsIn0seyJ0cmFpdF90eXBlIjogIkV5ZWJyb3cgU2hhcGUiLCAidmFsdWUiOiAiTm9ybWFsIn0seyJ0cmFpdF90eXBlIjogIkV5ZSBTaGFwZSIsICJ2YWx1ZSI6ICJOb3JtYWwifSx7InRyYWl0X3R5cGUiOiAiRmFjaWFsIEhhaXIgVHlwZSIsICJ2YWx1ZSI6ICJTdHViYmxlIn0seyJ0cmFpdF90eXBlIjogIk1vdXRoIFN0eWxlIiwgInZhbHVlIjogIkxpcHMifSx7InRyYWl0X3R5cGUiOiAiTGlwIENvbG9yIiwgInZhbHVlIjogIlB1cnBsZSJ9LHsidHJhaXRfdHlwZSI6ICJFeWVicm93IFNoYXBlIiwgInZhbHVlIjogIk5vcm1hbCJ9LHsidHJhaXRfdHlwZSI6ICJFeWUgU2hhcGUiLCAidmFsdWUiOiAiTm9ybWFsIn0seyJ0cmFpdF90eXBlIjogIkZhY2lhbCBIYWlyIFR5cGUiLCAidmFsdWUiOiAiU3R1YmJsZSJ9LHsidHJhaXRfdHlwZSI6ICJNb3V0aCBTdHlsZSIsICJ2YWx1ZSI6ICJMaXBzIn0seyJ0cmFpdF90eXBlIjogIkxpcCBDb2xvciIsICJ2YWx1ZSI6ICJQdXJwbGUifSx7InRyYWl0X3R5cGUiOiAiTGFzaGVzIiwgInZhbHVlIjogInRydWUifV19";

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
        assertEq(facialFeaturesParams.mouthStyle, 1);
        assertEq(bodyParams.skinColor, 3);
        assertEq(clothingParams.clothingColor, 0);
        assertEq(hairParams.hairColor, 0);
        assertEq(accessoryParams.hatColor, 3);
        assertEq(otherParams.shapeColor, 1);
        assertEq(facialFeaturesParams.lipColor, 1);
        assertEq(otherParams.faceMaskColor, 3);
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
