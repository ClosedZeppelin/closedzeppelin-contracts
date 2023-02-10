// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v1.0.1 (utils/Context.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract Multisig {
    address[] internal signers;
    bool private _usingMultisig;

    modifier requireMultisig(uint256 min) {
        require(_usingMultisig, "multisig required");
        require(signers.length >= min, "not enough signers");
        _;
    }

    function execute(bytes calldata execution, bytes[] memory signatures) public returns (bytes memory result) {
        bytes32 _hash = keccak256(execution);
        signers = new address[](signatures.length);
        for (uint256 i = 0; i < signatures.length; i++) {
            signers[i] = _recoverSigner(_hash, signatures[i]);
        }
        _usingMultisig = true;
        result = Address.functionDelegateCall(address(this), execution);
        _usingMultisig = false;
        signers = new address[](0);
        return result;
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
