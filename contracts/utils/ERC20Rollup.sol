// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupSDK.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/RollupableTypes.sol";

abstract contract ERC20Rollup is RollupSDK, AccessControl, ERC20 {
    uint16 constant _balanceTag = 0;
    uint16 constant _totalSupplyTag = 1;
    using RollupableTypes for RollupableTypes.AddressUint256Map;
    using RollupableTypes for RollupableTypes.Uint256;

    RollupableTypes.AddressUint256Map private _balances;
    RollupableTypes.Uint256 private _totalSupply;

    /**
     * @dev Allows overriding the name, symbol & decimal of the base ERC20 contract
     */
    constructor(address bridgeAddress) public RollupSDK(bridgeAddress) {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override(ERC20) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        RollupStateContext memory ctx = getContext();
        _balances.sub(
            ctx,
            _balanceTag,
            sender,
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances.add(ctx, _balanceTag, recipient, amount);
        emit Transfer(sender, recipient, amount);
        saveContext(ctx);
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20)
    {
        RollupStateContext memory ctx = getContext();
        _mint(ctx, account, amount);
        saveContext(ctx);
    }

    function _mint(
        RollupStateContext memory ctx,
        address account,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply.add(ctx, _totalSupplyTag, amount);
        _balances.add(ctx, _balanceTag, account, amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        virtual
        override(ERC20)
    {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        RollupStateContext memory ctx = getContext();
        _balances.sub(
            ctx,
            _balanceTag,
            account,
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply.sub(ctx, _totalSupplyTag, amount);
        emit Transfer(account, address(0), amount);
        saveContext(ctx);
    }

    function totalSupply()
        public
        view
        virtual
        override(ERC20)
        returns (uint256)
    {
        return _totalSupply.get(getContext());
    }

    function balanceOf(address account)
        public
        view
        virtual
        override(ERC20)
        returns (uint256)
    {
        return _balances.get(getContext(), account);
    }

    function rollupToOtherChain(
        uint8 targetDomainId,
        bytes32 resourceID,
        uint64 batchSize
    ) public virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC20Rollup: must have admin role to terminate"
        );
        executeRollupMsgTo(targetDomainId, resourceID, batchSize);
    }

    // called by RollupSDK
    function recoverRollupStateMap(
        uint16 tag,
        RollupMapMsg[] memory entries,
        uint256
    ) internal virtual override {
        if (tag == _balanceTag) {
            RollupStateContext memory ctx = getContext();
            for (uint256 j = 0; j < entries.length; j++) {
                address account = abi.decode(entries[j].key, (address));
                uint256 amount = abi.decode(entries[j].value, (uint256));
                _mint(ctx, account, amount);
            }
            saveContext(ctx);
        }
    }
}
