// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../contracts/access/AccessControl.sol";
import "../../contracts/access/AccountControl.sol";

contract AccountControlMock is AccountControl, AccessControl {
    constructor() {
        _addSigner(msg.sender, msg.sender, "owner");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setRoleAdmin(uint64 roleId, uint64 adminRoleId) public {
        _setRoleAdmin(roleId, adminRoleId);
    }

    function addSigner(
        address signer,
        address account,
        string memory _metadata
    ) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _addSigner(signer, account, _metadata);
    }

    function removeSigner(
        address signer,
        string memory _metadata
    ) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeSigner(signer, _metadata);
    }
}
