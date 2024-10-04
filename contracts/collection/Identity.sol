// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v1.0.1 (contracts/collection/Identity.sol)

pragma solidity ^0.8.0;

import "../access/AccessControl.sol";
import "../access/AccountControl.sol";
import "../utils/Multisig.sol";

/**
 * @title Identity
 * @dev A contract that provides access and account control using multisig and role-based permissions.
 */
contract Identity is AccessControl, AccountControl, Multisig {
    uint256 private _scluster; // small cluster of signers
    uint256 private _bcluster; // big cluster of signers

    // TODO: define owner role
    uint64 public constant OWNER_ROLE = 1 << 1;
    // TODO: define manager role
    uint64 public constant MANAGER_ROLE = 1 << 2;
    // TODO: define operator role
    uint64 public constant OPERATOR_ROLE = 1 << 3;

    /**
     * @dev Forward the accountOf as msg.sender.
     * @return The address of the sender account.
     */
    function _msgSender() internal view override returns (address) {
        return accountOf(super._msgSender());
    }

    /**
     *@dev Check if all signers have the specified role.
     */
    modifier signersWithRole(uint64 role) {
        for (uint256 i = 0; i < signers().length; i++) {
            require(hasRole(role, accountOf(signers(i))), "Identity: invalid role for signer");
        }
        _;
    }

    /**
     * @dev Constructor function.
     * @param name The name of the contract.
     * @param scluster_ The number of signers for small cluster.
     * @param bcluster_ The number of signers for big cluster.
     * @param admin The addresses of the admin signers.
     * @param owner The addresses of the owner signers.
     * @param manager The addresses of the manager signers.
     * @param operator The addresses of the operator signers.
     * @param _metadata The metadata of the contract.
     */
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

    /**
     * @dev Grants the specified role to the specified account if the current signers
     *  have the admin role for the specified role. This function requires a multisig
     *  of the specified big cluster of signers.
     * @param role The role to grant.
     * @param account The address to grant the role to.
     */
    function grantRole(
        uint64 role,
        address account
    ) public virtual override requireSignatures(_bcluster) signersWithRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes the specified role from the specified account if the current signers
     * have the admin role for the specified role. This function requires a multisig
     * of the specified big cluster of signers.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(
        uint64 role,
        address account
    ) public virtual override requireSignatures(_bcluster) signersWithRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    // account control

    /**
     * @dev Adds a new signer with the specified address and metadata. This function requires
     * a multisig of the specified small cluster of signers and the caller must have the manager role.
     * @param signer The address of the signer to add.
     * @param account The account associated with the signer.
     * @param _metadata The metadata associated with the signer.
     */
    function addSigner(
        address signer,
        address account,
        string memory _metadata
    ) public virtual override requireSignatures(_scluster) signersWithRole(MANAGER_ROLE) {
        _addSigner(signer, account, _metadata);
    }

    /**
     * @dev Removes a signer with the specified address and metadata. This function requires
     * the caller to have either the manager or operator role.
     * @param signer The address of the signer to remove.
     * @param _metadata The metadata associated with the signer.
     */
    function removeSigner(
        address signer,
        string memory _metadata
    ) public virtual override onlyRole(MANAGER_ROLE | OPERATOR_ROLE) {
        _removeSigner(signer, _metadata);
    }

    // bulk actions

    /**
     * @dev Adds multiple signers with the specified addresses and metadata. This function requires
     * a multisig of the specified small cluster of signers and the caller must have the manager role.
     * @param signer The addresses of the signers to add.
     * @param account The accounts associated with the signers.
     * @param _metadata The metadata associated with the signers.
     */
    function _bulkAddSigner(address[] memory signer, address[] memory account, string memory _metadata) internal {
        require(signer.length <= 100, "Identity: bulk capacity exceded");
        require(signer.length == account.length, "Identity: bulk arrays must have same length");
        for (uint256 i = 0; i < signer.length; i++) {
            _addSigner(signer[i], account[i], _metadata);
        }
    }

    /**
     * @dev Grants the specified role to multiple accounts. This function requires
     * a multisig of the specified big cluster of signers.
     * @param role The role to grant.
     * @param accounts The addresses to grant the role to.
     */
    function _bulkGrantRole(uint64 role, address[] memory accounts) internal {
        require(accounts.length <= 100, "Identity: bulk capacity exceded");
        for (uint256 i = 0; i < accounts.length; i++) {
            _grantRole(role, accounts[i]);
        }
    }
}
