// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./RollupableLib.sol";

library RollupableMap {
    using RollupableLib for RollupStateContext;

    struct Map {
        mapping(bytes32 => bytes) _map;
    }

    function set(
        Map storage map,
        RollupStateContext memory ctx,
        uint16 tag,
        bytes32 key,
        bytes memory value
    ) internal {
        map._map[key] = value;
        ctx.emitKv(tag, abi.encode(key), abi.encode(value));
    }

    function get(Map storage map, bytes32 key)
        internal
        view
        returns (bytes memory)
    {
        return map._map[key];
    }

    struct AddressUint256Map {
        mapping(address => uint256) _map;
    }

    function set(
        AddressUint256Map storage map,
        RollupStateContext memory ctx,
        uint16 tag,
        address key,
        uint256 value
    ) internal {
        map._map[key] = value;
        ctx.emitKv(tag, abi.encode(key), abi.encode(value));
    }

    function get(AddressUint256Map storage map, address key)
        internal
        view
        returns (uint256)
    {
        return map._map[key];
    }
}
