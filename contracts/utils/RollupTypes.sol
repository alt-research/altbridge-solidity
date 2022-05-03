// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct RollupStateContext {
    bytes32 _state;
    uint256 _startBlock;
    uint8 _epoch;
}

enum RollupMsgType {
    Map
}

struct RollupMapMsg {
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
    uint64 idx;
    uint16 tag;
    bytes records;
}

struct RollupProposal {
    uint8 originDomainID;
    uint64 nonce;
    bytes32 stateRootHash;
    bytes32 msgRootHash;
    uint256 totalBatch;
}