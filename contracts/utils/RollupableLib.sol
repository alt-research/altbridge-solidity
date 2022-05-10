// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupTypes.sol";

library RollupableLib {
    event EmitRollupMsg(RollupMsg messages);

    function emitKv(
        RollupStateContext memory ctx,
        uint16 tag,
        bytes memory key,
        bytes memory value
    ) internal {
        RollupMsg memory message = RollupMsg(
            RollupMsgType.Map,
            tag,
            abi.encode(RollupMapMsg(key, value))
        );
        emitMsg(ctx, message);
    }

    function emitKey(
        RollupStateContext memory ctx,
        uint16 tag,
        bytes memory key
    ) internal {
        bytes memory empty;
        RollupMsg memory message = RollupMsg(
            RollupMsgType.Map,
            tag,
            abi.encode(RollupMapMsg(key, empty))
        );
        emitMsg(ctx, message);
    }

    function emitValue(
        RollupStateContext memory ctx,
        uint16 tag,
        bytes memory value
    ) internal {
        bytes memory empty;
        RollupMsg memory message = RollupMsg(
            RollupMsgType.Map,
            tag,
            abi.encode(RollupMapMsg(empty, value))
        );
        emitMsg(ctx, message);
    }

    function emitMsg(RollupStateContext memory ctx, RollupMsg memory message)
        internal
    {
        ctx._state = keccak256(abi.encode(ctx._state, message));
        emit EmitRollupMsg(message);
    }

    // https://github.com/binodnp/openzeppelin-solidity/blob/master/contracts/cryptography/MerkleProof.sol
    function verifyMerkleProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encode(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encode(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}
