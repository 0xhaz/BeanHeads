// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {TokenPool} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {Pool} from "chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Pool.sol";
import {IERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {MockWETH} from "src/mocks/MockWETH.sol";

/// @title MockTokenPool
/// @notice Mocks a token pool that wraps/unwraps ETH instead of transferring ERC20 tokens.
contract MockTokenPool is TokenPool {
    using SafeERC20 for IERC20;

    /// @notice Emitted when ETH is received and treated as WETH wrapping
    event ETHWrapped(address indexed sender, uint256 amount);

    /// @notice Emitted when ETH is unwrapped and sent back to receiver
    event ETHUnwrapped(address indexed receiver, uint256 amount);

    constructor(IERC20 _token, address[] memory allowList, address rmnProxy, address router)
        TokenPool(_token, allowList, rmnProxy, router)
    {}

    /// @notice Accept ETH for wrap simulation
    receive() external payable {}

    function lockOrBurn(Pool.LockOrBurnInV1 calldata lockOrBurnIn)
        external
        override
        returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut)
    {
        _validateLockOrBurn(lockOrBurnIn);

        lockOrBurnOut =
            Pool.LockOrBurnOutV1({destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector), destPoolData: ""});
    }

    function releaseOrMint(Pool.ReleaseOrMintInV1 calldata releaseOrMintIn)
        external
        override
        returns (Pool.ReleaseOrMintOutV1 memory releaseOrMintOut)
    {
        _validateReleaseOrMint(releaseOrMintIn);

        address receiver = releaseOrMintIn.receiver;
        uint256 amount = releaseOrMintIn.amount;

        // Simulate WETH unwrapping by sending ETH to receiver
        (bool success,) = receiver.call{value: amount}("");
        require(success, "MockTokenPool: ETH transfer failed");

        emit ETHUnwrapped(receiver, amount);

        releaseOrMintOut = Pool.ReleaseOrMintOutV1({destinationAmount: amount});
    }
}
