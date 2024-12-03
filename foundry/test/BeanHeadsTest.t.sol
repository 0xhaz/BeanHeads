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

        // Prepare grouped parameters
        Avatar.Core memory coreParams = Avatar.Core({accessory: accessory, bodyType: bodyType, skinColor: skinColor});

        Avatar.Appearance memory appearanceParams = Avatar.Appearance({
            eyebrowShape: eyebrowShape,
            eyeShape: eyeShape,
            mouthStyle: mouthStyle,
            facialHairType: facialHairType,
            hairStyle: hairStyle,
            hairColor: hairColor
        });

        Avatar.Clothing memory clothingParams = Avatar.Clothing({
            clothes: clothes,
            clothesGraphic: clothesGraphic,
            clothingColor: clothingColor,
            hatStyle: hatStyle,
            hatColor: hatColor
        });

        Avatar.Extras memory extrasParams = Avatar.Extras({
            circleColor: circleColor,
            lipColor: lipColor,
            faceMaskColor: faceMaskColor,
            faceMask: faceMask,
            lashes: lashes,
            mask: mask
        });

        // Call the buildAvatar function
        uint256 tokenId = beanHeads.buildAvatar(coreParams, appearanceParams, clothingParams, extrasParams);

        vm.stopPrank();

        // Validate Core attributes
        Avatar.Core memory body = beanHeads.getBodies(tokenId);
        assertEq(body.bodyType, bodyType);
        assertEq(body.skinColor, skinColor);
        assertEq(body.accessory, accessory);

        // Validate Appearance attributes
        Avatar.Appearance memory appearance = beanHeads.getEyes(tokenId); // Assuming Eyes encompasses all Appearance attributes
        assertEq(appearance.eyeShape, eyeShape);
        assertEq(appearance.eyebrowShape, eyebrowShape);
        assertEq(appearance.mouthStyle, mouthStyle);
        assertEq(appearance.facialHairType, facialHairType);
        assertEq(appearance.hairStyle, hairStyle);
        assertEq(appearance.hairColor, hairColor);

        // Validate Clothing attributes
        Avatar.Clothing memory avatarClothes = beanHeads.getClothes(tokenId);
        assertEq(avatarClothes.clothes, clothes);
        assertEq(avatarClothes.clothesGraphic, clothesGraphic);
        assertEq(avatarClothes.clothingColor, clothingColor);
        assertEq(avatarClothes.hatStyle, hatStyle);
        assertEq(avatarClothes.hatColor, hatColor);

        // Validate Extras attributes
        Avatar.Extras memory extras = beanHeads.getFaceMask(tokenId); // Assuming FaceMask encompasses all Extras attributes
        assertEq(extras.circleColor, circleColor);
        assertEq(extras.lipColor, lipColor);
        assertEq(extras.faceMaskColor, faceMaskColor);
        assertEq(extras.faceMask, faceMask);
        assertEq(extras.lashes, lashes);
        assertEq(extras.mask, mask);
    }

    function test_getAttributes() public {
        // Avatar.AllAttributes memory params = Avatar.AllAttributes({
        //     accessory: Avatar.Accessories({accessory: accessory, lashes: false, mask: true}),
        //     body: Avatar.Bodies({bodyType: bodyType, skinColor: skinColor}),
        //     clothes: Avatar.Clothes({clothes: clothes, clothesGraphic: clothesGraphic, clothingColor: clothingColor}),
        //     hat: Avatar.Hats({hatStyle: hatStyle, hatColor: hatColor}),
        //     eyes: Avatar.Eyes({eyeShape: eyeShape}),
        //     eyebrows: Avatar.Eyebrows({eyebrowShape: eyebrowShape}),
        //     mouth: Avatar.Mouths({mouthStyle: mouthStyle, lipColor: lipColor}),
        //     hair: Avatar.Hairs({hairStyle: hairStyle, hairColor: hairColor}),
        //     facialHair: Avatar.FacialHairs({facialHairType: facialHairType}),
        //     faceMask: Avatar.FaceMask({faceMaskColor: faceMaskColor, isOn: true}),
        //     shapes: Avatar.Shapes({circleColor: circleColor})
        // });
        // vm.startPrank(USER);

        // beanHeads.buildAvatar(params);

        // vm.expectEmit(true, true, false, false);
        // emit MintedGenesis(USER, 0);

        // vm.stopPrank();

        // Avatar.AllAttributes memory attributes = beanHeads.getAttributes(tokenId);
        // string memory formattedAttributes = beanHeads.formatAttributes(attributes);

        // assertEq(
        //     formattedAttributes,
        //     "0,1,3,2,1,4,1,0,0x123456,0x654321,0xaabbcc,0x112233,0x445566,0x998877,0x112233,true,false,true"
        // );
    }
}
