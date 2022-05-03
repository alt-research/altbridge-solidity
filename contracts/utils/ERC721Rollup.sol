// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupSDK.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract ERC721Rollup is RollupSDK, AccessControl, ERC721 {
    uint16 constant _holderTokensTag = 0;
    uint16 constant _tokenOwnersTag = 1;
    uint16 constant _tokenURIsTag = 2;
    uint64 constant _batchSize = 100;

    using RollupableTypes for RollupableTypes.AddressEnumerableUintSetMap;
    using RollupableTypes for RollupableTypes.EnumerableUintToAddressMap;
    using RollupableTypes for RollupableTypes.Map;

    RollupableTypes.AddressEnumerableUintSetMap private _holderTokens;
    RollupableTypes.EnumerableUintToAddressMap private _tokenOwners;
    RollupableTypes.Map private _tokenURIs;

    /**
     * @dev Allows overriding the name, symbol & decimal of the base ERC20 contract
     */
    constructor(address bridgeAddress) public RollupSDK(bridgeAddress) {}

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _holderTokens.length(getContext(), owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return
            _tokenOwners.get(
                getContext(),
                tokenId,
                "ERC721: owner query for nonexistent token"
            );
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        RollupStateContext memory ctx = getContext();

        string memory _tokenURI = _tokenURIs.getAsString(ctx, bytes32(tokenId));
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _holderTokens.at(getContext(), owner, index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length(getContext());
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        (uint256 tokenId, ) = _tokenOwners.at(getContext(), index);
        return tokenId;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return _tokenOwners.contains(getContext(), tokenId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        RollupStateContext memory ctx,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens.add(ctx, _holderTokensTag, to, tokenId);
        _tokenOwners.set(ctx, _tokenOwnersTag, tokenId, to);
        emit Transfer(address(0), to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        RollupStateContext memory ctx = getContext();
        _mint(ctx, to, tokenId);
        saveContext(ctx);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        address owner = ERC721.ownerOf(tokenId); // internal owner
        RollupStateContext memory ctx = getContext();

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (_tokenURIs.get(ctx, bytes32(tokenId)).length != 0) {
            _tokenURIs.remove(ctx, _tokenURIsTag, bytes32(tokenId));
        }

        _holderTokens.remove(ctx, _holderTokensTag, owner, tokenId);
        _tokenOwners.remove(ctx, _tokenOwnersTag, tokenId);

        emit Transfer(owner, address(0), tokenId);

        saveContext(ctx);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        ); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);
        RollupStateContext memory ctx = getContext();

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens.remove(ctx, _holderTokensTag, from, tokenId);
        _holderTokens.add(ctx, _holderTokensTag, to, tokenId);

        _tokenOwners.set(ctx, _tokenOwnersTag, tokenId, to);

        emit Transfer(from, to, tokenId);

        saveContext(ctx);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
        override
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        RollupStateContext memory ctx = getContext();
        _tokenURIs.setAsString(ctx, _tokenURIsTag, bytes32(tokenId), _tokenURI);
        saveContext(ctx);
    }

    function rollupToOtherChain(uint8 targetDomainId, bytes32 resourceID)
        public
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721Rollup: must have admin role to terminate"
        );
        executeRollupMsgTo(targetDomainId, resourceID, _batchSize);
    }

    // called by RollupSDK
    function recoverRollupStateMap(
        uint16 tag,
        RollupMapMsg[] memory entries,
        uint256
    ) internal virtual override {
        if (tag == _holderTokensTag) {
            RollupStateContext memory ctx = getContext();
            for (uint256 j = 0; j < entries.length; j++) {
                bool isEnable = abi.decode(entries[j].value, (uint256)) == 1;
                if (isEnable) {
                    address account;
                    uint256 tokenId;
                    (account, tokenId) = abi.decode(
                        entries[j].key,
                        (address, uint256)
                    );
                    _mint(ctx, account, tokenId);
                }
            }
            saveContext(ctx);
        } else if (tag == _tokenURIsTag) {}
    }
}
