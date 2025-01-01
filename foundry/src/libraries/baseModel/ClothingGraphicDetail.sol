// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {SVGBody} from "./SVGBody.sol";
import {Errors} from "src/types/Constants.sol";
import {ClothingDetail} from "src/libraries/baseModel/ClothingDetail.sol";

library ClothingGraphicDetail {
    enum ClothingGraphicType {
        NONE,
        GATSBY,
        GRAPHQL,
        REACT,
        REDWOOD,
        VUE
    }
    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev SVG content for the Gatsby logo
    function gatsbySVG() internal pure returns (string memory) {
        return renderGatsbySVG();
    }

    /// @dev SVG content for the GraphQL logo
    function graphqlSVG() internal pure returns (string memory) {
        return renderGraphqlSVG();
    }

    /// @dev SVG content for the React logo
    function reactSVG() internal pure returns (string memory) {
        return renderReactSVG();
    }

    /// @dev SVG content for the Redwood logo
    function redwoodSVG() internal pure returns (string memory) {
        return renderRedwoodSVG();
    }

    /// @dev SVG content for the Vue logo
    function vueSVG() internal pure returns (string memory) {
        return renderVueSVG();
    }

    /// @dev Returns the SVG and name for a specific clothing graphic ID
    function getClothingGraphicById(uint8 clothes, uint8 id) internal pure returns (string memory) {
        // ClothingGraphicType graphicType = ClothingGraphicType(id);

        if (!isAllowedGraphic(clothes)) return "";

        // if (graphicType == ClothingGraphicType.NONE) return "";
        string[6] memory graphics = ["", gatsbySVG(), graphqlSVG(), reactSVG(), redwoodSVG(), vueSVG()];
        if (id >= graphics.length) revert Errors.InvalidType(id);
        return graphics[id];
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function renderGatsbySVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="gatsby" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" y="30"',
            string(
                abi.encodePacked(
                    '<path d="M500,860.85a59.07,59.07,0,1,0,59.07,59.07A59.24,59.24,0,0,0,500,860.85Zm-32.91,92a45.79,45.79,0,0,1-13.5-32.07l46,45.57C487.76,965.91,476,961.69,467.09,952.83Zm43,12.23L454.86,909.8a46.37,46.37,0,0,1,82.69-17.3L531.22,898A39,39,0,0,0,500,882a38.38,38.38,0,0,0-35.86,25.31l48.52,48.52a38.26,38.26,0,0,0,24.47-27.42H516.88v-8.44h29.53A46.54,46.54,0,0,1,510.13,965.06Z" style="fill:#663795"/>'
                )
            )
        );
    }

    function renderGraphqlSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="graphql" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"  y="30"',
            string(
                abi.encodePacked(
                    '<path d="M551.55,939.73a11.33,11.33,0,0,0-3-1.2V907.92a11.25,11.25,0,0,0,3.06-1.22,11.49,11.49,0,1,0-14.08-17.84L511,873.57a11.48,11.48,0,1,0-22.48-3.28,11.68,11.68,0,0,0,.47,3.26l-26.5,15.3a11.65,11.65,0,0,0-2.59-2.05,11.49,11.49,0,1,0-11.48,19.9,11.25,11.25,0,0,0,3.06,1.22v30.6a11.71,11.71,0,0,0-3,1.21,11.49,11.49,0,1,0,11.48,19.9,11.65,11.65,0,0,0,2.57-2L489,972.9a11.25,11.25,0,0,0-.47,3.25,11.48,11.48,0,1,0,23,0,11.68,11.68,0,0,0-.58-3.62l26.33-15.2a11.24,11.24,0,0,0,2.84,2.3,11.49,11.49,0,0,0,11.48-19.9ZM465.35,947a11.36,11.36,0,0,0-1.21-3,11.59,11.59,0,0,0-2-2.56l34.68-60.06a11.67,11.67,0,0,0,3.2.45,11.37,11.37,0,0,0,3.21-.46l34.67,60.06a11.45,11.45,0,0,0-3.23,5.6Zm69.45-53.36a11.46,11.46,0,0,0,8.26,14.28v30.65l-.44.11-34.68-60.07.3-.3Zm-43.06-15.34.33.32-34.68,60.07-.45-.12V907.89a11.45,11.45,0,0,0,8.25-14.29Zm16.75,90.14a11.5,11.5,0,0,0-16.76-.23l-26.51-15.31.12-.44h69.32c.06.25.13.51.21.75Z" style="fill:#e535ab"/>'
                )
            )
        );
    }

    function renderReactSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="react" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"  y="30"',
            string(
                abi.encodePacked(
                    '<rect x="441.15" y="860.49" width="112" height="112" style="fill:none"/>',
                    '<path d="M566.88,917.83c0-8.86-11.1-17.26-28.11-22.47,3.93-17.34,2.18-31.13-5.51-35.55a9.56,9.56,0,0,0-6.08-1.56c-8,.13-17.31,5.35-27.23,14.62C490,863.65,479,858.2,472.71,858.36c-3.16.09-4.37.52-6.16,1.56-7.67,4.41-9.38,18.18-5.43,35.47-17,5.23-28,13.61-28,22.44s11.1,17.26,28.11,22.47c-3.93,17.34-2.18,31.13,5.51,35.55a11.93,11.93,0,0,0,6.13,1.53c7.5,0,17.31-5.35,27.24-14.62,9.92,9.22,19.74,14.51,27.24,14.51a12.11,12.11,0,0,0,6.16-1.53c7.66-4.42,9.38-18.19,5.42-35.47C555.84,935.06,566.88,926.66,566.88,917.83Zm-39.72-53.49v0a6.32,6.32,0,0,1,3.1.71c3.71,2.13,5.32,10.23,4.07,20.64-.3,2.56-.79,5.26-1.39,8a133,133,0,0,0-17.32-3,132.78,132.78,0,0,0-11.34-13.63C513.16,868.87,521.49,864.35,527.16,864.34Zm-51.32,67.45q1.92,3.27,3.93,6.38c-3.87-.57-7.61-1.28-11.18-2.15,1-3.52,2.26-7.15,3.68-10.77C473.39,927.43,474.56,929.61,475.84,931.79Zm-7.33-32.15c3.57-.84,7.33-1.58,11.23-2.15-1.33,2.1-2.67,4.25-3.92,6.46s-2.43,4.36-3.55,6.54A114.8,114.8,0,0,1,468.51,899.64Zm6.95,18.27c1.69-3.65,3.6-7.31,5.65-10.88s4.3-7.17,6.57-10.41c4.06-.36,8.18-.55,12.32-.55s8.23.19,12.27.52c2.26,3.24,4.47,6.71,6.6,10.36s4,7.2,5.67,10.85c-1.72,3.66-3.6,7.31-5.65,10.88s-4.3,7.17-6.57,10.42c-4.06.35-8.18.54-12.32.54s-8.23-.19-12.27-.52c-2.26-3.24-4.47-6.7-6.6-10.36S477.18,921.56,475.46,917.91Zm48.7,13.8c1.25-2.18,2.42-4.39,3.54-6.57A114.8,114.8,0,0,1,531.46,936c-3.57.87-7.33,1.61-11.23,2.18C521.57,936.07,522.9,933.92,524.16,931.71Zm0-27.84c-1.25-2.18-2.59-4.31-3.93-6.38q5.82.85,11.18,2.15c-1,3.52-2.26,7.15-3.68,10.77C526.58,908.23,525.41,906.05,524.13,903.87ZM507.5,890.15c-2.46-.1-5-.19-7.5-.19s-5.1.06-7.58.19a105.71,105.71,0,0,1,7.5-8.72A114.37,114.37,0,0,1,507.5,890.15Zm-37.93-25a6.08,6.08,0,0,1,3.14-.71v0c5.64,0,14,4.5,22.9,12.71a129.42,129.42,0,0,0-11.26,13.6,129.07,129.07,0,0,0-17.34,3c-.63-2.72-1.09-5.37-1.42-7.9C464.31,875.43,465.89,867.33,469.57,865.18Zm-6.87,69.23c-2.7-.85-5.26-1.78-7.63-2.78-9.66-4.12-15.9-9.52-15.9-13.8s6.24-9.71,15.9-13.8c2.34-1,4.9-1.91,7.55-2.75a130.83,130.83,0,0,0,6.13,16.6A130.68,130.68,0,0,0,462.7,934.41Zm10.12,36.91a6.43,6.43,0,0,1-3.08-.73c-3.71-2.13-5.32-10.23-4.07-20.64.3-2.57.79-5.26,1.39-8a131.33,131.33,0,0,0,17.32,3,131.87,131.87,0,0,0,11.34,13.64C486.83,966.8,478.49,971.32,472.82,971.32Zm27.23-17.09a114.59,114.59,0,0,1-7.58-8.73c2.46.11,5,.19,7.5.19s5.1-.05,7.58-.19A105.91,105.91,0,0,1,500.05,954.23Zm30.38,16.25a6.08,6.08,0,0,1-3.14.71c-5.64,0-14-4.5-22.9-12.71a129.42,129.42,0,0,0,11.26-13.6,129.07,129.07,0,0,0,17.34-3,75.63,75.63,0,0,1,1.42,7.93C535.69,960.23,534.11,968.32,530.43,970.48Zm14.48-38.85c-2.35,1-4.91,1.9-7.56,2.75a131.52,131.52,0,0,0-6.13-16.61,129,129,0,0,0,6-16.52c2.7.85,5.26,1.77,7.66,2.78,9.66,4.12,15.9,9.52,15.9,13.8S554.56,927.54,544.91,931.63Z" style="fill:#61dafb"/>',
                    '<circle cx="499.97" cy="917.83" r="12.46" style="fill:#61dafb"/>'
                )
            )
        );
    }

    function renderRedwoodSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="redwood" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" y="30"',
            string(
                abi.encodePacked(
                    '<rect x="441.15" y="860.49" width="112" height="112" style="fill:none"/>',
                    '<rect x="433.91" y="856" width="132.18" height="132.18" style="fill:none"/>',
                    '<path d="M490.59,859c-4.7,2.37-14.62,7-20,10.65s-4.7,7.1-7.05,9.47-9.4,8.28-14.1,11.83-3.53,13-4.7,16.56-3.53,11.83-4.71,15.38,2.35,8.28,4.71,13,8.22,17.74,10.57,22.48,9.41,2.36,15.28,7.09a206.67,206.67,0,0,0,20,14.2c5.87,3.55,8.23,3.55,14.1,0a205.35,205.35,0,0,0,20-14.2c5.88-4.73,12.93-2.36,15.29-7.09s8.22-17.75,10.57-22.48,5.88-9.47,4.71-13-3.53-11.83-4.71-15.38,0-13-4.7-16.56a174,174,0,0,1-14.1-11.83c-4-3.77-2.35-5.92-7.06-9.47s-15.28-8.28-20-10.65A14.93,14.93,0,0,0,490.59,859Z" style="fill:#fff;fill-rule:evenodd"/>',
                    '<path d="M474,879.46l22,15a3.14,3.14,0,0,0,1.68.52,3,3,0,0,0,1.67-.52l22-15.07a3,3,0,0,0-.41-5.13l-22-10.9a3.05,3.05,0,0,0-2.64,0l-21.94,10.9a3,3,0,0,0-.36,5.18Zm31.14,19.73a3,3,0,0,0,1.3,2.49l17.64,12.06a3,3,0,0,0,3.66-.24l14.79-13.23a3,3,0,0,0-.13-4.6l-14.12-11.29a3,3,0,0,0-3.55-.14l-18.29,12.51A3,3,0,0,0,505.13,899.19Zm-43.87,16.4a3,3,0,0,1,1,2.54,3,3,0,0,1-1.49,2.29l-10.53,6.31a3,3,0,0,1-3.39-.23,3,3,0,0,1-1-3.27l3.9-12.25a3,3,0,0,1,2.05-2,2.92,2.92,0,0,1,2.78.66Zm57.13,1.28-19.05-13a3,3,0,0,0-3.34,0l-19,13a3,3,0,0,0-1.3,2.29,3.13,3.13,0,0,0,1,2.46l19,17a2.94,2.94,0,0,0,2,.75,3,3,0,0,0,2-.75l19-17a3,3,0,0,0,1-2.46A3,3,0,0,0,518.39,916.87ZM467.6,913.5l-14.78-13.23a3.07,3.07,0,0,1-1-2.37,3,3,0,0,1,1.12-2.28l14.12-11.36a3,3,0,0,1,3.57-.13l18.27,12.5a3.05,3.05,0,0,1,1.36,2.53,3,3,0,0,1-1.36,2.52l-17.62,12.06A3,3,0,0,1,467.6,913.5Zm75.88,19-15.05-9a3,3,0,0,0-3.51.34l-18.39,16.41a3,3,0,0,0,.87,5l25.51,10.34a3,3,0,0,0,3.85-1.57l7.9-17.71A3,3,0,0,0,543.48,932.51ZM545.57,911l3.89,12.25h0a3,3,0,0,1-2.86,3.93,2.91,2.91,0,0,1-1.52-.43l-10.55-6.31a2.93,2.93,0,0,1-1.44-2.29,3,3,0,0,1,1-2.54l6.69-6a3,3,0,0,1,2.77-.66A3,3,0,0,1,545.57,911Zm-55.8,32a3,3,0,0,0-1-2.76l-18.39-16.41a3,3,0,0,0-3.51-.34l-15,9a3.05,3.05,0,0,0-1.2,3.84l7.92,17.71a3,3,0,0,0,3.84,1.56l25.5-10.33A3,3,0,0,0,489.77,943Zm9,5,20.46,8.29a3,3,0,0,1,.54,5.27l-20.48,14.22a2.94,2.94,0,0,1-1.67.54,3,3,0,0,1-1.67-.54l-20.46-14.22a3,3,0,0,1,.58-5.27l20.46-8.29A3.09,3.09,0,0,1,498.79,948.06Z" style="fill:#c04927;fill-rule:evenodd"/>'
                )
            )
        );
    }

    function renderVueSVG() private pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="vue" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" y="30"',
            string(
                abi.encodePacked(
                    '<path d="M517.8,866.62l-14.4,24.94L489,866.62H441l62.36,108,62.36-108Z" style="fill:#44b783"/>',
                    '<path d="M517.8,866.62l-14.4,24.94L489,866.62H466l37.42,64.81,37.42-64.81Z" style="fill:#364a5e"/>'
                )
            )
        );
    }

    /// @dev Check if the graphic is allowed only to all type except Dress & Shirt
    function isAllowedGraphic(uint8 clothes) private pure returns (bool) {
        // Restrict graphics for `dressSVG` and `shirtSVG`
        if (clothes == 0 || clothes == 1 || clothes == 2) return false;
        return true;
    }
}
