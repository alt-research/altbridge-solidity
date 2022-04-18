// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRollupReceiver.sol";
import "../interfaces/IRollupSender.sol";

contract RollupSDK {
    address public immutable _bridgeAddress;
    bytes32 public immutable _resourceID;
    mapping(uint72 => bool) _rollupStates;

    constructor(
        address bridgeAddress,
        bytes32 resourceID
    ) public {
        _bridgeAddress = bridgeAddress;
        _resourceID = resourceID;
    }

    function executeRollup(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes32 msgRootHash,
        int256 batchIdx,
        bytes calldata states,
        bytes32[] calldata _proof
    ) external {
        require(
            IRollupSender(_bridgeAddress).verifyRollupMsg(
                originDomainID,
                resourceID,
                nonce,
                msgRootHash,
                batchIdx,
                states,
                _proof
            ),
            "verify fail"
        );
        IRollupSender.RollupState[] memory rollupStates;
        rollupStates = abi.decode(states, (IRollupSender.RollupState[]));
        onExecuteRollupMsg(rollupStates);
    }

    function onExecuteRollupMsg(IRollupSender.RollupState[] memory) public pure virtual {
        require(false, "onExecuteRollupMsg is not implemented");
    }

    function sendRollupMsg(IRollupSender.RollupMessage[] calldata messages) internal {
        IRollupSender(_bridgeAddress).sendRollupMsg(_resourceID, messages);
    }

    function executeRollupMsgOn(uint8 destDomainID, uint64 batchSize) internal {
        IRollupSender(_bridgeAddress).executeRollupMsgOn(
            destDomainID,
            _resourceID,
            batchSize
        );
    }
}
