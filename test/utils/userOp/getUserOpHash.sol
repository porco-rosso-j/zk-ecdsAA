// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";

/// @notice Get the userOperation hash over a user operation, entryPoint and chainId
function getUserOpHash(
    UserOperation memory userOp,
    address entryPoint,
    uint256 chainId
) pure returns (bytes32) {
    bytes32 userOpHash = keccak256(
        abi.encode(
            userOp.sender,
            userOp.nonce,
            userOp.initCode,
            userOp.callData,
            userOp.callGasLimit,
            userOp.verificationGasLimit,
            userOp.preVerificationGas,
            userOp.maxFeePerGas,
            userOp.maxPriorityFeePerGas,
            userOp.paymasterAndData
        )
    );

    return keccak256(abi.encode(userOpHash, entryPoint, chainId));
}
