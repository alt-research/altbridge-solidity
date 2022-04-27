// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupTypes.sol";

library RollupableLib {
    event EmitRollupMsg(RollupMsg messages);

    function emitKv(
        RollupStateContext memory ctx,
        uint16 tag,
        bytes memory key,
        bytes memory value
    ) internal {
        RollupMsg memory message = RollupMsg(
            RollupMsgType.Map,
            tag,
            abi.encode(RollupMapMsg(key, value))
        );
        emitMsg(ctx, message);
    }

    function emitMsg(RollupStateContext memory ctx, RollupMsg memory message)
        internal
    {
        ctx._state = keccak256(abi.encode(ctx._state, message));
        emit EmitRollupMsg(message);
    }

    function finalize(RollupStateContext memory ctx) internal {}
}
