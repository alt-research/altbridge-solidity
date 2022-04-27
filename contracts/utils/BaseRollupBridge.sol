// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupTypes.sol";

contract BaseRollupBridge {
    event ExecRollup(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 nonce,
        uint64 batchSize,
        bytes32 proof
    );

    function _executeRollupMsgTo(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 nonce,
        uint64 batchSize,
        bytes32 state
    ) internal {
        emit ExecRollup(destDomainID, resourceID, nonce, batchSize, state);
    }
}
