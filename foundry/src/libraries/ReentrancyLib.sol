// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

library ReentrancyLib {
    bytes32 constant REENTRANCY_STORAGE_POSITION = keccak256("beanheads.diamond.reentrancy.storage");

    struct ReentrancyStorage {
        uint256 status; // 0 = not entered, 1 = entered
    }

    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /**
     * @notice Returns the ReentrancyStorage instance
     * @return rs The ReentrancyStorage instance
     */
    function reentrancyStorage() private pure returns (ReentrancyStorage storage rs) {
        bytes32 position = REENTRANCY_STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }

    /**
     * @notice Enforces that the function is not re-entered
     * @dev This function should be called at the beginning of any function that needs to be protected against re-entrancy
     */
    function enforceNotEntered() internal {
        ReentrancyStorage storage rs = reentrancyStorage();
        require(rs.status != ENTERED, "ReentrancyLib: reentrant call");

        rs.status = ENTERED;
    }

    /**
     * @notice Resets the re-entrancy status to not entered
     * @dev This function should be called at the end of any function that was protected against re-entrancy
     */
    function resetStatus() internal {
        ReentrancyStorage storage rs = reentrancyStorage();
        rs.status = NOT_ENTERED;
    }

    /**
     * @notice Initializes the re-entrancy guard
     * @dev This function should be called once during contract initialization
     */
    function initReentrancyGuard() internal {
        ReentrancyStorage storage rs = reentrancyStorage();
        rs.status = NOT_ENTERED;
    }
}
