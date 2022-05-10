// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupTypes.sol";

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IRollupSender {
    function executeRollupMsgTo(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 batchSize,
        uint256 startBlock,
        bytes32 state
    ) external;
}
