// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Genesis} from "src/types/Genesis.sol";
import {Helpers} from "test/Helpers.sol";

contract GenesisTest is Test {
    /// Helper function to create a Genesis struct
    Helpers helpers;

    Genesis.SVGParams params;

    function setUp() public {
        helpers = new Helpers();
        (
            Genesis.HairParams memory hair,
            Genesis.BodyParams memory body,
            Genesis.ClothingParams memory clothing,
            Genesis.FacialFeaturesParams memory facialFeatures,
            Genesis.AccessoryParams memory accessory,
            Genesis.OtherParams memory other
        ) = helpers.params();
        params = Genesis.SVGParams(hair, body, clothing, facialFeatures, accessory, other);
    }

    function test_buildAvatar() public {
        string memory avatar = Genesis.buildAvatar(params);
        vm.writeFile("./output/genesis.svg", avatar);
        // console.log(avatar);
    }
}
