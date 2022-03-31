// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IRollup {
    function rollup(bytes32 resourceID, bytes calldata data) external;
}
