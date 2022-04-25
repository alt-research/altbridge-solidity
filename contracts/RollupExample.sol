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

    function recoverRollupStateMap(
        uint16 tag,
        IRollupSender.MapMsg[] memory entries,
        bool isEnd
    ) internal virtual override {
        if (tag == owner_tag_) {
            for (uint256 j = 0; j < entries.length; j++) {
                uint256 tokenId = abi.decode(entries[j].key, (uint256));
                address owner = abi.decode(entries[j].value, (address));
                emit Transfer(tokenId, owner);
                owner_[tokenId] = owner;
            }
            if (isEnd) {
                pause_ = false;
            }
        }
    }

    function transfer(uint256 tokenId, address to) public {
        if (msg.sender != admin_) {
            require(!pause_, "contract is paused");
            require(owner_[tokenId] == msg.sender, "token not owned");
        }
        owner_[tokenId] = to;
        sendRollupMsgMap(
            owner_tag_,
            IRollupSender.MapMsg(abi.encode(tokenId), abi.encode(to))
        );
    }

    function rollupTo(uint8 targetDomainId) public {
        require(msg.sender == admin_, "admin required");
        pause_ = true;
        executeRollupMsgTo(targetDomainId, batch_size_);
    }

    function pause() public {
        require(msg.sender == admin_, "admin required");
        pause_ = true;
    }

    function unpause() public {
        require(msg.sender == admin_, "admin required");
        pause_ = false;
    }
}
