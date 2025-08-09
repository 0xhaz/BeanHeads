// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

library ReentrancyLib {
    bytes32 constant REENTRANCY_STORAGE_POSITION = keccak256("beanheads.diamond.reentrancy.storage");

    struct ReentrancyStorage {
        uint256 status; // 0 = not entered, 1 = entered
    }

    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    function reentrancyStorage() private pure returns (ReentrancyStorage storage rs) {
        bytes32 position = REENTRANCY_STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }

    function enforceNotEntered() internal {
        ReentrancyStorage storage rs = reentrancyStorage();
        require(rs.status != ENTERED, "ReentrancyLib: reentrant call");

        rs.status = ENTERED;
    }

    function resetStatus() internal {
        ReentrancyStorage storage rs = reentrancyStorage();
        rs.status = NOT_ENTERED;
    }

    function initReentrancyGuard() internal {
        ReentrancyStorage storage rs = reentrancyStorage();
        rs.status = NOT_ENTERED;
    }
}
