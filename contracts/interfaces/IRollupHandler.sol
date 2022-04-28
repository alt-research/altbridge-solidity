// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupTypes.sol";


interface IRollupHandler {
    function fetchRollupProposal(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce
    ) external returns (RollupProposal memory proposal, address receiver);
}
