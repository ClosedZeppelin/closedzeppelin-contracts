// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Identity} from "../contracts/collection/Identity.sol";
import {Utils} from "./utils.t.sol";

contract IdentityTest is Test {
    Identity public identity;
    uint256 public deadline;

    address public admin;
    address public account1;
    address public account2;
    address public account3;
    address public account4; // has no roles

    uint64 constant DEFAULT_ADMIN_ROLE = 1 << 0;
    uint64 constant ADMIN_ROLE = 1 << 1;
    uint64 constant MANAGER_ROLE = 1 << 2;
    uint64 constant OPERATOR_ROLE = 1 << 3;

    string constant _metadata = "reason";
    address constant _account = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        admin = address(this);
        account1 = makeAddr("account1");
        account2 = makeAddr("account2");
        account3 = makeAddr("account3");
        account4 = makeAddr("account4");

        deadline = block.timestamp + 1000;

        address[] memory accounts = new address[](3);
        accounts[0] = account1;
        accounts[1] = account2;
        accounts[2] = account3;

        identity = new Identity("ClosedZeppelin - ID", 2, 3, accounts, accounts, accounts, accounts, "closed-zeppelin identity initial role");
    }

    function testConstructor() public view {
        assertEq(identity.hasRole(DEFAULT_ADMIN_ROLE, admin), false);
        assertEq(identity.hasRole(DEFAULT_ADMIN_ROLE, account1), true);
        assertEq(identity.hasRole(DEFAULT_ADMIN_ROLE, account2), true);
        assertEq(identity.hasRole(DEFAULT_ADMIN_ROLE, account3), true);

        assertEq(identity.accountOf(account1), account1);
        assertEq(identity.accountOf(account2), account2);
        assertEq(identity.accountOf(account3), account3);
    }

    function testGrantRoleFailsWithoutMultisig() public {
        vm.expectRevert("Multisig: required");
        identity.grantRole(OPERATOR_ROLE, _account);
    }

    function testGrantRoleFailsWithoutEnoughSignatures() public {
        bytes memory call = abi.encodeWithSignature("grantRole(uint256,address)", OPERATOR_ROLE, account4);
        bytes memory sig1 = _signTypedData(account1, call);
        bytes memory sig2 = _signTypedData(account2, call);

        vm.expectRevert("Multisig: not enough signers");
        identity.execute(call, deadline, Utils._twoBytes(sig1, sig2));
    }

    function testGrantRoleFailsWithInvalidSigners() public {
        bytes memory call = abi.encodeWithSignature("grantRole(uint256,address)", OPERATOR_ROLE, account4);
        bytes memory sig1 = _signTypedData(account4, call); // not admin
        bytes memory sig2 = _signTypedData(account2, call);
        bytes memory sig3 = _signTypedData(account3, call);

        vm.expectRevert("Identity: invalid role for signer");
        identity.execute(call, deadline, Utils._threeBytes(sig1, sig2, sig3));
    }

    function testGrantRoleSucceeds() public {
        bytes memory call = abi.encodeWithSignature("grantRole(uint256,address)", OPERATOR_ROLE, account4);
        bytes memory sig1 = _signTypedData(account1, call);
        bytes memory sig2 = _signTypedData(account2, call);
        bytes memory sig3 = _signTypedData(account3, call);

        identity.execute(call, deadline, Utils._threeBytes(sig2, sig1, sig3));
        assertEq(identity.hasRole(OPERATOR_ROLE, account4), true);
    }

    function testRevokeRoleFailsWithoutMultisig() public {
        vm.expectRevert("Multisig: required");
        identity.revokeRole(ADMIN_ROLE, _account);
    }

    function testRevokeRoleFailsWithoutEnoughSignatures() public {
        bytes memory call = abi.encodeWithSignature("revokeRole(uint256,address)", OPERATOR_ROLE, account3);
        bytes memory sig1 = _signTypedData(account1, call);
        bytes memory sig2 = _signTypedData(account2, call);

        vm.expectRevert("Multisig: not enough signers");
        identity.execute(call, deadline, Utils._twoBytes(sig2, sig1));
    }

    function testRevokeRoleFailsWithInvalidSigners() public {
        bytes memory call = abi.encodeWithSignature("revokeRole(uint256,address)", OPERATOR_ROLE, account3);
        bytes memory sig1 = _signTypedData(account4, call); // not admin
        bytes memory sig2 = _signTypedData(account2, call);
        bytes memory sig3 = _signTypedData(account3, call);

        vm.expectRevert("Identity: invalid role for signer");
        identity.execute(call, deadline, Utils._threeBytes(sig1, sig2, sig3));
    }

    function testRevokeRoleSucceeds() public {
        bytes memory call = abi.encodeWithSignature("revokeRole(uint256,address)", OPERATOR_ROLE, account3);
        bytes memory sig1 = _signTypedData(account1, call);
        bytes memory sig2 = _signTypedData(account2, call);
        bytes memory sig3 = _signTypedData(account3, call);

        identity.execute(call, deadline, Utils._threeBytes(sig2, sig1, sig3));
        assertEq(identity.hasRole(OPERATOR_ROLE, account3), false);
    }

    function testAddSignerFailsWithoutMultisig() public {
        vm.expectRevert("Multisig: required");
        identity.addSigner(_account, _account, _metadata);
    }

    function testAddSignerFailsWithoutEnoughSignatures() public {
        bytes memory call = abi.encodeWithSignature("addSigner(address,address,string)", _account, _account, _metadata);
        bytes memory sig1 = _signTypedData(account1, call);

        vm.expectRevert("Multisig: not enough signers");
        identity.execute(call, deadline, Utils._oneByte(sig1));
    }

    function testAddSignerFailsWithInvalidSigners() public {
        bytes memory call = abi.encodeWithSignature("addSigner(address,address,string)", _account, _account, _metadata);
        bytes memory sig1 = _signTypedData(account4, call); // not admin
        bytes memory sig2 = _signTypedData(account2, call);

        vm.expectRevert("Identity: invalid role for signer");
        identity.execute(call, deadline, Utils._twoBytes(sig1, sig2));
    }

    function testAddSignerSucceeds() public {
        bytes memory call = abi.encodeWithSignature("addSigner(address,address,string)", _account, _account, _metadata);
        bytes memory sig1 = _signTypedData(account1, call);
        bytes memory sig2 = _signTypedData(account2, call);

        identity.execute(call, deadline, Utils._twoBytes(sig2, sig1));
        assertEq(identity.accountOf(_account), _account);
    }

    function testRemoveSignerFailsWithoutRequiredRoles() public {
        vm.prank(account4);
        vm.expectRevert("AccessControl: account is missing role");
        identity.removeSigner(account3, _metadata);
    }

    function testRemoveSignerSucceeds() public {
        vm.prank(account1);
        identity.removeSigner(account3, _metadata);
        assertEq(identity.accountOf(account3), address(0));
    }

    function _signTypedData(address signer, bytes memory call) internal view returns (bytes memory) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("ClosedZeppelin - ID")),
                keccak256(bytes("1")),
                block.chainid,
                address(identity)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(keccak256("Execute(bytes32 call,address sender,uint256 nonce,uint256 deadline)"), keccak256(call), admin, identity.nonces(admin), deadline)
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)), hash);
        return abi.encodePacked(r, s, v);
    }
}
