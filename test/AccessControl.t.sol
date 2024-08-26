// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AccessControlMock} from "../src/mocks/AccessControlMock.sol";

contract AccessControlTest is Test {
    AccessControlMock public accessControl;

    uint64 constant DEFAULT_ADMIN_ROLE = 1;
    uint64 constant ROLE = 1 << 1;
    uint64 constant OTHER_ROLE = 1 << 2;

    address admin;
    address authorized;
    address other;
    address otherAdmin;

    function setUp() public {
        accessControl = new AccessControlMock();

        admin = address(this);
        authorized = address(0x1);
        other = address(0x2);
        otherAdmin = address(0x3);

        accessControl.setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        accessControl.setRoleAdmin(ROLE, DEFAULT_ADMIN_ROLE);
        accessControl.setRoleAdmin(OTHER_ROLE, DEFAULT_ADMIN_ROLE);
        accessControl.grantRole(OTHER_ROLE, otherAdmin);
    }

    function testDefaultAdmin() public view {
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertEq(accessControl.getRoleAdmin(ROLE), DEFAULT_ADMIN_ROLE);
        assertEq(
            accessControl.getRoleAdmin(DEFAULT_ADMIN_ROLE),
            DEFAULT_ADMIN_ROLE
        );
    }

    function testGranting() public {
        accessControl.grantRole(ROLE, authorized);

        vm.prank(other);
        vm.expectRevert("AccessControl: account is missing role");
        accessControl.grantRole(ROLE, authorized);

        accessControl.grantRole(ROLE, authorized);
    }

    function testRevoking() public {
        assertFalse(accessControl.hasRole(ROLE, authorized));

        accessControl.revokeRole(ROLE, authorized);

        accessControl.grantRole(ROLE, authorized);

        accessControl.revokeRole(ROLE, authorized);

        assertFalse(accessControl.hasRole(ROLE, authorized));

        vm.prank(other);
        vm.expectRevert("AccessControl: account is missing role");
        accessControl.revokeRole(ROLE, authorized);

        accessControl.revokeRole(ROLE, authorized);
    }

    function testRenouncing() public {
        vm.prank(authorized);
        accessControl.renounceRole(ROLE, authorized);

        accessControl.grantRole(ROLE, authorized);

        vm.prank(authorized);
        accessControl.renounceRole(ROLE, authorized);

        assertFalse(accessControl.hasRole(ROLE, authorized));

        vm.expectRevert("AccessControl: can only renounce roles for self");
        accessControl.renounceRole(ROLE, authorized);

        vm.prank(authorized);
        accessControl.renounceRole(ROLE, authorized);
    }

    function testSettingRoleAdmin() public {
        accessControl.setRoleAdmin(ROLE, OTHER_ROLE);

        assertEq(accessControl.getRoleAdmin(ROLE), OTHER_ROLE);

        vm.prank(otherAdmin);
        accessControl.grantRole(ROLE, authorized);

        vm.prank(otherAdmin);
        accessControl.revokeRole(ROLE, authorized);

        vm.expectRevert("AccessControl: account is missing role");
        accessControl.grantRole(ROLE, authorized);

        vm.expectRevert("AccessControl: account is missing role");
        accessControl.revokeRole(ROLE, authorized);
    }

    function testOnlyRoleModifier() public {
        accessControl.grantRole(ROLE, authorized);

        vm.prank(authorized);
        accessControl.senderProtected(ROLE);

        vm.prank(other);
        vm.expectRevert("AccessControl: account is missing role");
        accessControl.senderProtected(ROLE);

        vm.prank(authorized);
        vm.expectRevert("AccessControl: account is missing role");
        accessControl.senderProtected(OTHER_ROLE);
    }
}
