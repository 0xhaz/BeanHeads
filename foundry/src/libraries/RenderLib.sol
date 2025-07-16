// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Genesis} from "src/types/Genesis.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

library RenderLib {
    using Strings for uint256;
    using Base64 for bytes;

    /**
     * @notice Build base64-encoded metadata JSON for the given token
     * @param tokenId The token ID
     * @param params The SVG parameters
     * @param generation The generation number
     * @return metadataURI A data:application/json;base64 string
     */
    function buildMetadata(uint256 tokenId, Genesis.SVGParams memory params, uint256 generation)
        internal
        pure
        returns (string memory metadataURI)
    {
        string memory attributes = Genesis.buildAttributes(params, generation);
        string memory image = Genesis.generateBase64SVG(params);

        string memory metadataJson = string(
            abi.encodePacked(
                '{"name":"BeanHeads #',
                tokenId.toString(),
                '","description":"BeanHeads is a customizable avatar on-chain NFT collection","image":"',
                image,
                '","attributes":',
                attributes,
                "}"
            )
        );

        metadataURI = string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadataJson))));
    }
}
