// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupSDK.sol";
import "@openzeppelin/contracts/presets/ERC721PresetMinterPauserAutoId.sol";

contract RollupERC721 is RollupSDK, ERC721PresetMinterPauserAutoId {
    uint16 constant _balanceTag = 0;
    uint64 constant _batchSize = 100;

    /**
     * @dev Allows overriding the name, symbol & decimal of the base ERC20 contract
     */
    constructor(
        address bridgeAddress,
        bytes32 resourceID,
        string memory name,
        string memory symbol,
        string memory baseURI
    )
        public
        ERC721PresetMinterPauserAutoId(name, symbol, baseURI)
        RollupSDK(bridgeAddress, resourceID)
    {
    }


    // function rollupToOtherChain(uint8 targetDomainId) public {
    //     require(
    //         hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
    //         "RollupERC20: must have admin role to terminate"
    //     );
    //     pause();
    //     executeRollupMsgTo(targetDomainId, _batchSize);
    // }

    // // called by RollupSDK
    // function recoverRollupStateMap(
    //     uint16 tag,
    //     RollupMapMsg[] memory entries,
    //     bool
    // ) internal virtual override {
    //     if (tag == _balanceTag) {
    //         for (uint256 j = 0; j < entries.length; j++) {
    //             address account = abi.decode(entries[j].key, (address));
    //             uint256 amount = abi.decode(entries[j].value, (uint256));
    //             _mint(account, amount);
    //         }
    //     }
    // }
}
