// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployBeanHeads} from "script/DeployBeanHeads.s.sol";
import {BeanHeads} from "src/core/BeanHeads.sol";
import {Images, ImagesLib, ImagesInBytes} from "src/types/Constants.sol";
import {Avatar} from "src/types/Avatar.sol";
import {Helpers} from "test/Helpers.sol";

contract BeanHeadsTest is Test, Helpers {
    using ImagesLib for *;
    using ImagesInBytes for *;
    using Images for *;

    event MintedGenesis(address indexed owner, uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 tokenId);

    DeployBeanHeads deployer;
    BeanHeads beanHeads;

    address USER = makeAddr("USER");

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

    function test_buildAvatar() public {
        vm.startPrank(USER);
        uint256 tokenId = beanHeads.buildAvatar(
            accessory,
            bodyType,
            clothes,
            eyebrowShape,
            eyeShape,
            mouthStyle,
            facialHairType,
            clothesGraphic,
            hairStyle,
            hatStyle,
            faceMaskColor,
            clothingColor,
            hairColor,
            hatColor,
            circleColor,
            lipColor,
            skinColor,
            faceMask,
            lashes,
            mask
        );
        vm.stopPrank();

        // Check emitted event
        // vm.expectEmit(true, true, true, true);
        // emit MintedGenesis(USER, tokenId);

        // Validate attributes
        Avatar.Bodies memory body = beanHeads.getBodies(tokenId);
        assertEq(body.bodyType, bodyType);
        assertEq(body.skinColor, skinColor);

        Avatar.Accessories memory avatarAccessory = beanHeads.getAccessories(tokenId);
        assertEq(avatarAccessory.accessory, accessory);
        assertEq(avatarAccessory.lashes, false);
        assertEq(avatarAccessory.mask, true);
    }
}
