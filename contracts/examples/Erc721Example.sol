// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/ERC721Rollup.sol";
// import "@openzeppelin/contracts/presets/ERC721PresetMinterPauserAutoId.sol";

contract ERC721Example is ERC721Rollup {
    constructor(
        address bridgeAddress,
        string memory name,
        string memory symbol
    ) public ERC721Rollup(bridgeAddress) ERC721(name, symbol) {}
}
