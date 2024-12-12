// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {SVGBody} from "src/libraries/SVGBody.sol";

library BodyDetail {
    error BodyDetail__InvalidBodyType();

    string constant BREAST = "Breast";
    string constant CHEST = "Chest";

    struct Body {
        string name;
        string svg;
    }

    /// @dev SVG content
    function breastSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="breast" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M426.88,961.63a69.32,69.32,0,0,0,65.62-47,71,71,0,0,1-118.19,6.64L374.26,936C387,951.63,405.15,961.63,426.88,961.63Z" style="opacity:.05"/>',
                    '<path d="M573.12,961.63a69.32,69.32,0,0,1-65.62-47,71,71,0,0,0,118.19,6.64l0,14.72C613,951.63,594.85,961.63,573.12,961.63Z" style="opacity:.05"/>',
                    '<path d="M494.47,852.86a37.23,37.23,0,0,1,6,12.13,48.61,48.61,0,0,1,.15,27,37.23,37.23,0,0,1-5.93,12.19c.43-4.53,1-8.8,1.29-13.05s.5-8.43.48-12.63-.22-8.39-.6-12.63S495,857.38,494.47,852.86Z" style="fill:#592d3d"/>',
                    '<path d="M505.76,852.29c-.93,5.5-1.74,10.77-2.1,16a103.31,103.31,0,0,0,2.43,31.17c1.19,5.15,2.8,10.23,4.57,15.53A44.76,44.76,0,0,1,501.6,901,55,55,0,0,1,499,867.6,44.61,44.61,0,0,1,505.76,852.29Z" style="fill:#592d3d"/>',
                    '<path d="M407,943.81A69.33,69.33,0,0,1,380.42,831.7" style="fill:#fff"/>',
                    '<path d="M407,943.81a57.14,57.14,0,0,1-31.21-16l-1.62-1.6c-.53-.54-1-1.13-1.53-1.69s-1-1.15-1.48-1.73a22,22,0,0,1-1.43-1.79c-.9-1.23-1.81-2.46-2.68-3.72l-2.37-3.93a69,69,0,0,1-6.71-17.13,70.52,70.52,0,0,1-1.69-18.3,64.09,64.09,0,0,1,3.4-17.93c.26-.71.49-1.43.76-2.14l.88-2.1c.55-1.4,1.26-2.74,1.91-4.09a60.79,60.79,0,0,1,4.74-7.63c.85-1.21,1.82-2.35,2.75-3.49s1.94-2.23,3-3.23a47.65,47.65,0,0,1,6.73-5.59c-5.79,10-9.9,20.19-11.66,30.67A78.09,78.09,0,0,0,367.61,878a84.63,84.63,0,0,0,2,15.41,80.81,80.81,0,0,0,5.12,14.65,76.2,76.2,0,0,0,8.08,13.47,79,79,0,0,0,10.81,11.95A115,115,0,0,0,407,943.81Z" style="fill:#592d3d"/>',
                    '<path d="M593.05,943.81A69.33,69.33,0,0,0,619.58,831.7" style="fill:#fff"/>',
                    '<path d="M593.05,943.81a115,115,0,0,0,13.35-10.29,79,79,0,0,0,10.81-11.95,76.2,76.2,0,0,0,8.08-13.47,80.81,80.81,0,0,0,5.12-14.65,84.63,84.63,0,0,0,2-15.41,78.09,78.09,0,0,0-1.15-15.67c-1.76-10.48-5.87-20.64-11.66-30.67a47.65,47.65,0,0,1,6.73,5.59c1.08,1,2,2.14,3,3.23s1.9,2.28,2.75,3.49a60.79,60.79,0,0,1,4.74,7.63c.65,1.35,1.36,2.69,1.91,4.09l.88,2.1c.27.71.5,1.43.76,2.14a64.09,64.09,0,0,1,3.4,17.93,70.52,70.52,0,0,1-1.69,18.3,69,69,0,0,1-6.71,17.13L633,917.26c-.87,1.26-1.78,2.49-2.68,3.72a22,22,0,0,1-1.43,1.79c-.49.58-1,1.16-1.48,1.73s-1,1.15-1.53,1.69l-1.62,1.6A57.14,57.14,0,0,1,593.05,943.81Z" style="fill:#592d3d"/>'
                )
            )
        );
    }

    function chestSVG() internal pure returns (string memory) {
        return SVGBody.fullSVG(
            'id="chest" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"',
            string(
                abi.encodePacked(
                    '<path d="M610,758.72c90.76,0,72,114.24,72.87,241.28H610Z" style="fill:#fdd2b2"/>',
                    '<path d="M632.74,831.87,610,870l11.38,130h31.76C653.91,819.73,632.74,831.87,632.74,831.87Z" style="fill:#f3ab98"/>',
                    '<path d="M233.25,500c0-147.32,119.43-266.75,266.75-266.75S766.75,352.68,766.75,500A266.22,266.22,0,0,1,668.1,707.12q-8.21,6.68-16.94,12.69C591,758,515,758,446.39,751.89c-6.66-1-13.3-2.26-19.89-3.71-26.33-5.8-51.82-14.75-75.37-27.8Q342.4,715,334.2,708.76a199.59,199.59,0,0,1-15.8-13.38q-7.14-6.63-13.79-13.78A265.86,265.86,0,0,1,233.25,500Z" style="fill:#fdd2b2"/>',
                    '<path d="M269.61,634.48c.7,1.2,1.39,2.4,2.11,3.58.43.72.88,1.42,1.33,2.14.66,1.07,1.32,2.14,2,3.19.48.76,1,1.5,1.46,2.24.66,1,1.32,2,2,3,.51.76,1,1.52,1.56,2.28.66,1,1.32,1.92,2,2.88.54.77,1.1,1.53,1.65,2.3s1.34,1.85,2,2.77,1.15,1.53,1.73,2.29,1.37,1.8,2.07,2.7,1.19,1.51,1.79,2.26,1.41,1.76,2.12,2.63,1.23,1.49,1.85,2.23,1.44,1.72,2.17,2.57,1.27,1.47,1.91,2.2l2.22,2.5c.65.73,1.31,1.44,2,2.16.86.94,1.73,1.87,2.6,2.79l1.21,1.28c1.29,1.34,2.59,2.68,3.91,4l.26.27c1.29,1.28,2.6,2.55,3.91,3.81l1.58,1.5c.95.89,1.9,1.78,2.86,2.66l1.16,1.06c1,.94,2.09,1.86,3.14,2.78q4.9,4.27,10,8.19,8.19,6.24,16.93,11.62c23.55,13,49,22,75.37,27.8,6.59,1.45,13.23,2.7,19.89,3.71,42.1,3.75,87,5.18,129.28-3.08C508.45,729,185.59,612.74,388.8,257.48h0c-2.72,1.25-5.4,2.54-8.06,3.88l-.59.29c-1.22.61-2.44,1.24-3.65,1.88l-1,.53c-3.76,2-7.48,4.07-11.13,6.23l-.9.53c-1.16.69-2.31,1.39-3.46,2.1l-.87.54q-5.36,3.35-10.55,6.93l-1.08.75c-1.09.76-2.16,1.52-3.23,2.29l-.66.47q-3.27,2.39-6.46,4.84l-.62.48c-1,.78-2,1.58-3,2.39l-1.17.94c-1,.81-2,1.62-3,2.45l0,0c-2.11,1.75-4.19,3.55-6.24,5.37l-1.14,1-2.69,2.45L318,305q-4.28,4-8.37,8.17l-1.38,1.41c-.79.82-1.58,1.64-2.36,2.47-.46.49-.92,1-1.37,1.48q-2.06,2.2-4.06,4.46c-.45.51-.91,1-1.36,1.54-.71.81-1.41,1.63-2.11,2.45l-1.51,1.79c-.68.81-1.36,1.62-2,2.44-.54.66-1.08,1.33-1.61,2-1.07,1.33-2.12,2.66-3.16,4-.54.7-1.08,1.4-1.61,2.11s-1.2,1.59-1.79,2.4-1.07,1.45-1.59,2.18-1.13,1.55-1.68,2.33q-1.42,2-2.8,4.05c-.5.73-1,1.48-1.49,2.22s-1.1,1.66-1.64,2.5l-1.49,2.31-1.68,2.71c-.43.69-.86,1.38-1.28,2.07-.89,1.46-1.75,2.93-2.61,4.4l-1.22,2.16c-.54.95-1.08,1.91-1.61,2.87-.4.73-.8,1.46-1.19,2.19-.64,1.19-1.27,2.39-1.9,3.59l-1.2,2.34c-.64,1.28-1.28,2.55-1.91,3.84-.33.69-.67,1.39-1,2.09-.52,1.09-1,2.19-1.53,3.29-.31.66-.61,1.32-.91,2q-1.11,2.47-2.17,5c-.22.52-.43,1.05-.65,1.57-.53,1.27-1.05,2.54-1.56,3.82-.27.67-.53,1.34-.79,2-.5,1.26-1,2.53-1.45,3.8-.21.55-.42,1.1-.62,1.65q-.94,2.63-1.85,5.26l-.56,1.7q-.66,2-1.29,4l-.6,1.91c-.47,1.54-.93,3.08-1.37,4.63-.1.33-.2.66-.29,1q-.78,2.76-1.5,5.54c-.16.59-.3,1.19-.45,1.78-.35,1.39-.69,2.78-1,4.18l-.42,1.75c-.43,1.9-.85,3.8-1.24,5.71l-.15.77q-.51,2.55-1,5.1c-.11.61-.21,1.21-.32,1.82-.26,1.49-.51,3-.74,4.5-.08.51-.17,1-.24,1.52-.3,1.95-.57,3.91-.83,5.88l-.15,1.3c-.2,1.59-.38,3.19-.55,4.79-.06.6-.13,1.2-.19,1.81-.16,1.68-.31,3.37-.45,5.06,0,.35-.06.69-.08,1q-.22,3-.39,6.05c0,.53,0,1.07-.07,1.6q-.1,2.36-.18,4.71c0,.59,0,1.18,0,1.77,0,2.05-.08,4.11-.08,6.17,0,0,0,.07,0,.1,0,2.22,0,4.42.08,6.62,0,.76.06,1.52.08,2.28.05,1.47.1,2.94.17,4.41,0,.89.11,1.77.16,2.66.08,1.33.15,2.66.25,4,.07,1,.16,1.89.24,2.83.11,1.26.21,2.52.34,3.77.09,1,.21,1.94.31,2.91.14,1.21.27,2.43.42,3.64.12,1,.26,2,.39,2.95.16,1.18.32,2.37.5,3.55.15,1,.31,2,.47,3,.18,1.16.37,2.33.57,3.49.18,1,.36,2,.55,3,.21,1.15.43,2.3.65,3.44s.41,2,.62,3c.24,1.14.48,2.27.74,3.4s.44,2,.68,2.93c.26,1.13.54,2.25.82,3.36s.49,1.95.74,2.91c.3,1.12.6,2.23.91,3.34.26,1,.53,1.92.81,2.87.32,1.11.65,2.21,1,3.31s.58,1.89.88,2.84.7,2.19,1.06,3.28.62,1.87.94,2.8c.38,1.09.76,2.18,1.15,3.27.33.91.65,1.83,1,2.74l1.24,3.27c.35.89.69,1.79,1,2.68.44,1.09.89,2.19,1.34,3.28.36.86.71,1.73,1.08,2.59.47,1.12,1,2.22,1.45,3.33.37.82.73,1.65,1.1,2.47.52,1.16,1.07,2.3,1.6,3.44l1.08,2.3c.61,1.26,1.24,2.5,1.87,3.75.32.63.62,1.27.95,1.9q2.88,5.61,6,11.07C268.88,633.26,269.25,633.87,269.61,634.48Z" style="fill:#f3ab98"/>',
                    '<path d="M233.25,500c0-147.32,119.43-266.75,266.75-266.75S766.75,352.68,766.75,500A266.22,266.22,0,0,1,668.1,707.12q-8.21,6.68-16.94,12.69C591,758,515,758,446.39,751.89c-6.66-1-13.3-2.26-19.89-3.71-26.33-5.8-51.82-14.75-75.37-27.8Q342.4,715,334.2,708.76a199.59,199.59,0,0,1-15.8-13.38q-7.14-6.63-13.79-13.78A265.86,265.86,0,0,1,233.25,500Z" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M386.12,758.72c-90.77,0-72,114.24-72.87,241.28h72.87Z" style="fill:#fdd2b2"/>',
                    '<path d="M367.23,831.87,390,870l-11.39,130H346.88C346.07,819.73,367.23,831.87,367.23,831.87Z" style="fill:#f3ab98"/>',
                    '<path d="M619.47,1070H380.53a13.28,13.28,0,0,1-13.27-13.28V772a13.28,13.28,0,0,1,13.27-13.28H613.76c13.09,0,19,7.66,19,19.88v278.08A13.28,13.28,0,0,1,619.47,1070Z" style="fill:#fdd2b2"/>',
                    '<path d="M629.05,766.62a19.33,19.33,0,0,1-2.51-4,17.25,17.25,0,0,0-8.28-3.51,28.88,28.88,0,0,0-4.5-.34H380.53A13.28,13.28,0,0,0,367.26,772c29,10.42,83.29,16.24,132.74,16.24C563.06,788.24,604.38,778.89,629.05,766.62Z" style="fill:#f3ab98"/>',
                    '<path d="M610,758.72c90.76,0,72,114.24,72.87,241.28H632.74" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M386.12,758.72c-90.77,0-72,114.24-72.87,241.28h50.07" style="fill:none;stroke:#592d3d;stroke-linecap:square;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M570.68,842.45C570.9,833,582.9,829,588.9,835a10.61,10.61,0,1,1-15.16,14.85A10.4,10.4,0,0,1,570.68,842.45Z" style="fill:#592d3d"/>',
                    '<path d="M408.11,842.15C407.9,834,416.9,830,422.9,833c8,3,8,14,0,19-4,2-8,0-11.75-2.48A10.39,10.39,0,0,1,408.11,842.15Z" style="fill:#592d3d"/>',
                    '<path d="M380.53,758.82l233.23-.1" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M380.53,1070H497.15C388,1070,396.24,838.82,367.26,838.82v217.86A13.28,13.28,0,0,0,380.53,1070Z" style="fill:#f3ab98"/>',
                    '<path d="M361.26,860.85c-.19-3.67-.11-7.34.05-11s.47-7.35.86-11c.2-1.84.4-3.67.65-5.51s.49-3.67.85-5.51a44.18,44.18,0,0,1,3.59-11,44.18,44.18,0,0,1,3.59,11c.36,1.84.62,3.67.85,5.51s.45,3.67.65,5.51c.38,3.67.68,7.34.85,11s.25,7.34.06,11Z" style="fill:#592d3d"/>',
                    '<path d="M632.74,870v8c.26,34,.26,69,0,102.75,0,2.87,0,5.72,0,8.53v67.41A13.28,13.28,0,0,1,619.47,1070H380.53a13.28,13.28,0,0,1-13.27-13.28V998.52c0-2.51,0-5.07,0-7.65-.25-34.87-.25-69.87,0-105.3V860.85" style="fill:none;stroke:#592d3d;stroke-miterlimit:10;stroke-width:12px"/>',
                    '<path d="M626.74,870c-.19-4.17-.1-8.35.06-12.53s.47-8.35.85-12.53c.2-2.09.41-4.18.65-6.27s.49-4.17.85-6.26a55.09,55.09,0,0,1,3.59-12.53,55.09,55.09,0,0,1,3.59,12.53c.36,2.09.62,4.18.85,6.26s.45,4.18.65,6.27c.38,4.18.69,8.35.85,12.53s.25,8.36.06,12.53Z" style="fill:#592d3d"/>',
                    '<path d="M500,831.77a27.13,27.13,0,0,1,1.5,5.84,42.47,42.47,0,0,1,.49,5.84l.3,11.69c.09,3.89.21,7.79.25,11.69l.17,11.67c.23,15.57.22,31.16.28,46.74s.18,31.16,0,46.74c-.09,7.79-.3,15.58-.53,23.37-.1,3.89-.29,7.79-.67,11.68a92.5,92.5,0,0,1-1.77,11.69,92.5,92.5,0,0,1-1.77-11.69c-.38-3.89-.57-7.79-.67-11.68-.23-7.79-.44-15.58-.53-23.37-.2-15.58,0-31.16,0-46.74s0-31.15.18-46.73l.17-11.7.33-11.68.33-11.68a44.11,44.11,0,0,1,.5-5.84A27.13,27.13,0,0,1,500,831.77Z" style="fill:#f3ab98"/>',
                    '<path d="M425.22,883a18.51,18.51,0,0,1,4.67-1.5,29.75,29.75,0,0,1,4.68-.5l9.35-.33,18.7-.41c12.46-.19,24.91-.24,37.38-.27s24.93-.16,37.39,0c6.23.09,12.46.3,18.7.53,3.11.11,6.23.3,9.34.67a61.34,61.34,0,0,1,9.35,1.78,59.17,59.17,0,0,1-9.35,1.77c-3.11.38-6.23.57-9.34.67-6.24.23-12.47.43-18.7.52-12.46.19-24.92,0-37.39,0s-24.93,0-37.4-.15c-6.23-.06-12.46-.26-18.68-.5l-9.35-.34a29.5,29.5,0,0,1-4.67-.5A18.45,18.45,0,0,1,425.22,883Z" style="fill:#f3ab98"/>',
                    '<path d="M442.41,914.38a12.51,12.51,0,0,1,3.74-1.11,18.35,18.35,0,0,1,3.62-.15c2.39.1,4.78.16,7.17.21,4.78.11,9.56.15,14.34.17,9.63,0,19.09.08,28.76-.21s19.26-.43,28.88-.39c4.81,0,9.62.13,14.42.24a70.37,70.37,0,0,1,7.23.47,38.17,38.17,0,0,1,7.27,1.53,36.56,36.56,0,0,1-7.16,2,61.08,61.08,0,0,1-7.21.86c-4.82.35-9.64.65-14.45.82-9.64.36-19.27.32-28.88.45-4.81,0-9.61.22-14.48.1s-9.69-.13-14.52-.31-9.68-.58-14.5-1.08c-2.42-.27-4.82-.57-7.23-.9a16.82,16.82,0,0,1-3.57-.84A11.51,11.51,0,0,1,442.41,914.38Z" style="fill:#f3ab98"/>',
                    '<path d="M438.93,949.87a13.07,13.07,0,0,1,3.82-1.5,19.13,19.13,0,0,1,3.82-.49l7.63-.32c5.09-.18,10.19-.33,15.28-.41C479.66,947,489.84,947,500,947s20.36-.17,30.54,0c5.09.09,10.18.3,15.27.53a72.73,72.73,0,0,1,7.63.66A41.2,41.2,0,0,1,561.1,950a41.25,41.25,0,0,1-7.63,1.77,70.34,70.34,0,0,1-7.64.67c-5.09.23-10.18.44-15.27.53-10.18.2-20.37.06-30.55,0s-20.36-.06-30.54-.25c-5.09-.1-10.19-.28-15.28-.49l-7.63-.37a19.33,19.33,0,0,1-3.82-.5A12.85,12.85,0,0,1,438.93,949.87Z" style="fill:#f3ab98"/>'
                )
            )
        );
    }

    /// @dev Returns the SVG and name for a specific body ID
    function getBodyById(uint8 id) internal pure returns (Body memory) {
        if (id == 1) {
            return Body({name: BREAST, svg: breastSVG()});
        } else if (id == 2) {
            return Body({name: CHEST, svg: chestSVG()});
        } else {
            revert BodyDetail__InvalidBodyType();
        }
    }
}
