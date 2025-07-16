// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BeanHeadsRoyalty is IERC2981, Ownable {
    error BeanHeadsRoyalty__InvalidRoyaltyFee();

    /// @notice Royalty information
    uint96 private royaltyFeeBps;
    address private royaltyReceiver;
    uint96 private constant MAX_BPS = 10000;

    event RoyaltyInfoUpdated(address indexed receiver, uint96 feeBps);

    constructor(address initialOwner, uint96 initialFeeBps) Ownable(initialOwner) {
        if (initialFeeBps >= MAX_BPS) revert BeanHeadsRoyalty__InvalidRoyaltyFee();
        royaltyFeeBps = initialFeeBps;
        royaltyReceiver = initialOwner;
    }

    /**
     * @notice Returns the royalty information for a sale
     * @param salePrice The sale price of the token
     * @return receiver The address that will receive the royalty
     * @return royaltyAmount The amount of royalty to be paid
     */
    function royaltyInfo(uint256, uint256 salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyReceiver;
        royaltyAmount = (salePrice * royaltyFeeBps) / MAX_BPS;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the royalty fee and receiver
     * @param feeBps The royalty fee in basis points (1% = 100 BPS)
     */
    function setRoyaltyInfo(uint96 feeBps) external onlyOwner {
        if (feeBps >= MAX_BPS) revert BeanHeadsRoyalty__InvalidRoyaltyFee();

        royaltyFeeBps = feeBps;

        emit RoyaltyInfoUpdated(royaltyReceiver, royaltyFeeBps);
    }

    /*//////////////////////////////////////////////////////////////
                               INTERFACE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Supports interface detection.
     * @param interfaceId The interface identifier.
     * @return True if supported.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId;
    }
}
