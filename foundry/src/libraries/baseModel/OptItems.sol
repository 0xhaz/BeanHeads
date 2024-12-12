// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {SVGBody} from "src/libraries/baseModel/SVGBody.sol";

library OptItems {
    struct Items {
        bool faceMask;
        bool mask;
        bool lashes;
        bool shapes;
    }

    function faceMaskSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
             'id="face-mask" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
             string(
                abi.encodePacked(

                )
             )
        )
    }
}
