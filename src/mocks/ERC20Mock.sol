// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts (v1.0.1) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../access/IAccountControl.sol";

contract ERC20Mock is ERC20 {
    IAccountControl private _accounts;

    constructor(
        string memory name,
        uint256 supply,
        string memory symbol,
        IAccountControl accounts
    ) ERC20(name, symbol) {
        _accounts = accounts;
        _mint(_msgSender(), supply);
    }

    function _msgSender() internal view override returns (address) {
        return _accounts.accountOf(super._msgSender());
    }
}
