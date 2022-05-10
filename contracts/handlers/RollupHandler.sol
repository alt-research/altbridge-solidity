// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IDepositExecute.sol";
import "../interfaces/IRollupHandler.sol";
import "../interfaces/IRollup.sol";
import "./HandlerHelpers.sol";

contract RollupHandler is
    IDepositExecute,
    HandlerHelpers,
    IRollup,
    IRollupHandler
{
    constructor(address bridgeAddress) public HandlerHelpers(bridgeAddress) {}

    mapping(uint72 => Metadata) _rollupInfos;

    function deposit(
        bytes32,
        address,
        bytes calldata
    ) external override onlyBridge returns (bytes memory) {
        require(false, "deposit not supported in RollupHandler");
    }

    function rollup(bytes32, bytes calldata) external override onlyBridge {
        require(false, "rollup not supported in RollupHandler");
    }

    struct Metadata {
        uint8 domainID;
        bytes32 resourceID;
        uint64 nonce;
        bytes32 msgRootHash;
        bytes32 stateRootHash;
        uint64 totalBatch;
        // bytes state; unused
    }

    /**
        @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
        @param data Consists of {resourceID}, {lenMetaData}, and {metaData}.
        @notice Data passed into the function should be constructed as follows:
        len(data)                              uint256     bytes  0  - 32
        data                                   bytes       bytes  32 - END
        @notice {contractAddress} is required to be whitelisted
        @notice If {_contractAddressToExecuteFunctionSignature}[{contractAddress}] is set,
        {metaData} is expected to consist of needed function arguments.
     */
    function executeProposal(bytes32 resourceID, bytes calldata data)
        external
        override
        onlyBridge
    {
        address contractAddress = _resourceIDToTokenContractAddress[resourceID];
        require(
            _contractWhitelist[contractAddress],
            "provided contractAddress is not whitelisted"
        );

        Metadata memory md = abi.decode(data, (Metadata));
        uint72 nonceAndID = (uint72(md.nonce) << 8) | uint72(md.domainID);
        _rollupInfos[nonceAndID] = md;
    }

    function fetchRollupProposal(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce
    ) external override returns (RollupProposal memory, address) {
        address receiverAddress = _resourceIDToTokenContractAddress[resourceID];
        uint72 nonceAndID = (uint72(nonce) << 8) | uint72(originDomainID);
        Metadata memory md = _rollupInfos[nonceAndID];
        require(md.resourceID == resourceID, "resource_id not match");
        require(receiverAddress != address(0), "no handler for resourceID");
        RollupProposal memory proposal;
        proposal.originDomainID = originDomainID;
        proposal.nonce = nonce;
        proposal.stateRootHash = md.stateRootHash;
        proposal.msgRootHash = md.msgRootHash;
        proposal.stateRootHash = md.stateRootHash;
        proposal.totalBatch = md.totalBatch;
        return (proposal, receiverAddress);
    }

    function getAddressByResourceID(bytes32 resourceID)
        external
        override
        returns (address)
    {
        return _resourceIDToTokenContractAddress[resourceID];
    }
}
