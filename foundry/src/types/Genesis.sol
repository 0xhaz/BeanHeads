// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

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
    using Strings for uint256;

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
        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">';

        svg = string(abi.encodePacked(svg, buildShapes(params.otherParams)));
        svg = string(abi.encodePacked(svg, buildHairBack(params.hairParams)));
        svg = string(abi.encodePacked(svg, buildBody(params.bodyParams, params.clothingParams)));
        svg = string(abi.encodePacked(svg, buildHairFront(params.hairParams)));
        svg = string(abi.encodePacked(svg, buildClothes(params.bodyParams, params.clothingParams)));
        svg = string(abi.encodePacked(svg, buildHair(params.hairParams)));
        svg = string(abi.encodePacked(svg, buildClothingGraphic(params.clothingParams)));
        svg = string(abi.encodePacked(svg, buildEyes(params.facialFeaturesParams, params.bodyParams)));
        svg = string(abi.encodePacked(svg, buildFacialHair(params.facialFeaturesParams)));
        svg = string(abi.encodePacked(svg, buildHat(params.accessoryParams, params.hairParams)));
        svg = string(abi.encodePacked(svg, buildMouth(params.facialFeaturesParams)));
        svg = string(abi.encodePacked(svg, buildEyebrows(params.facialFeaturesParams)));
        svg = string(abi.encodePacked(svg, buildAccessory(params.accessoryParams)));
        svg = string(abi.encodePacked(svg, buildFaceMask(params.otherParams)));
        svg = string(abi.encodePacked(svg, buildLashes(params.facialFeaturesParams, params.otherParams)));

        svg = string(abi.encodePacked(svg, "</svg>"));
        return svg;
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE FUNCTION
    //////////////////////////////////////////////////////////////*/

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
    function buildAttributes(SVGParams memory params, uint256 generation) internal pure returns (string memory) {
        string memory attributes = "[";
        bool isFirst = true;

        // Hair Attributes
        attributes = appendHairAttributes(attributes, params.hairParams, isFirst);
        isFirst = isFirst && bytes(HairDetail.getHairTypeName(params.hairParams.hairStyle)).length == 0
            && bytes(HairDetail.getHairColorName(params.hairParams.hairColor)).length == 0;

        // Accessory Attributes
        attributes = appendAccessoryAttributes(attributes, params.accessoryParams, isFirst);
        isFirst = isFirst && bytes(AccessoryDetail.getAccessoryName(params.accessoryParams.accessoryId)).length == 0
            && bytes(HatsDetail.getHatsName(params.accessoryParams.hatStyle)).length == 0
            && bytes(HatsDetail.getHatsColorName(params.accessoryParams.hatColor)).length == 0;

        // Body Attributes
        attributes = appendBodyAttributes(attributes, params.bodyParams, isFirst);
        isFirst = isFirst && bytes(BodyDetail.getBodyTypeName(params.bodyParams.bodyType)).length == 0
            && bytes(BodyDetail.getBodyColorName(params.bodyParams.skinColor)).length == 0;

        // Clothing Attributes
        attributes = appendClothingAttributes(attributes, params.clothingParams, isFirst);
        isFirst = isFirst && bytes(ClothingDetail.getClothingName(params.clothingParams.clothes)).length == 0
            && bytes(ClothingDetail.getClothingColor(params.clothingParams.clothingColor)).length == 0
            && bytes(ClothingGraphicDetail.getClothingGraphicName(params.clothingParams.clothesGraphic)).length == 0;

        // Facial Features Attributes
        attributes = appendFacialFeaturesAttributes(attributes, params.facialFeaturesParams, isFirst);
        isFirst = isFirst && bytes(EyebrowDetail.getEyebrowName(params.facialFeaturesParams.eyebrowShape)).length == 0
            && bytes(EyesDetail.getEyeName(params.facialFeaturesParams.eyeShape)).length == 0
            && bytes(FacialHairDetail.getFacialHairName(params.facialFeaturesParams.facialHairType)).length == 0
            && bytes(MouthDetail.getMouthName(params.facialFeaturesParams.mouthStyle)).length == 0
            && (
                params.facialFeaturesParams.mouthStyle != 1
                    || bytes(MouthDetail.getMouthColor(params.facialFeaturesParams.lipColor)).length == 0
            );

        // Optional Attributes (Face Mask, Shapes, Lashes)
        if (params.otherParams.faceMask) {
            if (!isFirst) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type": "Face Mask", "value": "true"},',
                    '{"trait_type": "Face Mask Color", "value": "',
                    OptItems.getFaceMaskColor(params.otherParams.faceMaskColor),
                    '"}'
                )
            );
            isFirst = false;
        }

        if (params.otherParams.shapes) {
            if (!isFirst) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type": "Shapes", "value": "true"},',
                    '{"trait_type": "Shape Color", "value": "',
                    OptItems.getShapeColor(params.otherParams.shapeColor),
                    '"}'
                )
            );
            isFirst = false;
        }

        if (params.otherParams.lashes) {
            if (!isFirst) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes = string(abi.encodePacked(attributes, '{"trait_type": "Lashes", "value": "true"}'));
            isFirst = false;
        }

        if (!isFirst) {
            attributes = string(abi.encodePacked(attributes, ","));
        }

        attributes =
            string(abi.encodePacked(attributes, '{"trait_type": "Generation", "value": "', generation.toString(), '"}'));

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

    /**
     * @notice Appends hair attributes to the JSON string.
     * @param attributes The current JSON string.
     * @param params Hair parameters.
     * @param isFirst Indicates if this is the first attribute set.
     * @return Updated JSON string.
     */
    function appendHairAttributes(string memory attributes, HairParams memory params, bool isFirst)
        private
        pure
        returns (string memory)
    {
        string memory hairStyleName = HairDetail.getHairTypeName(params.hairStyle);
        if (bytes(hairStyleName).length > 0) {
            if (!isFirst) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes =
                string(abi.encodePacked(attributes, '{"trait_type": "Hair Style", "value": "', hairStyleName, '"}'));
        }

        string memory hairColorName = HairDetail.getHairColorName(params.hairColor);
        if (bytes(hairColorName).length > 0) {
            if (!isFirst || bytes(hairStyleName).length > 0) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes =
                string(abi.encodePacked(attributes, '{"trait_type": "Hair Color", "value": "', hairColorName, '"}'));
        }

        return attributes;
    }

    /**
     * @notice Appends accessory attributes to the JSON string.
     * @param attributes The current JSON string.
     * @param params Accessory parameters.
     * @param isFirst Indicates if this is the first attribute set.
     * @return Updated JSON string.
     */
    function appendAccessoryAttributes(string memory attributes, AccessoryParams memory params, bool isFirst)
        private
        pure
        returns (string memory)
    {
        string memory accessoryName = AccessoryDetail.getAccessoryName(params.accessoryId);
        if (bytes(accessoryName).length > 0) {
            if (!isFirst) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes =
                string(abi.encodePacked(attributes, '{"trait_type": "Accessory", "value": "', accessoryName, '"}'));
        }

        string memory hatName = HatsDetail.getHatsName(params.hatStyle);
        if (bytes(hatName).length > 0) {
            if (!isFirst || bytes(accessoryName).length > 0) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes = string(abi.encodePacked(attributes, '{"trait_type": "Hat Style", "value": "', hatName, '"}'));
        }

        string memory hatColorName = HatsDetail.getHatsColorName(params.hatColor);
        if (bytes(hatColorName).length > 0) {
            if (!isFirst || bytes(accessoryName).length > 0 || bytes(hatName).length > 0) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes =
                string(abi.encodePacked(attributes, '{"trait_type": "Hat Color", "value": "', hatColorName, '"}'));
        }

        return attributes;
    }

    /**
     * @notice Appends body attributes to the JSON string.
     * @param attributes The current JSON string.
     * @param params Body parameters.
     * @param isFirst Indicates if this is the first attribute set.
     * @return Updated JSON string.
     */
    function appendBodyAttributes(string memory attributes, BodyParams memory params, bool isFirst)
        private
        pure
        returns (string memory)
    {
        string memory bodyTypeName = BodyDetail.getBodyTypeName(params.bodyType);
        if (bytes(bodyTypeName).length > 0) {
            if (!isFirst) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes =
                string(abi.encodePacked(attributes, '{"trait_type": "Body Type", "value": "', bodyTypeName, '"}'));
        }

        string memory skinColorName = BodyDetail.getBodyColorName(params.skinColor);
        if (bytes(skinColorName).length > 0) {
            if (!isFirst || bytes(bodyTypeName).length > 0) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes =
                string(abi.encodePacked(attributes, '{"trait_type": "Skin Color", "value": "', skinColorName, '"}'));
        }

        return attributes;
    }

    /**
     * @notice Appends clothing attributes to the JSON string.
     * @param attributes The current JSON string.
     * @param params Clothing parameters.
     * @param isFirst Indicates if this is the first attribute set.
     *	Output: Updated JSON string.
     */
    function appendClothingAttributes(string memory attributes, ClothingParams memory params, bool isFirst)
        private
        pure
        returns (string memory)
    {
        string memory clothesName = ClothingDetail.getClothingName(params.clothes);
        if (bytes(clothesName).length > 0) {
            if (!isFirst) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes = string(abi.encodePacked(attributes, '{"trait_type": "Clothes", "value": "', clothesName, '"}'));
        }

        string memory clothesColorName = ClothingDetail.getClothingColor(params.clothingColor);
        if (bytes(clothesColorName).length > 0) {
            if (!isFirst || bytes(clothesName).length > 0) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes = string(
                abi.encodePacked(attributes, '{"trait_type": "Clothes Color", "value": "', clothesColorName, '"}')
            );
        }

        string memory clothingGraphicName = ClothingGraphicDetail.getClothingGraphicName(params.clothesGraphic);
        if (bytes(clothingGraphicName).length > 0) {
            if (!isFirst || bytes(clothesName).length > 0 || bytes(clothesColorName).length > 0) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes = string(
                abi.encodePacked(attributes, '{"trait_type": "Clothes Graphic", "value": "', clothingGraphicName, '"}')
            );
        }

        return attributes;
    }

    /**
     * @notice Appends facial features attributes to the JSON string.
     * @param attributes The current JSON string.
     * @param params Facial features parameters.
     * @param isFirst Indicates if this is the first attribute set.
     * @return Updated JSON string.
     */
    function appendFacialFeaturesAttributes(string memory attributes, FacialFeaturesParams memory params, bool isFirst)
        private
        pure
        returns (string memory)
    {
        string memory eyebrowShapeName = EyebrowDetail.getEyebrowName(params.eyebrowShape);
        if (bytes(eyebrowShapeName).length > 0) {
            if (!isFirst) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes = string(
                abi.encodePacked(attributes, '{"trait_type": "Eyebrow Shape", "value": "', eyebrowShapeName, '"}')
            );
        }

        string memory eyeName = EyesDetail.getEyeName(params.eyeShape);
        if (bytes(eyeName).length > 0) {
            if (!isFirst || bytes(eyebrowShapeName).length > 0) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes = string(abi.encodePacked(attributes, '{"trait_type": "Eye Shape", "value": "', eyeName, '"}'));
        }

        string memory facialHairName = FacialHairDetail.getFacialHairName(params.facialHairType);
        if (bytes(facialHairName).length > 0) {
            if (!isFirst || bytes(eyebrowShapeName).length > 0 || bytes(eyeName).length > 0) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes = string(
                abi.encodePacked(attributes, '{"trait_type": "Facial Hair Type", "value": "', facialHairName, '"}')
            );
        }

        string memory mouthStyleName = MouthDetail.getMouthName(params.mouthStyle);
        if (bytes(mouthStyleName).length > 0) {
            if (
                !isFirst || bytes(eyebrowShapeName).length > 0 || bytes(eyeName).length > 0
                    || bytes(facialHairName).length > 0
            ) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
            attributes =
                string(abi.encodePacked(attributes, '{"trait_type": "Mouth Style", "value": "', mouthStyleName, '"}'));
        }

        if (params.mouthStyle == 1) {
            string memory lipColorName = MouthDetail.getMouthColor(params.lipColor);
            if (bytes(lipColorName).length > 0) {
                if (
                    !isFirst || bytes(eyebrowShapeName).length > 0 || bytes(eyeName).length > 0
                        || bytes(facialHairName).length > 0 || bytes(mouthStyleName).length > 0
                ) {
                    attributes = string(abi.encodePacked(attributes, ","));
                }
                attributes =
                    string(abi.encodePacked(attributes, '{"trait_type": "Lip Color", "value": "', lipColorName, '"}'));
            }
        }

        return attributes;
    }

    /**
     * @notice Builds the SVG string for shapes, hair back, hair front, body, clothes, hair, clothing graphic,
     *         eyes, facial hair, hat, mouth, eyebrows, accessory, face mask, and lashes.
     * @param p Other parameters including shapes and face mask.
     * @return shapeSVG The SVG string for shapes.
     */
    function buildShapes(OtherParams memory p) private pure returns (string memory) {
        (string memory shapeSVG,) = isShapesOn(p.shapes, p.shapeColor);
        return shapeSVG;
    }

    function buildHairBack(HairParams memory p) private pure returns (string memory) {
        (string memory back,) = getHairComponentsById(p.hairStyle, p.hairColor);
        return back;
    }

    function buildHairFront(HairParams memory p) private pure returns (string memory) {
        (, string memory front) = getHairComponentsById(p.hairStyle, p.hairColor);
        return front;
    }

    function buildBody(BodyParams memory b, ClothingParams memory c) private pure returns (string memory) {
        (string memory bodySVG,) = BodyDetail.getBodyById(b.bodyType, b.skinColor, c.clothingColor);
        return bodySVG;
    }

    function buildClothes(BodyParams memory b, ClothingParams memory c) private pure returns (string memory) {
        (string memory clothesSVG,) = ClothingDetail.getClothingById(b.bodyType, c.clothes, c.clothingColor);
        return clothesSVG;
    }

    function buildHair(HairParams memory p) private pure returns (string memory) {
        (string memory hairSVG,) = HairDetail.getHairById(p.hairStyle, p.hairColor);
        return hairSVG;
    }

    function buildClothingGraphic(ClothingParams memory p) private pure returns (string memory) {
        (string memory svg,) = ClothingGraphicDetail.getClothingGraphicById(p.clothes, p.clothesGraphic);
        return svg;
    }

    function buildEyes(FacialFeaturesParams memory f, BodyParams memory b) private pure returns (string memory) {
        (string memory svg,) = EyesDetail.getEyeById(f.eyeShape, b.skinColor);
        return svg;
    }

    function buildFacialHair(FacialFeaturesParams memory f) private pure returns (string memory) {
        (string memory svg,) = FacialHairDetail.getFacialHairById(f.facialHairType);
        return svg;
    }

    function buildHat(AccessoryParams memory a, HairParams memory h) private pure returns (string memory) {
        (string memory svg,) = HatsDetail.getHatsById(a.hatStyle, a.hatColor, h.hairStyle);
        return svg;
    }

    function buildMouth(FacialFeaturesParams memory f) private pure returns (string memory) {
        (string memory svg,) = MouthDetail.getMouthById(f.mouthStyle, f.lipColor);
        return svg;
    }

    function buildEyebrows(FacialFeaturesParams memory f) private pure returns (string memory) {
        (string memory svg,) = EyebrowDetail.getEyebrowById(f.eyebrowShape);
        return svg;
    }

    function buildAccessory(AccessoryParams memory a) private pure returns (string memory) {
        (string memory svg,) = AccessoryDetail.getAccessoryById(a.accessoryId);
        return svg;
    }

    function buildFaceMask(OtherParams memory p) private pure returns (string memory) {
        (string memory svg,) = isFaceMaskOn(p.faceMask, p.faceMaskColor);
        return svg;
    }

    function buildLashes(FacialFeaturesParams memory f, OtherParams memory o) private pure returns (string memory) {
        return isLashesOn(f.eyeShape, o.lashes);
    }
}
