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

    modifier buildTokenId() {
        _;
    }

    function test_Name() public view {
        assertEq(beanHeads.name(), "BeanHeads");
    }

    function test_Symbol() public view {
        assertEq(beanHeads.symbol(), "BEAN");
    }

    function test_buildAvatar() public {
        vm.startPrank(USER);

        // Check emitted event
        vm.expectEmit(true, true, false, false);
        emit MintedGenesis(USER, 0);

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

        // Validate attributes
        Avatar.Bodies memory body = beanHeads.getBodies(tokenId);
        assertEq(body.bodyType, bodyType);
        assertEq(body.skinColor, skinColor);

        Avatar.Accessories memory avatarAccessory = beanHeads.getAccessories(tokenId);
        assertEq(avatarAccessory.accessory, accessory);
        assertEq(avatarAccessory.lashes, false);
        assertEq(avatarAccessory.mask, true);

        Avatar.Clothes memory avatarClothes = beanHeads.getClothes(tokenId);
        assertEq(avatarClothes.clothes, clothes);
        assertEq(avatarClothes.clothesGraphic, clothesGraphic);
        assertEq(avatarClothes.clothingColor, clothingColor);

        Avatar.Hats memory avatarHats = beanHeads.getHats(tokenId);
        assertEq(avatarHats.hatStyle, hatStyle);
        assertEq(avatarHats.hatColor, hatColor);

        Avatar.Eyes memory avatarEyes = beanHeads.getEyes(tokenId);
        assertEq(avatarEyes.eyeShape, eyeShape);

        Avatar.Eyebrows memory avatarEyebrows = beanHeads.getEyebrows(tokenId);
        assertEq(avatarEyebrows.eyebrowShape, eyebrowShape);

        Avatar.Mouths memory avatarMouths = beanHeads.getMouths(tokenId);
        assertEq(avatarMouths.mouthStyle, mouthStyle);
        assertEq(avatarMouths.lipColor, lipColor);

        Avatar.Hairs memory avatarHairs = beanHeads.getHairs(tokenId);
        assertEq(avatarHairs.hairStyle, hairStyle);
        assertEq(avatarHairs.hairColor, hairColor);

        Avatar.FacialHairs memory avatarFacialHairs = beanHeads.getFacialHairs(tokenId);
        assertEq(avatarFacialHairs.facialHairType, facialHairType);

        Avatar.FaceMask memory avatarFaceMask = beanHeads.getFaceMask(tokenId);
        assertEq(avatarFaceMask.faceMaskColor, faceMaskColor);
        assertEq(avatarFaceMask.isOn, true);

        Avatar.Shapes memory avatarShapes = beanHeads.getShapes(tokenId);
        assertEq(avatarShapes.circleColor, circleColor);
    }

    function test_getAttributes() public {
        vm.startPrank(USER);

        vm.expectEmit(true, true, false, false);
        emit MintedGenesis(USER, 0);

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

        Avatar.AllAttributes memory attributes = beanHeads.getAttributes(tokenId);
        string memory formattedAttributes = beanHeads.formatAttributes(attributes);

        assertEq(
            formattedAttributes,
            "0,1,3,2,1,4,1,0,0x123456,0x654321,0xaabbcc,0x112233,0x445566,0x998877,0x112233,true,false,true"
        );
    }
}
