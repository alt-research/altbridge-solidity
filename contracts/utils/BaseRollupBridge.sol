// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRollupSender.sol";

contract BaseRollupBridge {
    event SendRollupMsg(bytes32 resourceID, IRollupSender.RollupMsg[] messages, bytes32 proof);
    event ExecRollup(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 nonce,
        uint64 batchSize,
        bytes32 proof
    );
    event Debug(bytes data);

    mapping(bytes32 => bytes32) _latestState;

    function _sendRollupMsg(bytes32 resourceID, IRollupSender.RollupMsg[] calldata messages)
        internal
    {
        bytes32 proof = _latestState[resourceID];
        for (uint256 i = 0; i < messages.length; i++) {
            proof = keccak256(abi.encode(proof, messages[i]));
        }
        _latestState[resourceID] = proof;
        emit SendRollupMsg(resourceID, messages, proof);
    }

    function _executeRollupMsgOn(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 nonce,
        uint64 batchSize
    ) internal {
        bytes32 finalProof = _latestState[resourceID];
        if (finalProof == 0) {
            return;
        }
        _latestState[resourceID] = 0;
        emit ExecRollup(destDomainID, resourceID, nonce, batchSize, finalProof);
    }
}
