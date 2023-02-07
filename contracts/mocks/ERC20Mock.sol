// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts (v1.0.1) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../access/IAccountControl.sol";

contract ERC20Mock is ERC20 {
    IAccountControl private _accounts;
    uint8 private _decimals;

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    constructor(
        string memory name_,
        uint256 totalSupply_,
        string memory symbol_,
        uint8 decimals_,
        address accounts_
    ) ERC20(name_, symbol_) {
        _accounts = IAccountControl(accounts_);
        _decimals = decimals_;
        _mint(_msgSender(), totalSupply_ * 10**decimals());
    }

    function _msgSender() internal view override returns (address) {
        return _accounts.accountOf(msg.sender);
    }
}
