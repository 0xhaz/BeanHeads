// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {AccessoryDetail} from "src/libraries/AccessoryDetail.sol";
import {BodyDetail} from "src/libraries/BodyDetail.sol";
import {ClothingDetail} from "src/libraries/ClothingDetail.sol";
import {ClothingGraphicDetail} from "src/libraries/ClothingGraphicDetail.sol";
import {EyebrowDetail} from "src/libraries/EyebrowDetail.sol";
import {EyesDetail} from "src/libraries/EyesDetail.sol";
import {FacialHairDetail} from "src/libraries/FacialHairDetail.sol";
import {HairDetail} from "src/libraries/HairDetail.sol";
import {HatsDetail} from "src/libraries/HatsDetail.sol";
import {MouthDetail} from "src/libraries/MouthDetail.sol";

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

        /*//////////////////////////////////////////////////////////////
                             BODY TEST
        //////////////////////////////////////////////////////////////*/

        string memory shadesSVG = AccessoryDetail.shadesSVG();
        vm.writeFile("./output/shades.svg", shadesSVG);

        string memory breastSVG = BodyDetail.breastSVG();
        vm.writeFile("./output/breast.svg", breastSVG);

        string memory chestSVG = BodyDetail.chestSVG();
        vm.writeFile("./output/chest.svg", chestSVG);

        string memory dressSVG = ClothingDetail.dressSVG();
        // console.log(dressSVG);
        vm.writeFile("./output/dress.svg", dressSVG);

        string memory shirtSVG = ClothingDetail.shirtSVG();
        // console.log(shirtSVG);
        vm.writeFile("./output/shirt.svg", shirtSVG);

        string memory tShirtSVG = ClothingDetail.tShirtSVG();
        vm.writeFile("./output/t_shirt.svg", tShirtSVG);

        string memory tankTopSVG = ClothingDetail.tankTopSVG();
        vm.writeFile("./output/tank_top.svg", tankTopSVG);

        string memory vNeckSVG = ClothingDetail.vNeckSVG();
        vm.writeFile("./output/v_neck.svg", vNeckSVG);

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

        string memory afroHairSVG = HairDetail.afroHairSVG();
        vm.writeFile("./output/afro_hair.svg", afroHairSVG);

        string memory baldHairSVG = HairDetail.baldHairSVG();
        vm.writeFile("./output/bald_hair.svg", baldHairSVG);

        string memory bobCutSVG = HairDetail.bobCutSVG();
        vm.writeFile("./output/bob_cut.svg", bobCutSVG);

        string memory bunHairSVG = HairDetail.bunHairSVG();
        vm.writeFile("./output/bun_hair.svg", bunHairSVG);

        string memory longHairSVG = HairDetail.longHairSVG();
        vm.writeFile("./output/long_hair.svg", longHairSVG);

        string memory pixieCutSVG = HairDetail.pixieCutSVG();
        vm.writeFile("./output/pixie_cut.svg", pixieCutSVG);

        string memory shortHairSVG = HairDetail.shortHairSVG();
        vm.writeFile("./output/short_hair.svg", shortHairSVG);

        /*//////////////////////////////////////////////////////////////
                             HAT TEST
        //////////////////////////////////////////////////////////////*/

        string memory beanieSVG = HatsDetail.beanieHatSVG();
        vm.writeFile("./output/beanie_hat.svg", beanieSVG);

        string memory turbanHatSVG = HatsDetail.turbanHatSVG();
        vm.writeFile("./output/turban_hat.svg", turbanHatSVG);

        /*//////////////////////////////////////////////////////////////
                             MOUTH TEST
        //////////////////////////////////////////////////////////////*/
        string memory grinMouthSVG = MouthDetail.grinMouthSVG();
        vm.writeFile("./output/grin_mouth.svg", grinMouthSVG);

        string memory lipsMouthSVG = MouthDetail.lipsMouthSVG();
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
    }
}
