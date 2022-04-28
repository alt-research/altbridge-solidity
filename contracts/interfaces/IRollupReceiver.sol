// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupTypes.sol";

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IRollupReceiver {
    function recoverRollupProposal(
        RollupProposal memory proposal,
        uint256 batchIdx,
        bytes memory states,
        bytes32[] calldata proof
    ) external;
}
