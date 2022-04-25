// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IRollupSender {
    enum RollupMsgType {
        Map
    }

    struct MapMsg {
        bytes key;
        bytes value;
    }

    struct RollupMsg {
        RollupMsgType ty;
        uint16 tag;
        bytes data;
    }

    enum RollupStateType {
        Map
    }

    struct RollupState {
        RollupStateType ty;
        uint16 tag;
        bytes records;
    }

    function sendRollupMsg(
        bytes32 resourceID,
        RollupMsg[] calldata messages
    ) external;

    function executeRollupMsgTo(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 batchSize
    ) external;

    function verifyRollupMsg(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes32 msgRootHash,
        uint256 batchIdx,
        bytes calldata states,
        bytes32[] calldata _proof
    ) external returns (bool passed, bool isEnd);
}
