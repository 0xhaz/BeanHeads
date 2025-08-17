// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC173} from "src/interfaces/IERC173.sol";
import {BHStorage} from "src/libraries/BHStorage.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        BHStorage.enforceContractOwner();
        address previousOwner = BHStorage.contractOwner();
        BHStorage.diamondStorage().owner = _newOwner;

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function owner() external view override returns (address) {
        return BHStorage.contractOwner();
    }
}
