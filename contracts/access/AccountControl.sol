// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v4.4.1 (access/AccountControl.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IAccountControl.sol";

abstract contract AccountControl is IAccountControl, ERC165 {
    mapping(address => address) private _accounts;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccountControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function accountOf(address signer) public view returns (address) {
        return _accounts[signer];
    }

    function _addSigner(
        address signer,
        address account,
        string memory _metadata
    ) internal virtual returns (bool) {
        _accounts[signer] = account;
        if (signer == account) emit AccountCreated(account, msg.sender, _metadata);
        else emit SignerAdded(signer, account, msg.sender, _metadata);
        return true;
    }

    function _removeSigner(address signer, string memory _metadata) internal virtual returns (bool) {
        delete _accounts[signer];
        emit SignerRemoved(signer, msg.sender, _metadata);
        return true;
    }
}
