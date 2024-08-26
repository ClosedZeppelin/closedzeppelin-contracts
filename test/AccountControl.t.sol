// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AccountControlMock} from "../src/mocks/AccountControlMock.sol";

contract AccountControlTest is Test {
    AccountControlMock public accountControl;

    address admin;
    address account1;
    address account2;
    address account3;
    string constant _metadata = "metadata";
    address constant zeroAccount = address(0);

    function setUp() public {
        accountControl = new AccountControlMock();
    }

    function testAdminAccountIsRegistered() public view {
        assertEq(accountControl.accountOf(admin), admin);
    }

    function testNonAdminCannotEditAccountSigner() public {
        vm.prank(account1);
        vm.expectRevert("AccessControl: account is missing role");
        accountControl.addSigner(account2, account3, _metadata);
    }

    function testAdminCanCreateAccountSigner() public {
        vm.prank(admin);

        accountControl.addSigner(account2, account2, _metadata);
    }

    function testAdminCanEditAccountSigner() public {
        vm.prank(admin);

        accountControl.addSigner(account2, account3, _metadata);
    }

    function testNonAdminCannotRemoveAccountSigner() public {
        vm.prank(account1);
        vm.expectRevert("AccessControl: account is missing role");
        accountControl.removeSigner(account2, _metadata);
    }

    function testAdminCanRemoveAccountSigner() public {
        vm.prank(admin);
        accountControl.addSigner(account2, account3, _metadata);

        accountControl.removeSigner(account2, _metadata);
    }

    function testReturnsZeroAddressForNonRegisteredUser() public view {
        assertEq(accountControl.accountOf(account3), zeroAccount);
    }

    function testReturnsCorrectAddressForRegisteredUser() public {
        vm.prank(admin);
        accountControl.addSigner(account2, account3, _metadata);
        assertEq(accountControl.accountOf(account2), account3);
    }
}
