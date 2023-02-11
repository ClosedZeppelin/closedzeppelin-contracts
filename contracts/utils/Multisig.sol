// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v1.0.1 (utils/Multisig.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

abstract contract Multisig is Context, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    bytes32 private immutable _EXECUTION_TYPEHASH =
        keccak256("Execute(bytes32 call,address sender,uint256 nonce,uint256 deadline)");

    // status to know if multisig call is being used
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

    modifier _usingMultisig() {
        _multisigBefore();
        _;
        _multisigAfter();
    }

    // signers access to allow contracts called by using multisig to perform data checks
    address[] private _signers;

    modifier _resetSigners() {
        address[] memory _tmp = _signers;
        _;
        _signers = _tmp;
        _nonces[_msgSender()].increment();
    }

    // multisig is required
    modifier requireSignatures(uint256 min) {
        require(_status == _ENTERED, "Multisig: required");
        require(_signers.length >= min, "Multisig: not enough signers");
        _;
    }

    // disable multisig execution for function
    modifier disableMultisig() {
        require(_status == _NOT_ENTERED, "Multisig: disabled");
        _;
    }

    constructor(string memory name) EIP712(name, "1") {}

    function execute(
        bytes calldata execution,
        uint256 deadline,
        bytes[] memory signatures
    ) public _usingMultisig _resetSigners returns (bytes memory) {
        require(block.timestamp <= deadline, "Multisig: execution expired");

        bytes32 structHash = keccak256(
            abi.encode(
                _EXECUTION_TYPEHASH,
                keccak256(execution),
                _msgSender(),
                _nonces[_msgSender()].current(),
                deadline
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);

        _signers = new address[](signatures.length);
        for (uint256 i = 0; i < _signers.length; i++) {
            _signers[i] = ECDSA.recover(digest, signatures[i]);
        }
        return Address.functionDelegateCall(address(this), execution);
    }

    function signers(uint256 index) internal view returns (address) {
        return _signers[index];
    }

    function signers() internal view returns (address[] memory) {
        return _signers;
    }

    function nonces(address sender) public view virtual returns (uint256) {
        return _nonces[sender].current();
    }
}
