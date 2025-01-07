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

    string public expectedTokenURI =
        "data:application/json;base64,eyJuYW1lIjogIkJlYW5IZWFkcyAjMSIsICJkZXNjcmlwdGlvbiI6ICJCZWFuSGVhZHMgaXMgYSBjdXN0b21pemFibGUgYXZhdGFyIG9uIGNoYWluIE5GVCBjb2xsZWN0aW9uIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjRiV3h1Y3owaWFIUjBjRG92TDNkM2R5NTNNeTV2Y21jdk1qQXdNQzl6ZG1jaUlIWnBaWGRDYjNnOUlqQWdNQ0ExTURBZ05UQXdJajQ4Y21WamRDQjNhV1IwYUQwaU5UQXdJaUJvWldsbmFIUTlJalV3TUNJZ1ptbHNiRDBpQXlJdlBqeDBaWGgwSUhnOUlqVXdKU0lnZVQwaU5UQWxJaUJrYjIxcGJtRnVkQzFpWVhObGJHbHVaVDBpYldsa1pHeGxJaUIwWlhoMExXRnVZMmh2Y2owaWJXbGtaR3hsSWlCbWIyNTBMWE5wZW1VOUlqSTBJajVDWldGdVNHVmhaSE1nUVhaaGRHRnlQQzkwWlhoMFBqd3ZjM1puUGc9PSIsICJhdHRyaWJ1dGVzIjpbeyJ0cmFpdF90eXBlIjogIkFjY2Vzc29yeSIsICJ2YWx1ZSI6ICIwIn0seyJ0cmFpdF90eXBlIjogIkJvZHkgVHlwZSIsICJ2YWx1ZSI6ICIxIn0seyJ0cmFpdF90eXBlIjogIkNsb3RoZXMiLCAidmFsdWUiOiAiMiJ9LHsidHJhaXRfdHlwZSI6ICJIYWlyIFN0eWxlIiwgInZhbHVlIjogIjEifSx7InRyYWl0X3R5cGUiOiAiQ2xvdGhlcyBHcmFwaGljIiwgInZhbHVlIjogIjIifSx7InRyYWl0X3R5cGUiOiAiRXllYnJvdyBTaGFwZSIsICJ2YWx1ZSI6ICIzIn0seyJ0cmFpdF90eXBlIjogIkV5ZSBTaGFwZSIsICJ2YWx1ZSI6ICI1In0seyJ0cmFpdF90eXBlIjogIkZhY2lhbCBIYWlyIFR5cGUiLCAidmFsdWUiOiAiMiJ9LHsidHJhaXRfdHlwZSI6ICJIYXQgU3R5bGUiLCAidmFsdWUiOiAiMCJ9LHsidHJhaXRfdHlwZSI6ICJNb3V0aCBTdHlsZSIsICJ2YWx1ZSI6ICI2In0seyJ0cmFpdF90eXBlIjogIlNraW4gQ29sb3IiLCAidmFsdWUiOiAiMyJ9LHsidHJhaXRfdHlwZSI6ICJDbG90aGluZyBDb2xvciIsICJ2YWx1ZSI6ICIwIn0seyJ0cmFpdF90eXBlIjogIkhhaXIgQ29sb3IiLCAidmFsdWUiOiAiMCJ9LHsidHJhaXRfdHlwZSI6ICJIYXQgQ29sb3IiLCAidmFsdWUiOiAiMyJ9LHsidHJhaXRfdHlwZSI6ICJTaGFwZSBDb2xvciIsICJ2YWx1ZSI6ICIwIn0seyJ0cmFpdF90eXBlIjogIkxpcCBDb2xvciIsICJ2YWx1ZSI6ICIxIn0seyJ0cmFpdF90eXBlIjogIkZhY2UgTWFzayBDb2xvciIsICJ2YWx1ZSI6ICIwIn0seyJ0cmFpdF90eXBlIjogIkZhY2UgTWFzayIsICJ2YWx1ZSI6ICJmYWxzZSJ9LHsidHJhaXRfdHlwZSI6ICJTaGFwZXMiLCAidmFsdWUiOiAiZmFsc2UifSx7InRyYWl0X3R5cGUiOiAiTGFzaGVzIiwgInZhbHVlIjogInRydWUifV19";

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

    function test_tokenURI_ReturnsURI() public {
        vm.prank(USER);
        uint256 tokenId = beanHeads.mintGenesis(params);
        string memory uri = beanHeads.tokenURI(tokenId);

        assertEq(uri, expectedTokenURI);
    }
}
