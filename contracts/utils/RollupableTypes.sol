// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./RollupableLib.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";

library RollupableTypes {
    using RollupableLib for RollupStateContext;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    // ====================================== Uint256 ======================================
    struct Uint256 {
        uint256 _value;
    }

    function set(
        Uint256 storage v,
        RollupStateContext memory ctx,
        uint16 tag,
        uint256 value
    ) internal {
        v._value = value;
        ctx.emitValue(tag, abi.encode(value));
    }

    function sub(
        Uint256 storage v,
        RollupStateContext memory ctx,
        uint16 tag,
        uint256 amount
    ) internal {
        uint256 value = v._value.sub(amount);
        v._value = value;
        ctx.emitValue(tag, abi.encode(value));
    }

    function add(
        Uint256 storage v,
        RollupStateContext memory ctx,
        uint16 tag,
        uint256 amount
    ) internal {
        uint256 value = v._value.add(amount);
        v._value = value;
        ctx.emitValue(tag, abi.encode(value));
    }

    function get(Uint256 storage v) internal view returns (uint256) {
        return v._value;
    }

    // ====================================== Map ======================================

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
        ctx.emitKv(tag, abi.encode(key), value);
    }

    function remove(
        Map storage map,
        RollupStateContext memory ctx,
        uint16 tag,
        bytes32 key
    ) internal {
        delete map._map[key];
        ctx.emitKey(tag, abi.encode(key));
    }

    function get(Map storage map, bytes32 key)
        internal
        view
        returns (bytes memory)
    {
        return map._map[key];
    }

    function getAsAddress(Map storage map, bytes32 key)
        internal
        view
        returns (address val)
    {
        bytes memory out = map._map[key];
        if (out.length > 0) {
            (val) = abi.decode(map._map[key], (address));
        }
        return val;
    }

    function getAsString(Map storage map, bytes32 key)
        internal
        view
        returns (string memory val)
    {
        return string(map._map[key]);
    }

    function setAsString(
        Map storage map,
        RollupStateContext memory ctx,
        uint16 tag,
        bytes32 key,
        string memory value
    ) internal {
        map._map[key] = bytes(value);
        ctx.emitKv(tag, abi.encode(key), bytes(value));
    }

    // ====================================== AddressUint256Map ======================================

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

    function add(
        AddressUint256Map storage map,
        RollupStateContext memory ctx,
        uint16 tag,
        address key,
        uint256 amount
    ) internal {
        uint256 value = map._map[key].add(amount);
        map._map[key] = value;
        ctx.emitKv(tag, abi.encode(key), abi.encode(value));
    }

    function sub(
        AddressUint256Map storage map,
        RollupStateContext memory ctx,
        uint16 tag,
        address key,
        uint256 amount,
        string memory errorMessage
    ) internal {
        uint256 value = map._map[key].sub(amount, errorMessage);
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

    // ====================================== AddressEnumerableSetMap ======================================

    struct AddressEnumerableUintSetMap {
        mapping(address => EnumerableSet.UintSet) _map;
    }

    function length(AddressEnumerableUintSetMap storage map, address key)
        internal
        view
        returns (uint256)
    {
        return map._map[key].length();
    }

    function add(
        AddressEnumerableUintSetMap storage map,
        RollupStateContext memory ctx,
        uint16 tag,
        address key,
        uint256 value
    ) internal {
        map._map[key].add(value);
        ctx.emitKv(tag, abi.encode(key, value), abi.encode(1));
    }

    function remove(
        AddressEnumerableUintSetMap storage map,
        RollupStateContext memory ctx,
        uint16 tag,
        address key,
        uint256 value
    ) internal {
        map._map[key].remove(value);
        ctx.emitKv(tag, abi.encode(key, value), abi.encode(0));
    }

    function at(
        AddressEnumerableUintSetMap storage map,
        address key,
        uint256 index
    ) internal view returns (uint256) {
        return map._map[key].at(index);
    }

    // ============

    struct EnumerableUintToAddressMap {
        EnumerableMap.UintToAddressMap _map;
    }

    function at(EnumerableUintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        return map._map.at(index);
    }

    function contains(EnumerableUintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return map._map.contains(key);
    }

    function set(
        EnumerableUintToAddressMap storage map,
        RollupStateContext memory ctx,
        uint16 tag,
        uint256 key,
        address value
    ) internal {
        map._map.set(key, value);
        ctx.emitKv(tag, abi.encode(key), abi.encode(value));
    }

    function get(
        EnumerableUintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return map._map.get(key, errorMessage);
    }

    function length(EnumerableUintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return map._map.length();
    }

    function remove(
        EnumerableUintToAddressMap storage map,
        RollupStateContext memory ctx,
        uint16 tag,
        uint256 key
    ) internal {
        map._map.remove(key);
        ctx.emitKey(tag, abi.encode(key));
    }
}
