// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IRollupSender.sol";

contract RollupSDK {
    address public immutable _bridgeAddress;
    bytes32 public immutable _resourceID;
    uint256 private epoch_;
    mapping(uint72 => uint256) _executeBatchNonce;
    bool private unused_;

    constructor(address bridgeAddress, bytes32 resourceID) public {
        _bridgeAddress = bridgeAddress;
        _resourceID = resourceID;
    }

    function executeRollup(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes32 msgRootHash,
        uint256 batchIdx,
        bytes calldata states,
        bytes32[] calldata _proof
    ) external {
        bool passed;
        (passed, ) = IRollupSender(_bridgeAddress).verifyRollupMsg(
            originDomainID,
            resourceID,
            nonce,
            msgRootHash,
            batchIdx,
            states,
            _proof
        );
        require(passed, "verify fail");

        uint72 nonceAndID = (uint72(nonce) << 8) | uint72(originDomainID);
        require(
            _executeBatchNonce[nonceAndID] == batchIdx,
            "batchIdx not expected"
        );
        IRollupSender.RollupState memory rollupStates;
        rollupStates = abi.decode(states, (IRollupSender.RollupState));
        _executeBatchNonce[nonceAndID]++;
        handleRollupState(rollupStates);
    }

    function handleRollupState(IRollupSender.RollupState memory)
        internal
        virtual
    {
        require(false, "handleRollupState is not implemented");
        unused_ = true; // ignore the warning: Function state mutability can be restricted to pure
    }

    function sendRollupMsg(IRollupSender.RollupMsg[] memory messages) internal {
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
