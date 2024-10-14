// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v1.0.1 (utils/Multisig.sol)

pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts/contracts/utils/Context.sol";
import "openzeppelin-contracts/contracts/utils/Nonces.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

abstract contract Multisig is Context, EIP712, Nonces, ReentrancyGuard {
    bytes32 private immutable _EXECUTION_TYPEHASH =
        keccak256("Execute(bytes32 call,address sender,uint256 nonce,uint256 deadline)");

    // Signers accessibility to allow contracts called by using multisig to perform data checks
    address[] private _signers;

    /**
     * @dev Modifier that requires a certain number of signatures to have been provided.
     *      This modifier can only be used within the context of a multisig call.
     * @param min The minimum number of signatures required.
     */
    modifier requireSignatures(uint256 min) {
        require(_reentrancyGuardEntered(), "Multisig: required");
        require(_signers.length >= min, "Multisig: not enough signers");
        _;
    }

    /**
     * @dev Modifier to disable multisig execution for a function.
     */
    modifier disableMultisig() {
        require(!_reentrancyGuardEntered(), "Multisig: disabled");
        _;
    }

    /**
     * @dev Constructor function that sets up the EIP712 version.
     * @param name The name of the contract.
     */
    constructor(string memory name) EIP712(name, "1") {} // Setup version

    /**
     * @dev Executes a multisig operation.
     * @param execution The execution data to be executed.
     * @param deadline The deadline by which the operation must be executed.
     * @param signatures The signatures authorizing the operation.
     * @return The result of the execution.
     */
    function execute(
        bytes calldata execution,
        uint256 deadline,
        bytes[] memory signatures
    ) public nonReentrant cleanSigners returns (bytes memory) {
        require(block.timestamp <= deadline, "Multisig: execution expired");

        bytes32 structHash = keccak256(
            abi.encode(_EXECUTION_TYPEHASH, keccak256(execution), _msgSender(), _useNonce(_msgSender()), deadline)
        );

        bytes32 digest = _hashTypedDataV4(structHash);

        _signers = new address[](signatures.length);
        for (uint256 i = 0; i < _signers.length; i++) {
            _signers[i] = ECDSA.recover(digest, signatures[i]);
            require(i == 0 || _signers[i - 1] < _signers[i], "Multisig: unsorted signers"); // avoid repeated signatures
        }

        return Address.functionDelegateCall(address(this), execution);
    }

    /**
     * @dev Internal function that returns an array of addresses representing the signers of the multisig.
     * @return address[] representing the signers.
     */
    function signers() internal view returns (address[] memory) {
        return _signers;
    }

    /**
     * @dev Internal function that returns the address of a signer in the multisig at a specific index.
     * @param index uint256 representing the index of the signer to retrieve.
     * @return address representing the signer at the given index.
     */
    function signers(uint256 index) internal view returns (address) {
        return _signers[index];
    }

    /**
     * @dev Modifier to clean the signers array after the function is executed.
     */
    modifier cleanSigners() {
        _;
        delete _signers;
    }
}
