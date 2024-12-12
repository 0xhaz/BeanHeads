// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {AccessoryDetail} from "src/libraries/AccessoryDetail.sol";
import {BodyDetail} from "src/libraries/BodyDetail.sol";
import {ClothingDetail} from "src/libraries/ClothingDetail.sol";
import {ClothingGraphicDetail} from "src/libraries/ClothingGraphicDetail.sol";
import {EyebrowDetail} from "src/libraries/EyebrowDetail.sol";

contract SVGTest is Test {
    function testSVGOutput() public {
        string memory tinyGlassesSVG = AccessoryDetail.tinyGlassesSVG();

        // Write to local file
        vm.writeFile("./output/tiny_glasses.svg", tinyGlassesSVG);

        string memory roundGlassesSVG = AccessoryDetail.roundGlassesSVG();
        vm.writeFile("./output/round_glasses.svg", roundGlassesSVG);

        string memory shadesSVG = AccessoryDetail.shadesSVG();
        vm.writeFile("./output/shades.svg", shadesSVG);

        string memory breastSVG = BodyDetail.breastSVG();
        vm.writeFile("./output/breast.svg", breastSVG);

        string memory chestSVG = BodyDetail.chestSVG();
        vm.writeFile("./output/chest.svg", chestSVG);

        string memory dressSVG = ClothingDetail.dressSVG();
        console.log(dressSVG);
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
    }
}
