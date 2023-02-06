// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v4.4.1 (access/IAccountControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccountControl {
    event AccountCreated(address indexed account, address indexed creator, string _metadata);

    event SignerAdded(address indexed signer, address indexed account, address indexed creator, string _metadata);

    event SignerRemoved(address indexed signer, address indexed creator, string _metadata);

    function accountOf(address signer) external view returns (address);

    function addSigner(
        address signer,
        address account,
        string memory _metadata
    ) external returns (bool);

    function removeSigner(address signer, string memory _metadata) external returns (bool);
}
