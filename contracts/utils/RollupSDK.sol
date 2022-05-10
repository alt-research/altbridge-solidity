// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRollupSender.sol";
import "../interfaces/IRollupReceiver.sol";
import "../utils/RollupTypes.sol";
import "../utils/RollupableTypes.sol";

contract RollupSDK is IRollupReceiver {
    address public immutable _bridgeAddress;
    uint8 private _epoch;
    mapping(uint72 => uint256) _executeBatchNonce;
    bool private _unused;
    bytes32 private _state;
    uint256 private _startBlock;
    event BlockNumber(uint256);
    event NewEpoch(uint8);

    constructor(address bridgeAddress) public {
        _bridgeAddress = bridgeAddress;
    }

    function recoverRollupProposal(
        RollupProposal memory proposal,
        bytes memory states,
        bytes32[] calldata proof
    ) external override {
        require(msg.sender == _bridgeAddress, "should only from bridge");
        uint72 nonceAndID = (uint72(proposal.nonce) << 8) |
            uint72(proposal.originDomainID);
        RollupState memory rollupStates;
        rollupStates = abi.decode(states, (RollupState));
        if (rollupStates.idx < _executeBatchNonce[nonceAndID]) {
            revert("already executed");
        }
        require(
            _executeBatchNonce[nonceAndID] == rollupStates.idx,
            "batchIdx not expected"
        );
        require(
            RollupableLib.verifyMerkleProof(
                proof,
                proposal.stateRootHash,
                keccak256(states)
            ),
            "verify fail"
        );
        _executeBatchNonce[nonceAndID]++;
        if (rollupStates.idx == 0) {
            _beforeRecoverRollupState(proposal);
        }
        _recoverRollupState(rollupStates);
        if (rollupStates.idx == proposal.totalBatch - 1) {
            _afterRecoverRollupState(proposal);
        }
    }

    function _beforeRecoverRollupState(RollupProposal memory proposal)
        internal
        virtual
    {}

    function _afterRecoverRollupState(RollupProposal memory proposal)
        internal
        virtual
    {}

    function _recoverRollupState(RollupState memory state) internal virtual {
        if (state.ty == RollupStateType.Map) {
            RollupMapMsg[] memory entries = abi.decode(
                state.records,
                (RollupMapMsg[])
            );
            _recoverRollupStateMap(state.tag, entries);
        }
    }

    function _recoverRollupStateMap(uint16, RollupMapMsg[] memory)
        internal
        virtual
    {
        require(false, "handleRollupStateMap is not implemented");
        _unused = true; // ignore the warning: Function state mutability can be restricted to pure
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
        uint8 epoch = _epoch + 1;
        emit NewEpoch(epoch);
        _epoch = epoch;
        _state = bytes32(0);
    }

    function getReadContext()
        internal
        view
        returns (RollupStateContext memory)
    {
        RollupStateContext memory ctx;
        ctx._epoch = _epoch;
        return ctx;
    }

    function getWriteContext()
        internal
        view
        returns (RollupStateContext memory)
    {
        RollupStateContext memory ctx;
        ctx._state = _state;
        ctx._epoch = _epoch;
        ctx._writable = true;
        if (ctx._state == bytes32(0)) {
            ctx._startBlock = block.number;
        }
        return ctx;
    }

    function saveContext(RollupStateContext memory ctx) internal {
        require(ctx._writable, "should save a writable context");
        _state = ctx._state;
        _epoch = ctx._epoch;
        if (ctx._startBlock > 0) {
            _startBlock = ctx._startBlock;
            emit BlockNumber(ctx._startBlock);
        }
    }
}
