// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct RollupStateContext {
    bytes32 _state;
    RollupMsg[] _msgs;
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
    uint16 tag;
    bytes records;
}
