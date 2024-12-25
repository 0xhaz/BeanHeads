// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {AccessoryDetail} from "src/libraries/baseModel/AccessoryDetail.sol";
import {BodyDetail} from "src/libraries/baseModel/BodyDetail.sol";
import {ClothingDetail} from "src/libraries/baseModel/ClothingDetail.sol";
import {ClothingGraphicDetail} from "src/libraries/baseModel/ClothingGraphicDetail.sol";
import {EyebrowDetail} from "src/libraries/baseModel/EyebrowDetail.sol";
import {EyesDetail} from "src/libraries/baseModel/EyesDetail.sol";
import {FacialHairDetail} from "src/libraries/baseModel/FacialHairDetail.sol";
import {HairDetail} from "src/libraries/baseModel/HairDetail.sol";
import {HatsDetail} from "src/libraries/baseModel/HatsDetail.sol";
import {MouthDetail} from "src/libraries/baseModel/MouthDetail.sol";
import {OptItems} from "src/libraries/baseModel/OptItems.sol";

contract SVGTest is Test {
    function testSVGOutput() public {
        /*//////////////////////////////////////////////////////////////
                             ACCESSORY TEST
        //////////////////////////////////////////////////////////////*/

        string memory tinyGlassesSVG = AccessoryDetail.tinyGlassesSVG();
        // Write to local file
        vm.writeFile("./output/tiny_glasses.svg", tinyGlassesSVG);

        string memory roundGlassesSVG = AccessoryDetail.roundGlassesSVG();
        vm.writeFile("./output/round_glasses.svg", roundGlassesSVG);

        string memory shadesSVG = AccessoryDetail.shadesSVG();
        vm.writeFile("./output/shades.svg", shadesSVG);

        /*//////////////////////////////////////////////////////////////
                             BODY TEST
        //////////////////////////////////////////////////////////////*/

        string memory breastSVG = BodyDetail.breastSVGWithBody(0);
        // console.log(breastSVG);
        vm.writeFile("./output/breast.svg", breastSVG);

        string memory onlyBreastSVG = BodyDetail.onlyBreastSVG(1);
        // console.log(onlyBreastSVG);
        vm.writeFile("./output/only_breast.svg", onlyBreastSVG);

        string memory breastWhite = BodyDetail.getBodyById(1, 0);
        vm.writeFile("./output/breast_white.svg", breastWhite);

        string memory breastBlue = BodyDetail.getBodyById(1, 1);
        vm.writeFile("./output/breast_blue.svg", breastBlue);

        string memory breastBlack = BodyDetail.getBodyById(1, 2);
        vm.writeFile("./output/breast_black.svg", breastBlack);

        string memory breastGreen = BodyDetail.getBodyById(1, 3);
        vm.writeFile("./output/breast_green.svg", breastGreen);

        string memory breastRed = BodyDetail.getBodyById(1, 4);
        vm.writeFile("./output/breast_red.svg", breastRed);

        string memory chestSVG = BodyDetail.chestSVG(0);
        // console.log(chestSVG);
        vm.writeFile("./output/chest.svg", chestSVG);

        // Test by Id
        string memory bodyLightSkin = BodyDetail.getBodyById(2, 0);
        vm.writeFile("./output/body_test_light.svg", bodyLightSkin);

        string memory bodyYellowSkin = BodyDetail.getBodyById(2, 1);
        vm.writeFile("./output/body_test_yellow.svg", bodyYellowSkin);

        string memory bodyBrownSkin = BodyDetail.getBodyById(2, 2);
        vm.writeFile("./output/body_test_brown.svg", bodyBrownSkin);

        string memory bodyDarkSkin = BodyDetail.getBodyById(2, 3);
        vm.writeFile("./output/body_test_dark.svg", bodyDarkSkin);

        string memory bodyRedSkin = BodyDetail.getBodyById(2, 4);
        vm.writeFile("./output/body_test_red.svg", bodyRedSkin);

        string memory bodyBlackSkin = BodyDetail.getBodyById(2, 5);
        vm.writeFile("./output/body_test_black.svg", bodyBlackSkin);

        /*//////////////////////////////////////////////////////////////
                             CLOTHING TEST
        //////////////////////////////////////////////////////////////*/

        string memory dressSVG = ClothingDetail.dressSVG(1, 1);
        // console.log(dressSVG);
        vm.writeFile("./output/dress.svg", dressSVG);

        string memory shirtSVG = ClothingDetail.shirtSVG(1, 1);
        // console.log(shirtSVG);
        vm.writeFile("./output/shirt.svg", shirtSVG);

        string memory tShirtSVG = ClothingDetail.tShirtSVG(1, 0);
        vm.writeFile("./output/t_shirt.svg", tShirtSVG);

        string memory tankTopSVG = ClothingDetail.tankTopSVG(1, 0);
        vm.writeFile("./output/tank_top.svg", tankTopSVG);

        string memory vNeckSVG = ClothingDetail.vNeckSVG(0);
        vm.writeFile("./output/v_neck.svg", vNeckSVG);

        // Test by using function
        string memory whiteDress = ClothingDetail.getClothingById(1, 1, 0);
        vm.writeFile("./output/white_dress.svg", whiteDress);

        string memory blueDress = ClothingDetail.getClothingById(1, 1, 1);
        vm.writeFile("./output/blue_dress.svg", blueDress);

        string memory blackDress = ClothingDetail.getClothingById(1, 1, 2);
        vm.writeFile("./output/black_dress.svg", blackDress);

        string memory greenDress = ClothingDetail.getClothingById(1, 1, 3);
        vm.writeFile("./output/green_dress.svg", greenDress);

        string memory redDress = ClothingDetail.getClothingById(1, 1, 4);
        vm.writeFile("./output/red_dress.svg", redDress);

        string memory shirtWhite = ClothingDetail.getClothingById(2, 1, 0);
        vm.writeFile("./output/white_shirt.svg", shirtWhite);

        string memory shirtBlue = ClothingDetail.getClothingById(2, 1, 1);
        vm.writeFile("./output/blue_shirt.svg", shirtBlue);

        string memory shirtBlack = ClothingDetail.getClothingById(2, 1, 2);
        vm.writeFile("./output/black_shirt.svg", shirtBlack);

        string memory shirtGreen = ClothingDetail.getClothingById(2, 1, 3);
        vm.writeFile("./output/green_shirt.svg", shirtGreen);

        string memory shirtRed = ClothingDetail.getClothingById(2, 2, 4);
        vm.writeFile("./output/red_shirt.svg", shirtRed);

        string memory tShirtWhite = ClothingDetail.getClothingById(3, 1, 0);
        vm.writeFile("./output/white_t_shirt.svg", tShirtWhite);

        string memory tShirtBlue = ClothingDetail.getClothingById(3, 1, 1);
        vm.writeFile("./output/blue_t_shirt.svg", tShirtBlue);

        string memory tShirtBlack = ClothingDetail.getClothingById(1, 3, 2);
        vm.writeFile("./output/black_t_shirt.svg", tShirtBlack);

        string memory tShirtGreen = ClothingDetail.getClothingById(1, 3, 3);
        vm.writeFile("./output/green_t_shirt.svg", tShirtGreen);

        string memory tShirtRed = ClothingDetail.getClothingById(1, 3, 4);
        vm.writeFile("./output/red_t_shirt.svg", tShirtRed);

        string memory tankTopWhite = ClothingDetail.getClothingById(1, 4, 0);
        vm.writeFile("./output/white_tank_top.svg", tankTopWhite);

        string memory tankTopBlue = ClothingDetail.getClothingById(1, 4, 1);
        vm.writeFile("./output/blue_tank_top.svg", tankTopBlue);

        string memory tankTopBlack = ClothingDetail.getClothingById(1, 4, 2);
        vm.writeFile("./output/black_tank_top.svg", tankTopBlack);

        string memory tankTopGreen = ClothingDetail.getClothingById(1, 4, 3);
        vm.writeFile("./output/green_tank_top.svg", tankTopGreen);

        string memory tankTopRed = ClothingDetail.getClothingById(1, 4, 4);
        vm.writeFile("./output/red_tank_top.svg", tankTopRed);

        string memory vNeckWhite = ClothingDetail.getClothingById(1, 5, 0);
        vm.writeFile("./output/white_v_neck.svg", vNeckWhite);

        string memory vNeckBlue = ClothingDetail.getClothingById(1, 5, 1);
        vm.writeFile("./output/blue_v_neck.svg", vNeckBlue);

        string memory vNeckBlack = ClothingDetail.getClothingById(1, 5, 2);
        vm.writeFile("./output/black_v_neck.svg", vNeckBlack);

        string memory vNeckGreen = ClothingDetail.getClothingById(1, 5, 3);
        vm.writeFile("./output/green_v_neck.svg", vNeckGreen);

        string memory vNeckRed = ClothingDetail.getClothingById(1, 5, 4);
        vm.writeFile("./output/red_v_neck.svg", vNeckRed);

        /*//////////////////////////////////////////////////////////////
                             CLOTHING GRAPPHIC TEST
        //////////////////////////////////////////////////////////////*/

        string memory gatsbySVG = ClothingGraphicDetail.gatsbySVG();
        vm.writeFile("./output/gatsby.svg", gatsbySVG);

        string memory graphqlSVG = ClothingGraphicDetail.graphqlSVG();
        vm.writeFile("./output/graphql.svg", graphqlSVG);

        string memory reactSVG = ClothingGraphicDetail.reactSVG();
        vm.writeFile("./output/react.svg", reactSVG);

        string memory redwoodSVG = ClothingGraphicDetail.redwoodSVG();
        vm.writeFile("./output/redwood.svg", redwoodSVG);

        string memory vueSVG = ClothingGraphicDetail.vueSVG();
        vm.writeFile("./output/vue.svg", vueSVG);

        /*//////////////////////////////////////////////////////////////
                             EYEBROW TEST
        //////////////////////////////////////////////////////////////*/

        string memory angryEyebrowSVG = EyebrowDetail.angryEyebrowSVG();
        vm.writeFile("./output/angry_eyebrow.svg", angryEyebrowSVG);

        string memory concernedEyebrowSVG = EyebrowDetail.concernedEyebrowSVG();
        vm.writeFile("./output/concerned_eyebrow.svg", concernedEyebrowSVG);

        string memory leftLoweredEyebrowSVG = EyebrowDetail.leftLoweredEyebrowSVG();
        vm.writeFile("./output/left_lowered_eyebrow.svg", leftLoweredEyebrowSVG);

        string memory normalEyebrowSVG = EyebrowDetail.normalEyebrowSVG();
        vm.writeFile("./output/normal_eyebrow.svg", normalEyebrowSVG);

        string memory seriousEyebrowSVG = EyebrowDetail.seriousEyebrowSVG();
        vm.writeFile("./output/serious_eyebrow.svg", seriousEyebrowSVG);

        /*//////////////////////////////////////////////////////////////
                             EYE TEST
        //////////////////////////////////////////////////////////////*/

        string memory contentEyeSVG = EyesDetail.contentEyeSVG();
        vm.writeFile("./output/content_eye.svg", contentEyeSVG);

        string memory dizzyEyeSVG = EyesDetail.dizzyEyeSVG();
        vm.writeFile("./output/dizzy_eye.svg", dizzyEyeSVG);

        string memory happyEyeSVG = EyesDetail.happyEyeSVG();
        vm.writeFile("./output/happy_eye.svg", happyEyeSVG);

        string memory heartEyeSVG = EyesDetail.heartEyeSVG();
        vm.writeFile("./output/heart_eye.svg", heartEyeSVG);

        string memory leftTwitchEyeSVG = EyesDetail.leftTwitchEyeSVG();
        vm.writeFile("./output/left_twitch_eye.svg", leftTwitchEyeSVG);

        string memory normalEye = EyesDetail.normalEyeSVG();
        // console.log(normalEye);
        vm.writeFile("./output/normal_eye.svg", normalEye);

        string memory simpleEyeSVG = EyesDetail.simpleEyeSVG();
        vm.writeFile("./output/simple_eye.svg", simpleEyeSVG);

        string memory squintEyeSVG = EyesDetail.squintEyeSVG();
        vm.writeFile("./output/squint_eye.svg", squintEyeSVG);

        string memory winkEyeSVG = EyesDetail.winkEyeSVG();
        vm.writeFile("./output/wink_eye.svg", winkEyeSVG);

        /*//////////////////////////////////////////////////////////////
                             FACIAL HAIR TEST
        //////////////////////////////////////////////////////////////*/

        string memory mediumBeardSVG = FacialHairDetail.mediumBeardSVG();
        vm.writeFile("./output/medium_beard.svg", mediumBeardSVG);

        string memory stubbleSVG = FacialHairDetail.stubbleSVG();
        vm.writeFile("./output/stubble.svg", stubbleSVG);

        /// Test by using function
        string memory mediumBeard = FacialHairDetail.getFacialHairById(1);
        vm.writeFile("./output/medium_beard.svg", mediumBeard);

        string memory stubble = FacialHairDetail.getFacialHairById(2);
        vm.writeFile("./output/stubble.svg", stubble);

        /*//////////////////////////////////////////////////////////////
                             HAIR TEST
        //////////////////////////////////////////////////////////////*/

        string memory afroHairSVG = HairDetail.afroHairSVG(0);
        vm.writeFile("./output/afro_hair.svg", afroHairSVG);

        string memory baldHairSVG = HairDetail.baldHairSVG(0);
        vm.writeFile("./output/bald_hair.svg", baldHairSVG);

        string memory bobCutSVG = HairDetail.bobCutSVG(0);
        vm.writeFile("./output/bob_cut.svg", bobCutSVG);

        string memory bunHairSVG = HairDetail.bunHairSVG(0);
        vm.writeFile("./output/bun_hair.svg", bunHairSVG);

        string memory longHairSVG = HairDetail.longHairSVG(0);
        vm.writeFile("./output/long_hair.svg", longHairSVG);

        string memory pixieCutSVG = HairDetail.pixieCutSVG(0);
        vm.writeFile("./output/pixie_cut.svg", pixieCutSVG);

        string memory shortHairSVG = HairDetail.shortHairSVG(0);
        vm.writeFile("./output/short_hair.svg", shortHairSVG);

        // Test by using function
        string memory afroBlonde = HairDetail.getHairById(1, 0);
        vm.writeFile("./output/afro_blonde.svg", afroBlonde);

        string memory afroOrange = HairDetail.getHairById(1, 1);
        vm.writeFile("./output/afro_orange.svg", afroOrange);

        string memory afroBlack = HairDetail.getHairById(1, 2);
        vm.writeFile("./output/afro_black.svg", afroBlack);

        string memory afroWhite = HairDetail.getHairById(1, 3);
        vm.writeFile("./output/afro_white.svg", afroWhite);

        string memory afroBrown = HairDetail.getHairById(1, 4);
        vm.writeFile("./output/afro_brown.svg", afroBrown);

        string memory afroBlue = HairDetail.getHairById(1, 5);
        vm.writeFile("./output/afro_blue.svg", afroBlue);

        string memory afroPink = HairDetail.getHairById(1, 6);
        vm.writeFile("./output/afro_pink.svg", afroPink);

        string memory baldBlonde = HairDetail.getHairById(2, 0);
        vm.writeFile("./output/bald_blonde.svg", baldBlonde);

        string memory baldOrange = HairDetail.getHairById(2, 1);
        vm.writeFile("./output/bald_orange.svg", baldOrange);

        string memory baldBlack = HairDetail.getHairById(2, 2);
        vm.writeFile("./output/bald_black.svg", baldBlack);

        string memory baldWhite = HairDetail.getHairById(2, 3);
        vm.writeFile("./output/bald_white.svg", baldWhite);

        string memory baldBrown = HairDetail.getHairById(2, 4);
        vm.writeFile("./output/bald_brown.svg", baldBrown);

        string memory baldBlue = HairDetail.getHairById(2, 5);
        vm.writeFile("./output/bald_blue.svg", baldBlue);

        string memory baldPink = HairDetail.getHairById(2, 6);
        vm.writeFile("./output/bald_pink.svg", baldPink);

        string memory bobBlonde = HairDetail.getHairById(3, 0);
        vm.writeFile("./output/bob_blonde.svg", bobBlonde);

        string memory bobOrange = HairDetail.getHairById(3, 1);
        vm.writeFile("./output/bob_orange.svg", bobOrange);

        string memory bobBlack = HairDetail.getHairById(3, 2);
        vm.writeFile("./output/bob_black.svg", bobBlack);

        string memory bobWhite = HairDetail.getHairById(3, 3);
        vm.writeFile("./output/bob_white.svg", bobWhite);

        string memory bobBrown = HairDetail.getHairById(3, 4);
        vm.writeFile("./output/bob_brown.svg", bobBrown);

        string memory bobBlue = HairDetail.getHairById(3, 5);
        vm.writeFile("./output/bob_blue.svg", bobBlue);

        string memory bobPink = HairDetail.getHairById(3, 6);
        vm.writeFile("./output/bob_pink.svg", bobPink);

        string memory bunBlonde = HairDetail.getHairById(4, 0);
        vm.writeFile("./output/bun_blonde.svg", bunBlonde);

        string memory bunOrange = HairDetail.getHairById(4, 1);
        vm.writeFile("./output/bun_orange.svg", bunOrange);

        string memory bunBlack = HairDetail.getHairById(4, 2);
        vm.writeFile("./output/bun_black.svg", bunBlack);

        string memory bunWhite = HairDetail.getHairById(4, 3);
        vm.writeFile("./output/bun_white.svg", bunWhite);

        string memory bunBrown = HairDetail.getHairById(4, 4);
        vm.writeFile("./output/bun_brown.svg", bunBrown);

        string memory bunBlue = HairDetail.getHairById(4, 5);
        vm.writeFile("./output/bun_blue.svg", bunBlue);

        string memory bunPink = HairDetail.getHairById(4, 6);
        vm.writeFile("./output/bun_pink.svg", bunPink);

        string memory longBlonde = HairDetail.getHairById(5, 0);
        vm.writeFile("./output/long_blonde.svg", longBlonde);

        string memory longOrange = HairDetail.getHairById(5, 1);
        vm.writeFile("./output/long_orange.svg", longOrange);

        string memory longBlack = HairDetail.getHairById(5, 2);
        vm.writeFile("./output/long_black.svg", longBlack);

        string memory longWhite = HairDetail.getHairById(5, 3);
        vm.writeFile("./output/long_white.svg", longWhite);

        string memory longBrown = HairDetail.getHairById(5, 4);
        vm.writeFile("./output/long_brown.svg", longBrown);

        string memory longBlue = HairDetail.getHairById(5, 5);
        vm.writeFile("./output/long_blue.svg", longBlue);

        string memory longPink = HairDetail.getHairById(5, 6);
        vm.writeFile("./output/long_pink.svg", longPink);

        string memory pixieBlonde = HairDetail.getHairById(6, 0);
        vm.writeFile("./output/pixie_blonde.svg", pixieBlonde);

        string memory pixieOrange = HairDetail.getHairById(6, 1);
        vm.writeFile("./output/pixie_orange.svg", pixieOrange);

        string memory pixieBlack = HairDetail.getHairById(6, 2);
        vm.writeFile("./output/pixie_black.svg", pixieBlack);

        string memory pixieWhite = HairDetail.getHairById(6, 3);
        vm.writeFile("./output/pixie_white.svg", pixieWhite);

        string memory pixieBrown = HairDetail.getHairById(6, 4);
        vm.writeFile("./output/pixie_brown.svg", pixieBrown);

        string memory pixieBlue = HairDetail.getHairById(6, 5);
        vm.writeFile("./output/pixie_blue.svg", pixieBlue);

        string memory pixiePink = HairDetail.getHairById(6, 6);
        vm.writeFile("./output/pixie_pink.svg", pixiePink);

        string memory shortBlonde = HairDetail.getHairById(7, 0);
        vm.writeFile("./output/short_blonde.svg", shortBlonde);

        string memory shortOrange = HairDetail.getHairById(7, 1);
        vm.writeFile("./output/short_orange.svg", shortOrange);

        string memory shortBlack = HairDetail.getHairById(7, 2);
        vm.writeFile("./output/short_black.svg", shortBlack);

        string memory shortWhite = HairDetail.getHairById(7, 3);
        vm.writeFile("./output/short_white.svg", shortWhite);

        string memory shortBrown = HairDetail.getHairById(7, 4);
        vm.writeFile("./output/short_brown.svg", shortBrown);

        string memory shortBlue = HairDetail.getHairById(7, 5);
        vm.writeFile("./output/short_blue.svg", shortBlue);

        string memory shortPink = HairDetail.getHairById(7, 6);
        vm.writeFile("./output/short_pink.svg", shortPink);

        /*//////////////////////////////////////////////////////////////
                             HAT TEST
        //////////////////////////////////////////////////////////////*/

        string memory beanieSVG = HatsDetail.beanieHatSVG(0);
        vm.writeFile("./output/beanie_hat.svg", beanieSVG);

        string memory turbanHatSVG = HatsDetail.turbanHatSVG(0);
        vm.writeFile("./output/turban_hat.svg", turbanHatSVG);

        /// test by using function
        string memory beanieWhite = HatsDetail.getHatsById(1, 0);
        vm.writeFile("./output/beanie_white.svg", beanieWhite);

        string memory beanieBlue = HatsDetail.getHatsById(1, 1);
        vm.writeFile("./output/beanie_blue.svg", beanieBlue);

        string memory beanieBlack = HatsDetail.getHatsById(1, 2);
        vm.writeFile("./output/beanie_black.svg", beanieBlack);

        string memory beanieGreen = HatsDetail.getHatsById(1, 3);
        vm.writeFile("./output/beanie_green.svg", beanieGreen);

        string memory beanieRed = HatsDetail.getHatsById(1, 4);
        vm.writeFile("./output/beanie_red.svg", beanieRed);

        string memory turbanWhite = HatsDetail.getHatsById(2, 0);
        vm.writeFile("./output/turban_white.svg", turbanWhite);

        string memory turbanBlue = HatsDetail.getHatsById(2, 1);
        vm.writeFile("./output/turban_blue.svg", turbanBlue);

        string memory turbanBlack = HatsDetail.getHatsById(2, 2);
        vm.writeFile("./output/turban_black.svg", turbanBlack);

        string memory turbanGreen = HatsDetail.getHatsById(2, 3);
        vm.writeFile("./output/turban_green.svg", turbanGreen);

        string memory turbanRed = HatsDetail.getHatsById(2, 4);
        vm.writeFile("./output/turban_red.svg", turbanRed);

        /*//////////////////////////////////////////////////////////////
                             MOUTH TEST
        //////////////////////////////////////////////////////////////*/
        string memory grinMouthSVG = MouthDetail.grinMouthSVG();
        vm.writeFile("./output/grin_mouth.svg", grinMouthSVG);

        string memory lipsMouthSVG = MouthDetail.lipsMouthSVG(0);
        vm.writeFile("./output/lips_mouth.svg", lipsMouthSVG);

        string memory openMouthSVG = MouthDetail.openMouthSVG();
        vm.writeFile("./output/open_mouth.svg", openMouthSVG);

        string memory openSmileMouthSVG = MouthDetail.openSmileMouthSVG();
        vm.writeFile("./output/smile_mouth.svg", openSmileMouthSVG);

        string memory sadMouthSVG = MouthDetail.sadMouthSVG();
        vm.writeFile("./output/sad_mouth.svg", sadMouthSVG);

        string memory seriousMouthSVG = MouthDetail.seriousMouthSVG();
        vm.writeFile("./output/serious_mouth.svg", seriousMouthSVG);

        string memory toungeMouthSVG = MouthDetail.toungeMouthSVG();
        vm.writeFile("./output/tounge_mouth.svg", toungeMouthSVG);

        /// test by using function
        string memory lipsRed = MouthDetail.getMouthById(2, 0);
        vm.writeFile("./output/lipsRed_test.svg", lipsRed);

        string memory purpleLips = MouthDetail.getMouthById(2, 1);
        vm.writeFile("./output/lipsPurple_test.svg", purpleLips);

        string memory pinkLips = MouthDetail.getMouthById(2, 2);
        vm.writeFile("./output/lipsPink_test.svg", pinkLips);

        string memory turquoiseLips = MouthDetail.getMouthById(2, 3);
        vm.writeFile("./output/lipsTurquoise_test.svg", turquoiseLips);

        string memory greenLips = MouthDetail.getMouthById(2, 4);
        vm.writeFile("./output/lipsGreen_test.svg", greenLips);

        /*//////////////////////////////////////////////////////////////
                             OPTIONAL ITEMS TEST
        //////////////////////////////////////////////////////////////*/
        string memory faceMaskSVG = OptItems.faceMaskSVG(0);
        vm.writeFile("./output/face_mask.svg", faceMaskSVG);

        string memory maskSVG = OptItems.maskSVG();
        vm.writeFile("./output/mask.svg", maskSVG);

        string memory lashesSVG = OptItems.lashesSVG();
        vm.writeFile("./output/lashes.svg", lashesSVG);

        string memory shapeSVG = OptItems.shapeSVG(1);
        vm.writeFile("./output/shape.svg", shapeSVG);

        /*//////////////////////////////////////////////////////////////
                             COLOR TEST
        //////////////////////////////////////////////////////////////*/
        string memory faceMaskWhite = OptItems.faceMaskSVG(0);
        vm.writeFile("./output/face_mask_white.svg", faceMaskWhite);

        string memory faceMaskBlue = OptItems.faceMaskSVG(1);
        vm.writeFile("./output/face_mask_blue.svg", faceMaskBlue);

        string memory faceMaskBlack = OptItems.faceMaskSVG(2);
        vm.writeFile("./output/face_mask_black.svg", faceMaskBlack);

        string memory faceMaskGreen = OptItems.faceMaskSVG(3);
        vm.writeFile("./output/face_mask_green.svg", faceMaskGreen);

        string memory faceMaskRed = OptItems.faceMaskSVG(4);
        vm.writeFile("./output/face_mask_red.svg", faceMaskRed);
    }
}
