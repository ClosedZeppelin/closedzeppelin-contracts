// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v4.4.1 (access/AccountControl.sol)

pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "./IAccountControl.sol";

abstract contract AccountControl is IAccountControl, ERC165 {
    mapping(address => address) private _accounts;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccountControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IAccountControl-accountOf}.
     */
    function accountOf(address signer) public view returns (address) {
        return _accounts[signer];
    }

    /**
     * @dev See {IAccountControl-addSigner}.
     */
    function addSigner(address signer, address account, string memory _metadata) external virtual {
        return _addSigner(signer, account, _metadata);
    }

    /**
     * @dev See {IAccountControl-removeSigner}.
     */
    function removeSigner(address signer, string memory _metadata) external virtual {
        return _removeSigner(signer, _metadata);
    }

    /**
     * @dev Adds a new signer to an account.
     * @param signer The address of the new signer.
     * @param account The address of the account to which the signer will be added.
     * @param _metadata Additional metadata associated with the signer addition.
     */
    function _addSigner(address signer, address account, string memory _metadata) internal virtual {
        _accounts[signer] = account;
        if (signer == account) emit AccountCreated(account, msg.sender, _metadata);
        else emit SignerAdded(signer, account, msg.sender, _metadata);
    }

    /**
     * @dev Removes a signer from an account.
     * @param signer The address of the signer to remove.
     * @param _metadata Additional metadata associated with the signer removal.
     */
    function _removeSigner(address signer, string memory _metadata) internal virtual {
        delete _accounts[signer];
        emit SignerRemoved(signer, msg.sender, _metadata);
    }
}
