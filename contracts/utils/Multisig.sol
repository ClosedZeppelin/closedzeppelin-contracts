// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v1.0.1 (utils/Context.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract Multisig {
    // State to know if multisig call is being used
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function _multisigBefore() private {
        // On the first call to multisig, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "Multisig: reentrant call");

        // Any calls to multisig after this point will fail
        _status = _ENTERED;
    }

    function _multisigAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier usingMultisig() {
        _multisigBefore();
        _;
        _multisigAfter();
    }

    // Signers to allow contracts called by using multisig to perform data checks
    address[] private _signers;

    modifier resetSigners() {
        address[] memory _value = _signers;
        _;
        _signers = _value;
    }

    function signers() internal view returns (address[] memory) {
        return _signers;
    }

    // multisig is required
    modifier requireSignatures(uint256 min) {
        require(_status == _ENTERED, "multisig required");
        require(_signers.length >= min, "not enough signers");
        _;
    }

    // executes a contract call by checking authorizers
    function execute(bytes calldata execution, bytes[] memory signatures)
        public
        usingMultisig
        resetSigners
        returns (bytes memory result)
    {
        bytes32 _hash = keccak256(execution);
        _signers = new address[](signatures.length);
        for (uint256 i = 0; i < signatures.length; i++) {
            _signers[i] = _recoverSigner(_hash, signatures[i]);
        }
        return Address.functionDelegateCall(address(this), execution);
    }

    function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}
