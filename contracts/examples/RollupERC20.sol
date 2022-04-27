// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/RollupSDK.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "../utils/RollupableMap.sol";

contract RollupERC20 is RollupSDK, ERC20PresetMinterPauser {
    uint16 constant _balanceTag = 0;
    uint64 constant _batchSize = 100;
    uint256 private _totalSupply;
    using RollupableMap for RollupableMap.AddressUint256Map;

    RollupableMap.AddressUint256Map private _balances;
    bytes32 _balanceState;

    /**
     * @dev Allows overriding the name, symbol & decimal of the base ERC20 contract
     */
    constructor(
        address bridgeAddress,
        bytes32 resourceID,
        string memory name,
        string memory symbol,
        uint8 decimals
    )
        public
        ERC20PresetMinterPauser(name, symbol)
        RollupSDK(bridgeAddress, resourceID)
    {
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
        RollupStateContext memory ctx;
        ctx._state = _balanceState;
        _balances.set(
            ctx,
            _balanceTag,
            sender,
            _balances.get(sender).sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            )
        );
        _balances.set(
            ctx,
            _balanceTag,
            recipient,
            _balances.get(recipient).add(amount)
        );
        emit Transfer(sender, recipient, amount);
        _balanceState = ctx._state;
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        RollupStateContext memory ctx;
        ctx._state = _balanceState;
        _totalSupply = _totalSupply.add(amount);
        _balances.set(
            ctx,
            _balanceTag,
            account,
            _balances.get(account).add(amount)
        );
        emit Transfer(address(0), account, amount);
        _balanceState = ctx._state;
    }

    function _burn(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        RollupStateContext memory ctx;
        ctx._state = _balanceState;
        _balances.set(
            ctx,
            _balanceTag,
            account,
            _balances.get(account).sub(
                amount,
                "ERC20: burn amount exceeds balance"
            )
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        _balanceState = ctx._state;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
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

    function rollupToOtherChain(uint8 targetDomainId) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "RollupERC20: must have admin role to terminate"
        );
        pause();
        executeRollupMsgTo(targetDomainId, _batchSize);
    }

    // called by RollupSDK
    function recoverRollupStateMap(
        uint16 tag,
        RollupMapMsg[] memory entries,
        bool
    ) internal virtual override {
        if (tag == _balanceTag) {
            for (uint256 j = 0; j < entries.length; j++) {
                address account = abi.decode(entries[j].key, (address));
                uint256 amount = abi.decode(entries[j].value, (uint256));
                _mint(account, amount);
            }
        }
    }
}
