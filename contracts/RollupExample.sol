// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./utils/RollupSDK.sol";

contract RollupExample is RollupSDK {
    
    uint16 constant owner_tag_ = 0;
    uint64 constant batch_size_ = 100;

    address immutable admin_;
    bool pause_ = false;
    mapping(uint256 => address) owner_;

    event Transfer(uint256, address);

    constructor(address bridgeAddress, bytes32 resourceID)
        public
        RollupSDK(bridgeAddress, resourceID)
    {
        admin_ = msg.sender;
    }

    function handleRollupState(IRollupSender.RollupState memory state)
        internal
        virtual
        override
    {
        if (
            state.tag == owner_tag_ &&
            state.ty == IRollupSender.RollupStateType.Map
        ) {
            IRollupSender.MapMsg[] memory entries = abi.decode(
                state.records,
                (IRollupSender.MapMsg[])
            );
            for (uint256 j = 0; j < entries.length; j++) {
                uint256 tokenId = abi.decode(entries[j].key, (uint256));
                address owner = abi.decode(entries[j].value, (address));
                emit Transfer(tokenId, owner);
                owner_[tokenId] = owner;
            }
        }
    }

    function transfer(uint256 tokenId, address to) public {
        if (msg.sender != admin_) {
            require(!pause_, "contract is paused");
            require(owner_[tokenId] == msg.sender, "token not owned");
        }
        owner_[tokenId] = to;
        IRollupSender.MapMsg memory kvMsg = IRollupSender.MapMsg(
            abi.encode(tokenId),
            abi.encode(to)
        );
        IRollupSender.RollupMsg[] memory msgs = new IRollupSender.RollupMsg[](
            1
        );

        msgs[0] = IRollupSender.RollupMsg(
            IRollupSender.RollupMsgType.Map,
            owner_tag_,
            abi.encode(kvMsg)
        );
        sendRollupMsg(msgs);
    }

    function rollup(uint8 targetDomainId) public {
        require(msg.sender == admin_, "admin required");
        pause_ = true;
        executeRollupMsgOn(targetDomainId, batch_size_);
    }
}
