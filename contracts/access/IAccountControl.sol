// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v4.4.1 (access/IAccountControl.sol)

pragma solidity ^0.8.0;

/**
 * @title IAccountControl
 * @dev Interface for the Account Control smart contract, which manages the signing authorities associated with user accounts.
 */
interface IAccountControl {
    /**
     * @dev Emitted when a new user account is created.
     * @param account The address of the newly created account.
     * @param creator The address of the account creator.
     * @param _metadata Additional metadata associated with the account creation event.
     */
    event AccountCreated(address indexed account, address indexed creator, string _metadata);

    /**
     * @dev Emitted when a new signer is added to an account.
     * @param signer The address of the new signer.
     * @param account The address of the account to which the signer is added.
     * @param creator The address of the account creator.
     * @param _metadata Additional metadata associated with the signer addition event.
     */
    event SignerAdded(address indexed signer, address indexed account, address indexed creator, string _metadata);

    /**
     * @dev Emitted when a signer is removed from an account.
     * @param signer The address of the removed signer.
     * @param creator The address of the account creator.
     * @param _metadata Additional metadata associated with the signer removal event.
     */
    event SignerRemoved(address indexed signer, address indexed creator, string _metadata);

    /**
     * @dev Returns the account associated with a given signer address.
     * @param signer The signer address to query.
     * @return The account associated with the signer address.
     */
    function accountOf(address signer) external view returns (address);

    /**
     * @dev Adds a new signer to an account.
     * @param signer The address of the new signer.
     * @param account The address of the account to which the signer will be added.
     * @param _metadata Additional metadata associated with the signer addition.
     */
    function addSigner(
        address signer,
        address account,
        string memory _metadata
    ) external;

    /**
     * @dev Removes a signer from an account.
     * @param signer The address of the signer to remove.
     * @param _metadata Additional metadata associated with the signer removal.
     */
    function removeSigner(address signer, string memory _metadata) external;
}
