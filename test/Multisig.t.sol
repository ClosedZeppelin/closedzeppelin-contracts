// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MultisigMock} from "./mocks/MultisigMock.sol";
import {Utils} from "./utils.t.sol";

contract MultisigTest is Test {
    MultisigMock public multisig;
    uint256 public deadline;

    address public admin;
    address public account1;
    address public account2;
    address public account3;

    function setUp() public {
        multisig = new MultisigMock();
        deadline = block.timestamp + 1000;

        admin = address(this);
        account1 = makeAddr("account1");
        account2 = makeAddr("account2");
        account3 = makeAddr("account3");
    }

    function testSigners() public view {
        assertEq(multisig.currentSigners().length, 0, "Should have zero signers initially");
    }

    function testFunc2WithMultisig() public {
        bytes memory call = abi.encodeWithSignature("func2(string)", "value");
        bytes memory sig1 = _signTypedData(account1, call);

        vm.expectRevert("Multisig: disabled");
        multisig.execute(call, deadline, Utils._oneByte(sig1));
    }

    function testFunc2Direct() public {
        string memory _data = "func2 data";
        multisig.func2(_data);
        assertEq(multisig.data(), _data, "Data should be set correctly");
    }

    function testFuncDirect() public {
        vm.expectRevert("Multisig: required");
        multisig.func(100, "data");
    }

    function testFuncWithLessSignatures() public {
        bytes memory call = abi.encodeWithSignature("func(uint256,string)", 100, "value");
        bytes memory sig1 = _signTypedData(account1, call);

        vm.expectRevert("Multisig: not enough signers");
        multisig.execute(call, deadline, Utils._oneByte(sig1));

        assertEq(multisig.currentSigners().length, 0, "Should have zero signers");
    }

    function testFuncWithRepeatedSignature() public {
        bytes memory call = abi.encodeWithSignature("func(uint256,string)", 100, "value");
        bytes memory sig1 = _signTypedData(account1, call);

        vm.expectRevert("Multisig: unsorted signers");
        multisig.execute(call, deadline, Utils._twoBytes(sig1, sig1));
    }

    function testFuncWithUnsortedSigners() public {
        bytes memory call = abi.encodeWithSignature("func(uint256,string)", 100, "value");
        bytes memory sig1 = _signTypedData(account1, call);
        bytes memory sig2 = _signTypedData(account2, call);

        vm.expectRevert("Multisig: unsorted signers");
        multisig.execute(call, deadline, Utils._twoBytes(sig1, sig2));
    }

    function testFuncWithEnoughSigners() public {
        bytes memory call = abi.encodeWithSignature("func(uint256,string)", 100, "value");
        bytes memory sig1 = _signTypedData(account1, call);
        bytes memory sig2 = _signTypedData(account2, call);

        multisig.execute(call, deadline, Utils._twoBytes(sig2, sig1));
        assertEq(multisig.data(), "value", "Data should be set correctly");
        assertEq(multisig.currentSigners().length, 0, "Should have zero signers after execution");
    }

    function testFuncWithMoreThanEnoughSigners() public {
        bytes memory call = abi.encodeWithSignature("func(uint256,string)", 100, "value");
        bytes memory sig1 = _signTypedData(account1, call);
        bytes memory sig2 = _signTypedData(account2, call);
        bytes memory sig3 = _signTypedData(account3, call);

        multisig.execute(call, deadline, Utils._threeBytes(sig2, sig1, sig3));
        assertEq(multisig.data(), "value", "Data should be set correctly");
        assertEq(multisig.currentSigners().length, 0, "Should have zero signers after execution");
    }

    function testCheckInitialNonce() public view {
        assertEq(multisig.nonces(admin), 0, "Initial nonce should be zero");
    }

    function testCheckWithDifferentSigner() public {
        bytes memory call = abi.encodeWithSignature("check(address,address)", account2, account1);
        bytes memory sig2 = _signTypedData(account2, call);
        bytes memory sig3 = _signTypedData(account3, call);

        vm.expectRevert("invalid signer 2");
        multisig.execute(call, deadline, Utils._twoBytes(sig2, sig3));
    }

    function testCheckWithCorrectSigners() public {
        bytes memory call = abi.encodeWithSignature("check(address,address)", account2, account1);
        bytes memory sig1 = _signTypedData(account1, call);
        bytes memory sig2 = _signTypedData(account2, call);

        multisig.execute(call, deadline, Utils._twoBytes(sig2, sig1));
        assertEq(multisig.data(), "signers are correct", "Data should indicate correct signers");
    }

    function testCheckDoubleExecution() public {
        bytes memory call = abi.encodeWithSignature("check(address,address)", account2, account1);
        bytes memory sig1 = _signTypedData(account1, call);
        bytes memory sig2 = _signTypedData(account2, call);

        multisig.execute(call, deadline, Utils._twoBytes(sig2, sig1));
        assertEq(multisig.nonces(admin), 1, "Nonce should be incremented");

        vm.expectRevert();
        multisig.execute(call, deadline, Utils._twoBytes(sig2, sig1));
    }

    function testCheckExpiredDeadline() public {
        bytes memory call = abi.encodeWithSignature("check(address,address)", account2, account1);
        bytes memory sig1 = _signTypedData(account1, call);
        bytes memory sig2 = _signTypedData(account2, call);

        vm.warp(deadline + 1);

        vm.expectRevert("Multisig: execution expired");
        multisig.execute(call, deadline, Utils._twoBytes(sig2, sig1));
    }

    function _signTypedData(address signer, bytes memory call) internal view returns (bytes memory) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MultisigMock")),
                keccak256(bytes("1")),
                block.chainid,
                address(multisig)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Execute(bytes32 call,address sender,uint256 nonce,uint256 deadline)"),
                keccak256(call),
                admin,
                multisig.nonces(admin),
                deadline
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)), hash);
        return abi.encodePacked(r, s, v);
    }
}
