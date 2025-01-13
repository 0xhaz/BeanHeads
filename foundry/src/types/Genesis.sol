// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {AccessoryDetail} from "src/libraries/baseModel/AccessoryDetail.sol";
import {BodyDetail} from "src/libraries/baseModel/BodyDetail.sol";
import {ClothingDetail} from "src/libraries/baseModel/ClothingDetail.sol";
import {ClothingGraphicDetail} from "src/libraries/baseModel/ClothingGraphicDetail.sol";
import {EyebrowDetail} from "src/libraries/baseModel/EyebrowDetail.sol";
import {EyesDetail} from "src/libraries/baseModel/EyesDetail.sol";
import {FacialHairDetail} from "src/libraries/baseModel/FacialHairDetail.sol";
import {HairDetail} from "src/libraries/baseModel/HairDetail.sol";
import {HatsDetail} from "src/libraries/baseModel/HatsDetail.sol";
import {OptItems} from "src/libraries/baseModel/OptItems.sol";
import {MouthDetail} from "src/libraries/baseModel/MouthDetail.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library Genesis {
    using Strings for uint8;

    struct HairParams {
        uint8 hairStyle;
        uint8 hairColor;
    }

    struct BodyParams {
        uint8 bodyType;
        uint8 skinColor;
    }

    struct ClothingParams {
        uint8 clothes;
        uint8 clothingColor;
        uint8 clothesGraphic;
    }

    struct FacialFeaturesParams {
        uint8 eyebrowShape;
        uint8 eyeShape;
        uint8 facialHairType;
        uint8 mouthStyle;
        uint8 lipColor;
    }

    struct AccessoryParams {
        uint8 accessoryId;
        uint8 hatStyle;
        uint8 hatColor;
    }

    struct OtherParams {
        bool faceMask;
        uint8 faceMaskColor;
        bool shapes;
        uint8 shapeColor;
        bool lashes;
    }

    struct SVGParams {
        HairParams hairParams;
        BodyParams bodyParams;
        ClothingParams clothingParams;
        FacialFeaturesParams facialFeaturesParams;
        AccessoryParams accessoryParams;
        OtherParams otherParams;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTION
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Builds an SVG string for the avatar based on the provided parameters.
     * @dev Uses components and styles to construct the final SVG.
     * @param params A `SVGParams` struct containing details for avatar customization.
     * @return svg The complete SVG string representing the avatar.
     */
    function buildAvatar(SVGParams memory params) internal pure returns (string memory) {
        (
            string memory hairBack,
            string memory hairFront,
            string memory hairSVG,
            string memory accessorySVG,
            string memory bodySVG,
            string memory clothesSVG,
            string memory clothingGraphicSVG,
            string memory eyebrowShapeSVG,
            string memory eyeSVG,
            string memory facialHairSVG,
            string memory hatSVG,
            string memory mouthNameSVG,
            string memory shapeSVG,
            string memory faceMaskSVG
        ) = getSVG(params);

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">',
                shapeSVG,
                hairBack,
                bodySVG,
                hairFront,
                clothesSVG,
                hairSVG,
                clothingGraphicSVG,
                eyeSVG,
                facialHairSVG,
                hatSVG,
                mouthNameSVG,
                eyebrowShapeSVG,
                accessorySVG,
                faceMaskSVG,
                isLashesOn(params.facialFeaturesParams.eyeShape, params.otherParams.lashes)
            )
        );

        return svg;
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE FUNCTION
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Retrieves the SVG components for the avatar.
     * @dev Combines hair, body, clothing, and other components into separate SVG strings.
     * @param params A `SVGParams` struct containing details for avatar customization.
     * @return hairBack The SVG string for the back of the hair.
     * @return hairFront The SVG string for the front of the hair.
     * @return hairSVG The SVG string for hair details.
     * @return accessorySVG The SVG string for accessories.
     * @return bodySVG The SVG string for the body.
     * @return clothesSVG The SVG string for the clothing.
     * @return clothingGraphicSVG The SVG string for clothing graphics.
     * @return eyebrowShapeSVG The SVG string for eyebrows.
     * @return eyeSVG The SVG string for eyes.
     * @return facialHairSVG The SVG string for facial hair.
     * @return hatSVG The SVG string for hats.
     * @return mouthNameSVG The SVG string for the mouth.
     * @return shapeSVG The SVG string for shapes.
     * @return faceMaskSVG The SVG string for face masks.
     */
    function getSVG(SVGParams memory params)
        private
        pure
        returns (
            string memory hairBack,
            string memory hairFront,
            string memory hairSVG,
            string memory accessorySVG,
            string memory bodySVG,
            string memory clothesSVG,
            string memory clothingGraphicSVG,
            string memory eyebrowShapeSVG,
            string memory eyeSVG,
            string memory facialHairSVG,
            string memory hatSVG,
            string memory mouthNameSVG,
            string memory shapeSVG,
            string memory faceMaskSVG
        )
    {
        (hairBack, hairFront) = getHairComponentsById(params.hairParams.hairStyle, params.hairParams.hairColor);

        (hairSVG,) = HairDetail.getHairById(params.hairParams.hairStyle, params.hairParams.hairColor);

        (accessorySVG,) = AccessoryDetail.getAccessoryById(params.accessoryParams.accessoryId);

        (bodySVG,) = BodyDetail.getBodyById(
            params.bodyParams.bodyType, params.bodyParams.skinColor, params.clothingParams.clothingColor
        );

        (clothesSVG,) = ClothingDetail.getClothingById(
            params.bodyParams.bodyType, params.clothingParams.clothes, params.clothingParams.clothingColor
        );

        (clothingGraphicSVG,) = ClothingGraphicDetail.getClothingGraphicById(
            params.clothingParams.clothes, params.clothingParams.clothesGraphic
        );

        (eyebrowShapeSVG,) = EyebrowDetail.getEyebrowById(params.facialFeaturesParams.eyebrowShape);

        (eyeSVG,) = EyesDetail.getEyeById(params.facialFeaturesParams.eyeShape, params.bodyParams.skinColor);

        (facialHairSVG,) = FacialHairDetail.getFacialHairById(params.facialFeaturesParams.facialHairType);

        (hatSVG,) = HatsDetail.getHatsById(
            params.accessoryParams.hatStyle, params.accessoryParams.hatColor, params.hairParams.hairStyle
        );

        (mouthNameSVG,) =
            MouthDetail.getMouthById(params.facialFeaturesParams.mouthStyle, params.facialFeaturesParams.lipColor);

        (shapeSVG,) = isShapesOn(params.otherParams.shapes, params.otherParams.shapeColor);

        (faceMaskSVG,) = isFaceMaskOn(params.otherParams.faceMask, params.otherParams.faceMaskColor);
    }

    /**
     * @notice Retrieves the SVG string and name for the face mask if enabled.
     * @param faceMask A boolean indicating if the face mask is enabled.
     * @param color The color ID for the face mask.
     * @return maskSVG The SVG string for the face mask.
     * @return name The name of the face mask color.
     */
    function isFaceMaskOn(bool faceMask, uint8 color)
        private
        pure
        returns (string memory maskSVG, string memory name)
    {
        if (faceMask) {
            (maskSVG, name) = OptItems.faceMaskSVG(color);
            return (maskSVG, name);
        }
        return ("", "");
    }

    /**
     * @notice Retrieves the SVG string and name for shapes if enabled.
     * @param shapes A boolean indicating if shapes are enabled.
     * @param color The color ID for the shape.
     * @return shape The SVG string for the shape.
     * @return name The name of the shape color.
     */
    function isShapesOn(bool shapes, uint8 color) private pure returns (string memory shape, string memory name) {
        if (shapes) {
            (shape, name) = OptItems.shapeSVG(color);
            return (shape, name);
        }
        return ("", "");
    }

    /**
     * @notice Retrieves the SVG string for eyelashes if enabled.
     * @param eyeShape The ID of the eye shape.
     * @param lashes A boolean indicating if lashes are enabled.
     * @return svg The SVG string for eyelashes.
     */
    function isLashesOn(uint8 eyeShape, bool lashes) private pure returns (string memory) {
        if (lashes) {
            return OptItems.lashesSVG(eyeShape);
        }

        return "";
    }

    /**
     * @notice Retrieves the SVG strings for the back and front components of the hair.
     * @param id The ID of the hair style.
     * @param color The color ID for the hair.
     * @return back The SVG string for the back of the hair.
     * @return front The SVG string for the front of the hair.
     */
    function getHairComponentsById(uint8 id, uint8 color)
        private
        pure
        returns (string memory back, string memory front)
    {
        if (id == 1) {
            (back, front) = HairDetail.afroHairSVG(color);
        } else if (id == 3) {
            (back, front) = HairDetail.bobCutSVG(color);
        } else if (id == 5) {
            (back, front) = HairDetail.longHairSVG(color);
        } else {
            return ("", "");
        }
    }

    /**
     * @notice Builds the JSON array of attributes for the NFT metadata.
     * @param params A `SVGParams` struct containing details for avatar customization.
     * @return attributes A JSON string representing the attributes array.
     */
    function buildAttributes(Genesis.SVGParams memory params) internal pure returns (string memory) {
        // Initialize JSON string
        string memory attributes = "[";

        // Track if it's the first attribute to avoid leading commas
        bool isFirst = true;

        unchecked {
            string[2] memory hairAttributes = buildHairAttributes(params.hairParams);
            attributes = concatenateAttributes(attributes, hairAttributes, isFirst);
            isFirst = false;

            string[3] memory accessoryAttributes = buildAccessoryAttributes(params.accessoryParams);
            attributes = concatenateAttributes(attributes, accessoryAttributes, isFirst);

            string[2] memory bodyAttributes = buildBodyAttributes(params.bodyParams);
            attributes = concatenateAttributes(attributes, bodyAttributes, isFirst);

            string[3] memory clothingAttributes = buildClothingAttributes(params.clothingParams);
            attributes = concatenateAttributes(attributes, clothingAttributes, isFirst);

            string[5] memory facialFeaturesAttributes = buildFacialFeaturesAttributes(params.facialFeaturesParams);
            attributes = concatenateAttributes(attributes, facialFeaturesAttributes, isFirst);

            for (uint256 i; i < facialFeaturesAttributes.length; ++i) {
                if (bytes(facialFeaturesAttributes[i]).length > 0) {
                    if (!isFirst) {
                        attributes = string(abi.encodePacked(attributes, ","));
                    }
                    attributes = string(abi.encodePacked(attributes, facialFeaturesAttributes[i]));
                    isFirst = false;
                }
            }

            // Add boolean and conditional traits
            if (params.otherParams.faceMask) {
                string memory faceMaskAttribute = string(
                    abi.encodePacked(
                        '{"trait_type": "Face Mask", "value": "true"},',
                        '{"trait_type": "Face Mask Color", "value": "',
                        OptItems.getFaceMaskColor(params.otherParams.faceMaskColor),
                        '"}'
                    )
                );
                attributes = concatenateAttributes(attributes, faceMaskAttribute, isFirst);
            }

            if (params.otherParams.shapes) {
                string memory shapesAttribute = string(
                    abi.encodePacked(
                        '{"trait_type": "Shapes", "value": "true"},',
                        '{"trait_type": "Shape Color", "value": "',
                        OptItems.getShapeColor(params.otherParams.shapeColor),
                        '"}'
                    )
                );
                attributes = concatenateAttributes(attributes, shapesAttribute, isFirst);
            }

            if (params.otherParams.lashes) {
                string memory lashesAttribute = '{"trait_type": "Lashes", "value": "true"}';
                attributes = concatenateAttributes(attributes, lashesAttribute, isFirst);
            }
        }

        // Close JSON array
        attributes = string(abi.encodePacked(attributes, "]"));
        return attributes;
    }

    /**
     * @notice Builds the attributes for hair style and color.
     * @param params A `HairParams` struct containing hair style and color details.
     * @return hairAttributes An array of two JSON strings representing hair attributes.
     */
    function buildHairAttributes(HairParams memory params) private pure returns (string[2] memory hairAttributes) {
        string memory hairStyleName = HairDetail.getHairTypeName(params.hairStyle);
        string memory hairColorName = HairDetail.getHairColorName(params.hairColor);

        hairAttributes[0] = string(abi.encodePacked('{"trait_type": "Hair Style", "value": "', hairStyleName, '"}'));

        hairAttributes[1] = string(abi.encodePacked('{"trait_type": "Hair Color", "value": "', hairColorName, '"}'));

        return hairAttributes;
    }

    /**
     * @notice Builds the attributes for accessories, hat style, and hat color.
     * @param params An `AccessoryParams` struct containing accessory details.
     * @return accessoryAttributes An array of three JSON strings representing accessory attributes.
     */
    function buildAccessoryAttributes(AccessoryParams memory params)
        private
        pure
        returns (string[3] memory accessoryAttributes)
    {
        string memory accessoryName = AccessoryDetail.getAccessoryName(params.accessoryId);
        string memory hatName = HatsDetail.getHatsName(params.hatStyle);
        string memory hatColorName = HatsDetail.getHatsColorName(params.hatColor);

        accessoryAttributes[0] = string(abi.encodePacked('{"trait_type": "Accessory", "value": "', accessoryName, '"}'));

        accessoryAttributes[1] = string(abi.encodePacked('{"trait_type": "Hat Style", "value": "', hatName, '"}'));

        accessoryAttributes[2] = string(abi.encodePacked('{"trait_type": "Hat Color", "value": "', hatColorName, '"}'));

        return accessoryAttributes;
    }

    /**
     * @notice Builds the attributes for body type and skin color.
     * @param params A `BodyParams` struct containing body type and skin color details.
     * @return bodyAttributes An array of two JSON strings representing body attributes.
     */
    function buildBodyAttributes(BodyParams memory params) private pure returns (string[2] memory bodyAttributes) {
        string memory bodyTypeName = BodyDetail.getBodyTypeName(params.bodyType);
        string memory skinColorName = BodyDetail.getBodyColorName(params.skinColor);

        bodyAttributes[0] = string(abi.encodePacked('{"trait_type": "Body Type", "value": "', bodyTypeName, '"}'));

        bodyAttributes[1] = string(abi.encodePacked('{"trait_type": "Skin Color", "value": "', skinColorName, '"}'));

        return bodyAttributes;
    }

    /**
     * @notice Builds the attributes for clothing, clothing color, and graphic.
     * @param params A `ClothingParams` struct containing clothing details.
     * @return clothingAttributes An array of three JSON strings representing clothing attributes.
     */
    function buildClothingAttributes(ClothingParams memory params)
        private
        pure
        returns (string[3] memory clothingAttributes)
    {
        string memory clothesName = ClothingDetail.getClothingName(params.clothes);
        string memory clothesColorName = ClothingDetail.getClothingColor(params.clothingColor);
        string memory clothingGraphicName = ClothingGraphicDetail.getClothingGraphicName(params.clothesGraphic);

        clothingAttributes[0] = string(abi.encodePacked('{"trait_type": "Clothes", "value": "', clothesName, '"}'));

        clothingAttributes[1] =
            string(abi.encodePacked('{"trait_type": "Clothes Color", "value": "', clothesColorName, '"}'));

        clothingAttributes[2] =
            string(abi.encodePacked('{"trait_type": "Clothes Graphic", "value": "', clothingGraphicName, '"}'));

        return clothingAttributes;
    }

    /**
     * @notice Builds the attributes for facial features, including eyebrows, eyes, facial hair, and lips.
     * @param params A `FacialFeaturesParams` struct containing facial feature details.
     * @return facialFeaturesAttributes An array of five JSON strings representing facial features attributes.
     */
    function buildFacialFeaturesAttributes(FacialFeaturesParams memory params)
        private
        pure
        returns (string[5] memory facialFeaturesAttributes)
    {
        string memory eyebrowShapeName = EyebrowDetail.getEyebrowName(params.eyebrowShape);
        string memory eyeName = EyesDetail.getEyeName(params.eyeShape);
        string memory facialHairName = FacialHairDetail.getFacialHairName(params.facialHairType);
        string memory mouthStyleName = MouthDetail.getMouthName(params.mouthStyle);
        string memory lipColorName;

        // Only retrieve the lip color name if the mouth style is lipsMouthSVG
        if (params.mouthStyle == 1) {
            lipColorName = MouthDetail.getMouthColor(params.lipColor);
        }

        facialFeaturesAttributes[0] =
            string(abi.encodePacked('{"trait_type": "Eyebrow Shape", "value": "', eyebrowShapeName, '"}'));

        facialFeaturesAttributes[1] = string(abi.encodePacked('{"trait_type": "Eye Shape", "value": "', eyeName, '"}'));

        facialFeaturesAttributes[2] =
            string(abi.encodePacked('{"trait_type": "Facial Hair Type", "value": "', facialHairName, '"}'));

        facialFeaturesAttributes[3] =
            string(abi.encodePacked('{"trait_type": "Mouth Style", "value": "', mouthStyleName, '"}'));

        // Add "Lip Color" trait only if lipColorName is set (i.e., mouthStyle is lipsMouthSVG)
        if (bytes(lipColorName).length > 0) {
            facialFeaturesAttributes[4] =
                string(abi.encodePacked('{"trait_type": "Lip Color", "value": "', lipColorName, '"}'));
        } else {
            facialFeaturesAttributes[4] = "";
        }

        return facialFeaturesAttributes;
    }

    /**
     * @notice Builds the attributes for optional items such as face masks, shapes, and lashes.
     * @param params An `OtherParams` struct containing optional item details.
     * @return otherAttributes An array of five JSON strings representing optional item attributes.
     */
    function buildOtherAttributes(OtherParams memory params) private pure returns (string[5] memory otherAttributes) {
        string memory shapeColor = OptItems.getShapeColor(params.shapeColor);
        string memory faceMaskColor = OptItems.getFaceMaskColor(params.faceMaskColor);

        otherAttributes[0] =
            string(abi.encodePacked('{"trait_type":"Face Mask", "value": "', params.faceMask ? "true" : "false", '"}'));

        otherAttributes[1] =
            string(abi.encodePacked('{"trait_type": "Face Mask Color", "value": "', faceMaskColor, '"}'));

        otherAttributes[2] =
            string(abi.encodePacked('{"trait_type": "Shapes", "value": "', params.shapes ? "true" : "false", '"}'));

        otherAttributes[3] = string(abi.encodePacked('{"trait_type": "Shape Color", "value": "', shapeColor, '"}'));

        otherAttributes[4] =
            string(abi.encodePacked('{"trait_type": "Lashes", "value": "', params.lashes ? "true" : "false", '"}'));

        return otherAttributes;
    }

    /**
     * @notice Generates a Base64-encoded SVG string for the avatar.
     * @param params A `SVGParams` struct containing details for avatar customization.
     * @return svg A Base64-encoded string of the avatar's SVG.
     */
    function generateBase64SVG(Genesis.SVGParams memory params) internal pure returns (string memory) {
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500">',
                '<rect width="500" height="500" fill="',
                params.bodyParams.skinColor,
                '"/>',
                '<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-size="24">',
                "BeanHeads Avatar</text>",
                "</svg>"
            )
        );

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
    }

    /**
     * @notice Appends component attributes to the existing JSON attributes string.
     * @param attributes The current JSON string of attributes.
     * @param componentAttributes An array of component attributes to be added.
     * @param isFirst A boolean indicating if this is the first attribute being added.
     * @return updatedAttributes The updated JSON string of attributes.
     */
    function concatenateAttributes(string memory attributes, string[2] memory componentAttributes, bool isFirst)
        private
        pure
        returns (string memory)
    {
        for (uint256 i; i < componentAttributes.length; ++i) {
            if (bytes(componentAttributes[i]).length > 0) {
                if (!isFirst) {
                    attributes = string(abi.encodePacked(attributes, ","));
                }
                attributes = string(abi.encodePacked(attributes, componentAttributes[i]));
                isFirst = false;
            }
        }
        return attributes;
    }

    function concatenateAttributes(string memory attributes, string[3] memory componentAttributes, bool isFirst)
        private
        pure
        returns (string memory)
    {
        for (uint256 i; i < componentAttributes.length; ++i) {
            if (bytes(componentAttributes[i]).length > 0) {
                if (!isFirst) {
                    attributes = string(abi.encodePacked(attributes, ","));
                }
                attributes = string(abi.encodePacked(attributes, componentAttributes[i]));
                isFirst = false;
            }
        }
        return attributes;
    }

    function concatenateAttributes(string memory attributes, string[5] memory componentAttributes, bool isFirst)
        private
        pure
        returns (string memory)
    {
        for (uint256 i; i < componentAttributes.length; ++i) {
            if (bytes(componentAttributes[i]).length > 0) {
                if (!isFirst) {
                    attributes = string(abi.encodePacked(attributes, ","));
                }
                attributes = string(abi.encodePacked(attributes, componentAttributes[i]));
                isFirst = false;
            }
        }
        return attributes;
    }

    function concatenateAttributes(string memory attributes, string memory componentAttributes, bool isFirst)
        private
        pure
        returns (string memory)
    {
        if (bytes(componentAttributes).length > 0) {
            if (!isFirst) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes = string(abi.encodePacked(attributes, componentAttributes));
        }
        return attributes;
    }
}
