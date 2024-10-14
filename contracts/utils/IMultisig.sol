// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IMultisig
 * @author ClosedZeppelin
 * @notice Interface for the Multisig contract.
 */
interface IMultisig {
    /**
     * @notice Executes a multisig operation.
     * @param execution The execution data to be executed.
     * @param deadline The deadline by which the operation must be executed.
     * @param signatures The signatures authorizing the operation.
     * @return The result of the execution.
     */
    function execute(
        bytes calldata execution,
        uint256 deadline,
        bytes[] memory signatures
    ) external returns (bytes memory);
}
