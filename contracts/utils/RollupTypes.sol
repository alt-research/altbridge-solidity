// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct RollupStateContext {
    bool _writable;
    bytes32 _state; // writable
    uint256 _startBlock; // writable
    // readable
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

struct RollupStateHeader {
    RollupStateType ty;
    uint64 idx;
    uint16 tag;
}

struct RollupProposal {
    uint8 originDomainID;
    uint64 nonce;
    bytes32 stateRootHash;
    bytes32 msgRootHash;
    uint64 totalBatch;
}
