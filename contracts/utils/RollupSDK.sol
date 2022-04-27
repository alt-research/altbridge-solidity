// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRollupSender.sol";
import "../utils/RollupTypes.sol";
import "../utils/BaseRollupBridge.sol";

contract RollupSDK {
    address public immutable _bridgeAddress;
    bytes32 public immutable _resourceID;
    uint256 private epoch_;
    mapping(uint72 => uint256) _executeBatchNonce;
    bool private unused_;

    struct Context {
        bytes32 proof;
    }

    constructor(address bridgeAddress, bytes32 resourceID) public {
        _bridgeAddress = bridgeAddress;
        _resourceID = resourceID;
    }

    function executeRollup(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes32 msgRootHash,
        uint256 batchIdx,
        bytes calldata states,
        bytes32[] calldata _proof
    ) external {
        bool passed;
        bool isEnd;
        (passed, isEnd) = IRollupSender(_bridgeAddress).verifyRollupMsg(
            originDomainID,
            resourceID,
            nonce,
            msgRootHash,
            batchIdx,
            states,
            _proof
        );
        require(passed, "verify fail");

        uint72 nonceAndID = (uint72(nonce) << 8) | uint72(originDomainID);
        require(
            _executeBatchNonce[nonceAndID] == batchIdx,
            "batchIdx not expected"
        );
        RollupState memory rollupStates;
        rollupStates = abi.decode(states, (RollupState));
        _executeBatchNonce[nonceAndID]++;
        recoverRollupState(rollupStates, isEnd);
    }

    function recoverRollupState(RollupState memory state, bool isEnd)
        internal
        virtual
    {
        if (state.ty == RollupStateType.Map) {
            RollupMapMsg[] memory entries = abi.decode(
                state.records,
                (RollupMapMsg[])
            );
            recoverRollupStateMap(state.tag, entries, isEnd);
        }
    }

    function recoverRollupStateMap(
        uint16,
        RollupMapMsg[] memory,
        bool
    ) internal virtual {
        require(false, "handleRollupStateMap is not implemented");
        unused_ = true; // ignore the warning: Function state mutability can be restricted to pure
    }

    function sendRollupMsg(RollupMsg[] memory messages) internal {
        IRollupSender(_bridgeAddress).sendRollupMsg(_resourceID, messages);
    }

    function emitSingleRollupMapMsg(uint16 tag, RollupMapMsg memory kvMsg)
        internal
    {
        RollupMsg[] memory msgs = new RollupMsg[](1);
        msgs[0] = RollupMsg(RollupMsgType.Map, tag, abi.encode(kvMsg));
        sendRollupMsg(msgs);
    }

    function emitRollupMapMsg(uint16 tag, RollupMapMsg[] memory kvMsgs)
        internal
    {
        
    }

    function executeRollupMsgTo(uint8 destDomainID, uint64 batchSize) internal {
        IRollupSender(_bridgeAddress).executeRollupMsgTo(
            destDomainID,
            _resourceID,
            batchSize
        );
    }
}
