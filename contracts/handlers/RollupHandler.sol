// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IDepositExecute.sol";
import "../interfaces/IRollup.sol";
import "./HandlerHelpers.sol";

contract RollupHandler is IDepositExecute, HandlerHelpers, IRollup {
    constructor(address bridgeAddress) public HandlerHelpers(bridgeAddress) {}

    mapping(uint72 => Metadata) _rollupInfos;
    event Test(bytes32);

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
        uint256 totalBatch;
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

        Metadata memory md = abi.decode(
            data,
            (Metadata)
        );
        uint72 nonceAndID = (uint72(md.nonce) << 8) | uint72(md.domainID);
        _rollupInfos[nonceAndID] = md;
    }

    // https://github.com/binodnp/openzeppelin-solidity/blob/master/contracts/cryptography/MerkleProof.sol
    function _verify(
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

    function verifyRollupMsg(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes32 msgRootHash,
        uint256 batchIdx,
        bytes calldata states,
        bytes32[] calldata _proof
    ) external onlyBridge returns (bool passed, bool isEnd) {
        uint72 nonceAndID = (uint72(nonce) << 8) | uint72(originDomainID);
        Metadata memory md = _rollupInfos[nonceAndID];
        require(md.msgRootHash == msgRootHash, "msg_root_hash not match");
        require(md.resourceID == resourceID, "resource_id not match");
        require(
            _verify(_proof, md.stateRootHash, keccak256(states)),
            "invalid proof"
        );
        passed = true;
        isEnd = batchIdx == md.totalBatch-1;
        return (passed, isEnd);
    }
}
