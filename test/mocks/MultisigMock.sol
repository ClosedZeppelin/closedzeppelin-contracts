// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v1.0.1 (utils/Context.sol)

pragma solidity ^0.8.0;

import "../../contracts/utils/Multisig.sol";

contract MultisigMock is Multisig {
    string public data;

    constructor() Multisig("MultisigMock") {
        data = "invalid data";
    }

    function currentSigners() public view returns (address[] memory) {
        return signers();
    }

    function check(address sig1, address sig2) public requireSignatures(2) returns (bool) {
        require(sig1 == signers(0), "invalid signer 1");
        require(sig2 == signers(1), "invalid signer 2");
        data = "signers are correct";
        return true;
    }

    function func(int256 data1, string memory data2) public requireSignatures(2) returns (int256) {
        data = data2;
        return data1;
    }

    function func2(string memory data1) public disableMultisig returns (bool) {
        data = data1;
        return true;
    }
}
