// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v1.0.1 (contracts/collection/Identity.sol)

pragma solidity ^0.8.0;

import "../access/AccessControl.sol";
import "../access/AccountControl.sol";
import "../utils/Multisig.sol";

contract Identity is AccessControl, AccountControl, Multisig {
    uint256 private _scluster; // small cluster of signers
    uint256 private _bcluster; // big cluster of signers

    // TODO: define owner role
    uint64 public constant OWNER_ROLE = 1 << 1;
    // TODO: define manager role
    uint64 public constant MANAGER_ROLE = 1 << 2;
    // TODO: define operator role
    uint64 public constant OPERATOR_ROLE = 1 << 3;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, AccountControl, Multisig)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            AccountControl.supportsInterface(interfaceId) ||
            Multisig.supportsInterface(interfaceId);
    }

    // use accountOf as msg.sender forward
    function _msgSender() internal view override returns (address) {
        return accountOf(super._msgSender());
    }

    // check all signers has the specified role
    modifier signersWithRole(uint64 role) {
        for (uint256 i = 0; i < signers().length; i++) {
            require(hasRole(role, accountOf(signers(i))), "Identity: invalid role for signer");
        }
        _;
    }

    constructor(
        string memory name,
        uint256 scluster_,
        uint256 bcluster_,
        address[] memory admin,
        address[] memory owner,
        address[] memory manager,
        address[] memory operator,
        string memory _metadata
    ) Multisig(name) {
        require(admin.length >= bcluster_, "Identity: not enough admin for big cluster");

        _scluster = scluster_;
        _bcluster = bcluster_;

        _bulkAddSigner(admin, admin, _metadata);
        _bulkAddSigner(owner, owner, _metadata);
        _bulkAddSigner(manager, manager, _metadata);
        _bulkAddSigner(operator, operator, _metadata);

        _bulkGrantRole(DEFAULT_ADMIN_ROLE, admin);
        _bulkGrantRole(OWNER_ROLE, owner);
        _bulkGrantRole(MANAGER_ROLE, manager);
        _bulkGrantRole(OPERATOR_ROLE, operator);

        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(OWNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGER_ROLE, OWNER_ROLE);
        _setRoleAdmin(OPERATOR_ROLE, MANAGER_ROLE | OWNER_ROLE);
    }

    // access control

    function grantRole(uint64 role, address account)
        public
        virtual
        override
        requireSignatures(_bcluster)
        signersWithRole(getRoleAdmin(role))
    {
        return _grantRole(role, account);
    }

    function revokeRole(uint64 role, address account)
        public
        virtual
        override
        requireSignatures(_bcluster)
        signersWithRole(getRoleAdmin(role))
    {
        return _revokeRole(role, account);
    }

    // account control

    function addSigner(
        address signer,
        address account,
        string memory _metadata
    ) public virtual override requireSignatures(_scluster) signersWithRole(MANAGER_ROLE) returns (bool) {
        return _addSigner(signer, account, _metadata);
    }

    function removeSigner(address signer, string memory _metadata)
        public
        virtual
        override
        onlyRole(MANAGER_ROLE | OPERATOR_ROLE)
        returns (bool)
    {
        return _removeSigner(signer, _metadata);
    }

    // bulk actions

    function _bulkAddSigner(
        address[] memory signer,
        address[] memory account,
        string memory _metadata
    ) internal {
        require(signer.length <= 100, "Identity: bulk capacity exceded");
        require(signer.length == account.length, "Identity: bulk arrays must have same length");
        for (uint256 i = 0; i < signer.length; i++) {
            _addSigner(signer[i], account[i], _metadata);
        }
    }

    function _bulkGrantRole(uint64 role, address[] memory accounts) internal {
        require(accounts.length <= 100, "Identity: bulk capacity exceded");
        for (uint256 i = 0; i < accounts.length; i++) {
            _grantRole(role, accounts[i]);
        }
    }
}
