// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IRollupSender {
    enum RollupMsgType {
        SetKV
    }

    struct KvMsg {
        bytes key;
        bytes value;
    }

    struct RollupMessage {
        RollupMsgType ty;
        string tag;
        bytes data;
    }

    enum RollupStateType {
        Map
    }

    struct RollupState {
        RollupStateType ty;
        string tag;
        bytes records;
    }

    function sendRollupMsg(
        bytes32 resourceID,
        RollupMessage[] calldata messages
    ) external;

    function executeRollupMsgOn(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 batchSize
    ) external;

    function verifyRollupMsg(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes32 msgRootHash,
        int256 batchIdx,
        bytes calldata states,
        bytes32[] calldata _proof
    ) external returns (bool);
}
