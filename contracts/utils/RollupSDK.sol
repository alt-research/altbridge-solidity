// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRollupSender.sol";
import "../interfaces/IRollupReceiver.sol";
import "../utils/RollupTypes.sol";
import "../utils/RollupableTypes.sol";

contract RollupSDK is IRollupReceiver {
    address public immutable _bridgeAddress;
    uint256 private epoch_;
    mapping(uint72 => uint256) _executeBatchNonce;
    bool private unused_;
    bytes32 private _state;
    uint256 private _startBlock;
    event BlockNumber(uint256);

    constructor(address bridgeAddress) public {
        _bridgeAddress = bridgeAddress;
    }

    function recoverRollupProposal(
        RollupProposal memory proposal,
        uint256 batchIdx,
        bytes memory states,
        bytes32[] calldata proof
    ) external override {
        require(msg.sender == _bridgeAddress, "should only from bridge");
        uint72 nonceAndID = (uint72(proposal.nonce) << 8) |
            uint72(proposal.originDomainID);
        require(
            _executeBatchNonce[nonceAndID] == batchIdx,
            "batchIdx not expected"
        );
        RollupState memory rollupStates;
        rollupStates = abi.decode(states, (RollupState));
        _executeBatchNonce[nonceAndID]++;
        recoverRollupState(rollupStates, batchIdx);
    }

    function recoverRollupState(RollupState memory state, uint256 batchIdx)
        internal
        virtual
    {
        if (state.ty == RollupStateType.Map) {
            RollupMapMsg[] memory entries = abi.decode(
                state.records,
                (RollupMapMsg[])
            );
            recoverRollupStateMap(state.tag, entries, batchIdx);
        }
    }

    function recoverRollupStateMap(
        uint16,
        RollupMapMsg[] memory,
        uint256
    ) internal virtual {
        require(false, "handleRollupStateMap is not implemented");
        unused_ = true; // ignore the warning: Function state mutability can be restricted to pure
    }

    function executeRollupMsgTo(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 batchSize
    ) internal {
        IRollupSender(_bridgeAddress).executeRollupMsgTo(
            destDomainID,
            resourceID,
            batchSize,
            _startBlock,
            _state
        );
        _startBlock = 0;
        _state = bytes32(0);
    }

    function getContext() internal view returns (RollupStateContext memory) {
        RollupStateContext memory ctx;
        ctx._state = _state;
        if (ctx._state == bytes32(0)) {
            ctx._startBlock = block.number;
        }
        return ctx;
    }

    function saveContext(RollupStateContext memory ctx) internal {
        _state = ctx._state;
        if (ctx._startBlock > 0) {
            _startBlock = ctx._startBlock;
            emit BlockNumber(ctx._startBlock);
        }
    }
}
