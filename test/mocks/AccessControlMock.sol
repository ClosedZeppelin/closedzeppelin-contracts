// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../contracts/access/AccessControl.sol";

contract AccessControlMock is AccessControl {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setRoleAdmin(uint64 roleId, uint64 adminRoleId) public {
        _setRoleAdmin(roleId, adminRoleId);
    }

    function senderProtected(uint64 roleId) public onlyRole(roleId) {}
}
