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

        string memory breastSVG = BodyDetail.breastSVG(0);
        // console.log(breastSVG);
        vm.writeFile("./output/breast.svg", breastSVG);

        BodyDetail.Body memory breastWhite = BodyDetail.getBodyById(1, 0);
        vm.writeFile("./output/breast_white.svg", breastWhite.svg);

        BodyDetail.Body memory breastBlue = BodyDetail.getBodyById(1, 1);
        vm.writeFile("./output/breast_blue.svg", breastBlue.svg);

        BodyDetail.Body memory breastBlack = BodyDetail.getBodyById(1, 2);
        vm.writeFile("./output/breast_black.svg", breastBlack.svg);

        BodyDetail.Body memory breastGreen = BodyDetail.getBodyById(1, 3);
        vm.writeFile("./output/breast_green.svg", breastGreen.svg);

        BodyDetail.Body memory breastRed = BodyDetail.getBodyById(1, 4);
        vm.writeFile("./output/breast_red.svg", breastRed.svg);

        string memory chestSVG = BodyDetail.chestSVG(0);
        // console.log(chestSVG);
        vm.writeFile("./output/chest.svg", chestSVG);

        // Test by Id
        BodyDetail.Body memory bodyLightSkin = BodyDetail.getBodyById(2, 0);
        vm.writeFile("./output/body_test_light.svg", bodyLightSkin.svg);

        BodyDetail.Body memory bodyYellowSkin = BodyDetail.getBodyById(2, 1);
        vm.writeFile("./output/body_test_yellow.svg", bodyYellowSkin.svg);

        BodyDetail.Body memory bodyBrownSkin = BodyDetail.getBodyById(2, 2);
        vm.writeFile("./output/body_test_brown.svg", bodyBrownSkin.svg);

        BodyDetail.Body memory bodyDarkSkin = BodyDetail.getBodyById(2, 3);
        vm.writeFile("./output/body_test_dark.svg", bodyDarkSkin.svg);

        BodyDetail.Body memory bodyRedSkin = BodyDetail.getBodyById(2, 4);
        vm.writeFile("./output/body_test_red.svg", bodyRedSkin.svg);

        BodyDetail.Body memory bodyBlackSkin = BodyDetail.getBodyById(2, 5);
        vm.writeFile("./output/body_test_black.svg", bodyBlackSkin.svg);

        /*//////////////////////////////////////////////////////////////
                             CLOTHING TEST
        //////////////////////////////////////////////////////////////*/

        string memory dressSVG = ClothingDetail.dressSVG(0);
        // console.log(dressSVG);
        vm.writeFile("./output/dress.svg", dressSVG);

        string memory shirtSVG = ClothingDetail.shirtSVG(0);
        // console.log(shirtSVG);
        vm.writeFile("./output/shirt.svg", shirtSVG);

        string memory tShirtSVG = ClothingDetail.tShirtSVG(0);
        vm.writeFile("./output/t_shirt.svg", tShirtSVG);

        string memory tankTopSVG = ClothingDetail.tankTopSVG(0);
        vm.writeFile("./output/tank_top.svg", tankTopSVG);

        string memory vNeckSVG = ClothingDetail.vNeckSVG(0);
        vm.writeFile("./output/v_neck.svg", vNeckSVG);

        // Test by using function
        ClothingDetail.Clothing memory whiteDress = ClothingDetail.getClothingById(1, 0);
        vm.writeFile("./output/white_dress.svg", whiteDress.svg);

        ClothingDetail.Clothing memory blueDress = ClothingDetail.getClothingById(1, 1);
        vm.writeFile("./output/blue_dress.svg", blueDress.svg);

        ClothingDetail.Clothing memory blackDress = ClothingDetail.getClothingById(1, 2);
        vm.writeFile("./output/black_dress.svg", blackDress.svg);

        ClothingDetail.Clothing memory greenDress = ClothingDetail.getClothingById(1, 3);
        vm.writeFile("./output/green_dress.svg", greenDress.svg);

        ClothingDetail.Clothing memory redDress = ClothingDetail.getClothingById(1, 4);
        vm.writeFile("./output/red_dress.svg", redDress.svg);

        ClothingDetail.Clothing memory shirtWhite = ClothingDetail.getClothingById(2, 0);
        vm.writeFile("./output/white_shirt.svg", shirtWhite.svg);

        ClothingDetail.Clothing memory shirtBlue = ClothingDetail.getClothingById(2, 1);
        vm.writeFile("./output/blue_shirt.svg", shirtBlue.svg);

        ClothingDetail.Clothing memory shirtBlack = ClothingDetail.getClothingById(2, 2);
        vm.writeFile("./output/black_shirt.svg", shirtBlack.svg);

        ClothingDetail.Clothing memory shirtGreen = ClothingDetail.getClothingById(2, 3);
        vm.writeFile("./output/green_shirt.svg", shirtGreen.svg);

        ClothingDetail.Clothing memory shirtRed = ClothingDetail.getClothingById(2, 4);
        vm.writeFile("./output/red_shirt.svg", shirtRed.svg);

        ClothingDetail.Clothing memory tShirtWhite = ClothingDetail.getClothingById(3, 0);
        vm.writeFile("./output/white_t_shirt.svg", tShirtWhite.svg);

        ClothingDetail.Clothing memory tShirtBlue = ClothingDetail.getClothingById(3, 1);
        vm.writeFile("./output/blue_t_shirt.svg", tShirtBlue.svg);

        ClothingDetail.Clothing memory tShirtBlack = ClothingDetail.getClothingById(3, 2);
        vm.writeFile("./output/black_t_shirt.svg", tShirtBlack.svg);

        ClothingDetail.Clothing memory tShirtGreen = ClothingDetail.getClothingById(3, 3);
        vm.writeFile("./output/green_t_shirt.svg", tShirtGreen.svg);

        ClothingDetail.Clothing memory tShirtRed = ClothingDetail.getClothingById(3, 4);
        vm.writeFile("./output/red_t_shirt.svg", tShirtRed.svg);

        ClothingDetail.Clothing memory tankTopWhite = ClothingDetail.getClothingById(4, 0);
        vm.writeFile("./output/white_tank_top.svg", tankTopWhite.svg);

        ClothingDetail.Clothing memory tankTopBlue = ClothingDetail.getClothingById(4, 1);
        vm.writeFile("./output/blue_tank_top.svg", tankTopBlue.svg);

        ClothingDetail.Clothing memory tankTopBlack = ClothingDetail.getClothingById(4, 2);
        vm.writeFile("./output/black_tank_top.svg", tankTopBlack.svg);

        ClothingDetail.Clothing memory tankTopGreen = ClothingDetail.getClothingById(4, 3);
        vm.writeFile("./output/green_tank_top.svg", tankTopGreen.svg);

        ClothingDetail.Clothing memory tankTopRed = ClothingDetail.getClothingById(4, 4);
        vm.writeFile("./output/red_tank_top.svg", tankTopRed.svg);

        ClothingDetail.Clothing memory vNeckWhite = ClothingDetail.getClothingById(5, 0);
        vm.writeFile("./output/white_v_neck.svg", vNeckWhite.svg);

        ClothingDetail.Clothing memory vNeckBlue = ClothingDetail.getClothingById(5, 1);
        vm.writeFile("./output/blue_v_neck.svg", vNeckBlue.svg);

        ClothingDetail.Clothing memory vNeckBlack = ClothingDetail.getClothingById(5, 2);
        vm.writeFile("./output/black_v_neck.svg", vNeckBlack.svg);

        ClothingDetail.Clothing memory vNeckGreen = ClothingDetail.getClothingById(5, 3);
        vm.writeFile("./output/green_v_neck.svg", vNeckGreen.svg);

        ClothingDetail.Clothing memory vNeckRed = ClothingDetail.getClothingById(5, 4);
        vm.writeFile("./output/red_v_neck.svg", vNeckRed.svg);

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
        HairDetail.Hair memory afroBlonde = HairDetail.getHairDetailById(1, 0);
        vm.writeFile("./output/afro_blonde.svg", afroBlonde.svg);

        HairDetail.Hair memory afroOrange = HairDetail.getHairDetailById(1, 1);
        vm.writeFile("./output/afro_orange.svg", afroOrange.svg);

        HairDetail.Hair memory afroBlack = HairDetail.getHairDetailById(1, 2);
        vm.writeFile("./output/afro_black.svg", afroBlack.svg);

        HairDetail.Hair memory afroWhite = HairDetail.getHairDetailById(1, 3);
        vm.writeFile("./output/afro_white.svg", afroWhite.svg);

        HairDetail.Hair memory afroBrown = HairDetail.getHairDetailById(1, 4);
        vm.writeFile("./output/afro_brown.svg", afroBrown.svg);

        HairDetail.Hair memory afroBlue = HairDetail.getHairDetailById(1, 5);
        vm.writeFile("./output/afro_blue.svg", afroBlue.svg);

        HairDetail.Hair memory afroPink = HairDetail.getHairDetailById(1, 6);
        vm.writeFile("./output/afro_pink.svg", afroPink.svg);

        HairDetail.Hair memory baldBlonde = HairDetail.getHairDetailById(2, 0);
        vm.writeFile("./output/bald_blonde.svg", baldBlonde.svg);

        HairDetail.Hair memory baldOrange = HairDetail.getHairDetailById(2, 1);
        vm.writeFile("./output/bald_orange.svg", baldOrange.svg);

        HairDetail.Hair memory baldBlack = HairDetail.getHairDetailById(2, 2);
        vm.writeFile("./output/bald_black.svg", baldBlack.svg);

        HairDetail.Hair memory baldWhite = HairDetail.getHairDetailById(2, 3);
        vm.writeFile("./output/bald_white.svg", baldWhite.svg);

        HairDetail.Hair memory baldBrown = HairDetail.getHairDetailById(2, 4);
        vm.writeFile("./output/bald_brown.svg", baldBrown.svg);

        HairDetail.Hair memory baldBlue = HairDetail.getHairDetailById(2, 5);
        vm.writeFile("./output/bald_blue.svg", baldBlue.svg);

        HairDetail.Hair memory baldPink = HairDetail.getHairDetailById(2, 6);
        vm.writeFile("./output/bald_pink.svg", baldPink.svg);

        HairDetail.Hair memory bobBlonde = HairDetail.getHairDetailById(3, 0);
        vm.writeFile("./output/bob_blonde.svg", bobBlonde.svg);

        HairDetail.Hair memory bobOrange = HairDetail.getHairDetailById(3, 1);
        vm.writeFile("./output/bob_orange.svg", bobOrange.svg);

        HairDetail.Hair memory bobBlack = HairDetail.getHairDetailById(3, 2);
        vm.writeFile("./output/bob_black.svg", bobBlack.svg);

        HairDetail.Hair memory bobWhite = HairDetail.getHairDetailById(3, 3);
        vm.writeFile("./output/bob_white.svg", bobWhite.svg);

        HairDetail.Hair memory bobBrown = HairDetail.getHairDetailById(3, 4);
        vm.writeFile("./output/bob_brown.svg", bobBrown.svg);

        HairDetail.Hair memory bobBlue = HairDetail.getHairDetailById(3, 5);
        vm.writeFile("./output/bob_blue.svg", bobBlue.svg);

        HairDetail.Hair memory bobPink = HairDetail.getHairDetailById(3, 6);
        vm.writeFile("./output/bob_pink.svg", bobPink.svg);

        HairDetail.Hair memory bunBlonde = HairDetail.getHairDetailById(4, 0);
        vm.writeFile("./output/bun_blonde.svg", bunBlonde.svg);

        HairDetail.Hair memory bunOrange = HairDetail.getHairDetailById(4, 1);
        vm.writeFile("./output/bun_orange.svg", bunOrange.svg);

        HairDetail.Hair memory bunBlack = HairDetail.getHairDetailById(4, 2);
        vm.writeFile("./output/bun_black.svg", bunBlack.svg);

        HairDetail.Hair memory bunWhite = HairDetail.getHairDetailById(4, 3);
        vm.writeFile("./output/bun_white.svg", bunWhite.svg);

        HairDetail.Hair memory bunBrown = HairDetail.getHairDetailById(4, 4);
        vm.writeFile("./output/bun_brown.svg", bunBrown.svg);

        HairDetail.Hair memory bunBlue = HairDetail.getHairDetailById(4, 5);
        vm.writeFile("./output/bun_blue.svg", bunBlue.svg);

        HairDetail.Hair memory bunPink = HairDetail.getHairDetailById(4, 6);
        vm.writeFile("./output/bun_pink.svg", bunPink.svg);

        HairDetail.Hair memory longBlonde = HairDetail.getHairDetailById(5, 0);
        vm.writeFile("./output/long_blonde.svg", longBlonde.svg);

        HairDetail.Hair memory longOrange = HairDetail.getHairDetailById(5, 1);
        vm.writeFile("./output/long_orange.svg", longOrange.svg);

        HairDetail.Hair memory longBlack = HairDetail.getHairDetailById(5, 2);
        vm.writeFile("./output/long_black.svg", longBlack.svg);

        HairDetail.Hair memory longWhite = HairDetail.getHairDetailById(5, 3);
        vm.writeFile("./output/long_white.svg", longWhite.svg);

        HairDetail.Hair memory longBrown = HairDetail.getHairDetailById(5, 4);
        vm.writeFile("./output/long_brown.svg", longBrown.svg);

        HairDetail.Hair memory longBlue = HairDetail.getHairDetailById(5, 5);
        vm.writeFile("./output/long_blue.svg", longBlue.svg);

        HairDetail.Hair memory longPink = HairDetail.getHairDetailById(5, 6);
        vm.writeFile("./output/long_pink.svg", longPink.svg);

        HairDetail.Hair memory pixieBlonde = HairDetail.getHairDetailById(6, 0);
        vm.writeFile("./output/pixie_blonde.svg", pixieBlonde.svg);

        HairDetail.Hair memory pixieOrange = HairDetail.getHairDetailById(6, 1);
        vm.writeFile("./output/pixie_orange.svg", pixieOrange.svg);

        HairDetail.Hair memory pixieBlack = HairDetail.getHairDetailById(6, 2);
        vm.writeFile("./output/pixie_black.svg", pixieBlack.svg);

        HairDetail.Hair memory pixieWhite = HairDetail.getHairDetailById(6, 3);
        vm.writeFile("./output/pixie_white.svg", pixieWhite.svg);

        HairDetail.Hair memory pixieBrown = HairDetail.getHairDetailById(6, 4);
        vm.writeFile("./output/pixie_brown.svg", pixieBrown.svg);

        HairDetail.Hair memory pixieBlue = HairDetail.getHairDetailById(6, 5);
        vm.writeFile("./output/pixie_blue.svg", pixieBlue.svg);

        HairDetail.Hair memory pixiePink = HairDetail.getHairDetailById(6, 6);
        vm.writeFile("./output/pixie_pink.svg", pixiePink.svg);

        HairDetail.Hair memory shortBlonde = HairDetail.getHairDetailById(7, 0);
        vm.writeFile("./output/short_blonde.svg", shortBlonde.svg);

        HairDetail.Hair memory shortOrange = HairDetail.getHairDetailById(7, 1);
        vm.writeFile("./output/short_orange.svg", shortOrange.svg);

        HairDetail.Hair memory shortBlack = HairDetail.getHairDetailById(7, 2);
        vm.writeFile("./output/short_black.svg", shortBlack.svg);

        HairDetail.Hair memory shortWhite = HairDetail.getHairDetailById(7, 3);
        vm.writeFile("./output/short_white.svg", shortWhite.svg);

        HairDetail.Hair memory shortBrown = HairDetail.getHairDetailById(7, 4);
        vm.writeFile("./output/short_brown.svg", shortBrown.svg);

        HairDetail.Hair memory shortBlue = HairDetail.getHairDetailById(7, 5);
        vm.writeFile("./output/short_blue.svg", shortBlue.svg);

        HairDetail.Hair memory shortPink = HairDetail.getHairDetailById(7, 6);
        vm.writeFile("./output/short_pink.svg", shortPink.svg);

        /*//////////////////////////////////////////////////////////////
                             HAT TEST
        //////////////////////////////////////////////////////////////*/

        string memory beanieSVG = HatsDetail.beanieHatSVG(0);
        vm.writeFile("./output/beanie_hat.svg", beanieSVG);

        string memory turbanHatSVG = HatsDetail.turbanHatSVG(0);
        vm.writeFile("./output/turban_hat.svg", turbanHatSVG);

        /// test by using function
        HatsDetail.Hats memory beanieWhite = HatsDetail.getHatsById(1, 0);
        vm.writeFile("./output/beanie_white.svg", beanieWhite.svg);

        HatsDetail.Hats memory beanieBlue = HatsDetail.getHatsById(1, 1);
        vm.writeFile("./output/beanie_blue.svg", beanieBlue.svg);

        HatsDetail.Hats memory beanieBlack = HatsDetail.getHatsById(1, 2);
        vm.writeFile("./output/beanie_black.svg", beanieBlack.svg);

        HatsDetail.Hats memory beanieGreen = HatsDetail.getHatsById(1, 3);
        vm.writeFile("./output/beanie_green.svg", beanieGreen.svg);

        HatsDetail.Hats memory beanieRed = HatsDetail.getHatsById(1, 4);
        vm.writeFile("./output/beanie_red.svg", beanieRed.svg);

        HatsDetail.Hats memory turbanWhite = HatsDetail.getHatsById(2, 0);
        vm.writeFile("./output/turban_white.svg", turbanWhite.svg);

        HatsDetail.Hats memory turbanBlue = HatsDetail.getHatsById(2, 1);
        vm.writeFile("./output/turban_blue.svg", turbanBlue.svg);

        HatsDetail.Hats memory turbanBlack = HatsDetail.getHatsById(2, 2);
        vm.writeFile("./output/turban_black.svg", turbanBlack.svg);

        HatsDetail.Hats memory turbanGreen = HatsDetail.getHatsById(2, 3);
        vm.writeFile("./output/turban_green.svg", turbanGreen.svg);

        HatsDetail.Hats memory turbanRed = HatsDetail.getHatsById(2, 4);
        vm.writeFile("./output/turban_red.svg", turbanRed.svg);

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
        MouthDetail.Mouth memory lipsRed = MouthDetail.getMouthById(2, 0);
        vm.writeFile("./output/lipsRed_test.svg", lipsRed.svg);

        MouthDetail.Mouth memory purpleLips = MouthDetail.getMouthById(2, 1);
        vm.writeFile("./output/lipsPurple_test.svg", purpleLips.svg);

        MouthDetail.Mouth memory pinkLips = MouthDetail.getMouthById(2, 2);
        vm.writeFile("./output/lipsPink_test.svg", pinkLips.svg);

        MouthDetail.Mouth memory turquoiseLips = MouthDetail.getMouthById(2, 3);
        vm.writeFile("./output/lipsTurquoise_test.svg", turquoiseLips.svg);

        MouthDetail.Mouth memory greenLips = MouthDetail.getMouthById(2, 4);
        vm.writeFile("./output/lipsGreen_test.svg", greenLips.svg);

        /*//////////////////////////////////////////////////////////////
                             OPTIONAL ITEMS TEST
        //////////////////////////////////////////////////////////////*/
        string memory faceMaskSVG = OptItems.faceMaskSVG(0);
        vm.writeFile("./output/face_mask.svg", faceMaskSVG);

        string memory maskSVG = OptItems.maskSVG();
        vm.writeFile("./output/mask.svg", maskSVG);

        string memory lashesSVG = OptItems.lashesSVG();
        vm.writeFile("./output/lashes.svg", lashesSVG);

        string memory shapeSVG = OptItems.shapeSVG();
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
