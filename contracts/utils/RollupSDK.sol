// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRollupSender.sol";

contract RollupSDK {
    address public immutable _bridgeAddress;
    bytes32 public immutable _resourceID;
    uint256 private epoch_;
    mapping(uint72 => uint256) _executeBatchNonce;
    bool private unused_;

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
        IRollupSender.RollupState memory rollupStates;
        rollupStates = abi.decode(states, (IRollupSender.RollupState));
        _executeBatchNonce[nonceAndID]++;
        recoverRollupState(rollupStates, isEnd);
    }

    function recoverRollupState(
        IRollupSender.RollupState memory state,
        bool isEnd
    ) internal virtual {
        if (state.ty == IRollupSender.RollupStateType.Map) {
            IRollupSender.MapMsg[] memory entries = abi.decode(
                state.records,
                (IRollupSender.MapMsg[])
            );
            recoverRollupStateMap(state.tag, entries, isEnd);
        }
    }

    function recoverRollupStateMap(
        uint16,
        IRollupSender.MapMsg[] memory,
        bool
    ) internal virtual {
        require(false, "handleRollupStateMap is not implemented");
        unused_ = true; // ignore the warning: Function state mutability can be restricted to pure
    }

    function sendRollupMsg(IRollupSender.RollupMsg[] memory messages) internal {
        IRollupSender(_bridgeAddress).sendRollupMsg(_resourceID, messages);
    }

    function sendRollupMsgMap(uint16 tag, IRollupSender.MapMsg memory kvMsg) internal {
        IRollupSender.RollupMsg[] memory msgs = new IRollupSender.RollupMsg[](
            1
        );
        msgs[0] = IRollupSender.RollupMsg(
            IRollupSender.RollupMsgType.Map,
            tag,
            abi.encode(kvMsg)
        );
        sendRollupMsg(msgs);
    }

    function executeRollupMsgTo(uint8 destDomainID, uint64 batchSize) internal {
        IRollupSender(_bridgeAddress).executeRollupMsgTo(
            destDomainID,
            _resourceID,
            batchSize
        );
    }
}
