// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupSDK.sol";
import "../utils/RollupableTypes.sol";

contract RollupExample is RollupSDK {
    uint16 constant _ownerTag = 0;
    uint64 constant _batchSize = 100;
    using RollupableTypes for RollupableTypes.Map;

    address immutable admin_;
    bool pause_ = false;
    RollupableTypes.Map private owner_;
    bytes32 private _state;

    event Transfer(uint256, address);

    constructor(address bridgeAddress) public RollupSDK(bridgeAddress) {
        admin_ = msg.sender;
    }

    function recoverRollupStateMap(
        uint16 tag,
        RollupMapMsg[] memory entries,
        uint256
    ) internal virtual override {
        RollupStateContext memory ctx = getContext();
        if (tag == _ownerTag) {
            for (uint256 j = 0; j < entries.length; j++) {
                uint256 tokenId = abi.decode(entries[j].key, (uint256));
                address owner = abi.decode(entries[j].value, (address));
                emit Transfer(tokenId, owner);
                owner_.set(ctx, _ownerTag, bytes32(tokenId), entries[j].value);
            }
        }
        saveContext(ctx);
    }

    function transfer(uint256 tokenId, address to) public {
        if (msg.sender != admin_) {
            require(!pause_, "contract is paused");
            require(
                owner_.getAsAddress(bytes32(tokenId)) == msg.sender,
                "token not owned"
            );
        }

        RollupStateContext memory ctx = getContext();
        owner_.set(ctx, _ownerTag, bytes32(tokenId), abi.encode(to));
        saveContext(ctx);
    }

    function rollupToOtherChain(uint8 targetDomainId, bytes32 resourceID)
        public
    {
        require(msg.sender == admin_, "admin required");
        pause_ = true;
        executeRollupMsgTo(targetDomainId, resourceID, _batchSize);
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
