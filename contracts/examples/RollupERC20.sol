// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupSDK.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "../utils/RollupableTypes.sol";

contract RollupERC20 is RollupSDK, ERC20PresetMinterPauser {
    uint16 constant _balanceTag = 0;
    uint16 constant _totalSupplyTag = 1;
    uint64 constant _batchSize = 100;
    using RollupableTypes for RollupableTypes.AddressUint256Map;
    using RollupableTypes for RollupableTypes.Uint256;

    RollupableTypes.AddressUint256Map private _balances;
    RollupableTypes.Uint256 private _totalSupply;

    /**
     * @dev Allows overriding the name, symbol & decimal of the base ERC20 contract
     */
    constructor(
        address bridgeAddress,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public ERC20PresetMinterPauser(name, symbol) RollupSDK(bridgeAddress) {
        _setupDecimals(decimals);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
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

    function _mint(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        RollupStateContext memory ctx = getContext();
        _totalSupply.set(ctx, _totalSupplyTag, _totalSupply.get().add(amount));
        _balances.add(ctx, _balanceTag, account, amount);
        emit Transfer(address(0), account, amount);
        saveContext(ctx);
    }

    function _burn(address account, uint256 amount) internal virtual override {
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply.get();
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances.get(account);
    }

    function rollupToOtherChain(uint8 targetDomainId, bytes32 resourceID)
        public
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "RollupERC20: must have admin role to terminate"
        );
        pause();
        executeRollupMsgTo(targetDomainId, resourceID, _batchSize);
    }

    // called by RollupSDK
    function recoverRollupStateMap(
        uint16 tag,
        RollupMapMsg[] memory entries,
        uint256
    ) internal virtual override {
        if (tag == _balanceTag) {
            for (uint256 j = 0; j < entries.length; j++) {
                address account = abi.decode(entries[j].key, (address));
                uint256 amount = abi.decode(entries[j].value, (uint256));
                _mint(account, amount);
            }
        } else if (tag == _totalSupplyTag) {
            for (uint256 j = 0; j < entries.length; j++) {
                RollupStateContext memory ctx = getContext();
                _totalSupply.add(
                    ctx,
                    _totalSupplyTag,
                    abi.decode(entries[j].value, (uint256))
                );
                saveContext(ctx);
            }
        }
    }
}
