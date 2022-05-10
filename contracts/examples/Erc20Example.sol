// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../utils/ERC20Rollup.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract ERC20Example is ERC20Rollup, ERC20PresetMinterPauser {
    constructor(
        address bridgeAddress,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public ERC20Rollup(bridgeAddress) ERC20PresetMinterPauser(name, symbol) {
        _setupDecimals(decimals);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Rollup) {
        return super._transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Rollup)
    {
        return super._mint(account, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Rollup)
    {
        return super._burn(account, amount);
    }

    function totalSupply()
        public
        view
        virtual
        override(ERC20, ERC20Rollup)
        returns (uint256)
    {
        return super.totalSupply();
    }

    function balanceOf(address account)
        public
        view
        virtual
        override(ERC20, ERC20Rollup)
        returns (uint256)
    {
        return super.balanceOf(account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _beforeRecoverRollupState(RollupProposal memory)
        internal
        override
    {}

    function _afterRecoverRollupState(RollupProposal memory)
        internal
        override
    {}
}
