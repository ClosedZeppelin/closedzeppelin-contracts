// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {AccountControlMock} from "./mocks/AccountControlMock.sol";
import {IAccountControl} from "../contracts/access/IAccountControl.sol";

contract ERC20Test is Test {
    ERC20Mock public token;
    AccountControlMock public accounts;

    address constant zeroAccount = address(0);
    string constant _metadata = "metadata";

    address admin;
    address account1;
    address account2;
    address account3;

    function setUp() public {
        // deploy accounts control
        accounts = new AccountControlMock();

        // deploy erc20
        token = new ERC20Mock("Token Name", 100, "Token Symbol", IAccountControl(address(accounts)));

        admin = address(this);
        account1 = address(0x1);
        account2 = address(0x2);
        account3 = address(0x3);

        accounts.addSigner(account1, account2, _metadata);
    }

    function testAdminAccountHasInitialMintingBalance() public view {
        assertEq(token.balanceOf(admin), 100);
    }

    function testNonSignerCannotSpendMoney() public {
        token.transfer(account2, 10);
        assertEq(token.balanceOf(account2), 10);

        vm.prank(account2);
        vm.expectRevert("ERC20: transfer from the zero address");
        token.transfer(account3, 5);
    }

    function testSignerCanSpendMoney() public {
        token.transfer(account2, 10);
        assertEq(token.balanceOf(account1), 0);

        vm.prank(account1);
        token.transfer(account3, 5);

        assertEq(token.balanceOf(account3), 5);
        assertEq(token.balanceOf(account2), 5);
    }
}
