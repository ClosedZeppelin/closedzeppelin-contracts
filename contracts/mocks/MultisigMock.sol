// SPDX-License-Identifier: MIT
// ClosedZeppelin Contracts v1.0.1 (utils/Context.sol)

pragma solidity ^0.8.0;

import "../utils/Multisig.sol";

contract MultisigMock is Multisig {
    string public data;

    function currentSigners() public view returns (address[] memory) {
        return signers();
    }

    function func(int256 data1, string memory data2) public requireSignatures(2) returns (int256) {
        data = data2;
        return data1;
    }
}
