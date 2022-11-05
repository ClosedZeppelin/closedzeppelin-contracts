import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract } from 'ethers';

describe('AccessControl', function () {
  let accessControl: Contract;

  const DEFAULT_ADMIN_ROLE: number = 1;
  const ROLE: number = 1 << 1;
  const OTHER_ROLE: number = 1 << 2;

  let admin: SignerWithAddress;
  let authorized: SignerWithAddress;
  let other: SignerWithAddress;
  let otherAdmin: SignerWithAddress;

  beforeEach(async () => {
    const AccessControlMock = await ethers.getContractFactory('AccessControlMock');
    accessControl = await AccessControlMock.deploy();
    await accessControl.deployed();

    [admin, authorized, other, otherAdmin] = await ethers.getSigners();

    await accessControl.setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    await accessControl.setRoleAdmin(ROLE, DEFAULT_ADMIN_ROLE);
    await accessControl.setRoleAdmin(OTHER_ROLE, DEFAULT_ADMIN_ROLE);
    await accessControl.grantRole(OTHER_ROLE, otherAdmin.address);
  });

  describe('default admin', function () {
    it('deployer has default admin role', async function () {
      expect(await accessControl.hasRole(DEFAULT_ADMIN_ROLE, admin.address)).to.equal(true);
    });

    it("other roles's admin is the default admin role", async function () {
      expect(await accessControl.getRoleAdmin(ROLE)).to.equal(DEFAULT_ADMIN_ROLE);
    });

    it("default admin role's admin is itself", async function () {
      expect(await accessControl.getRoleAdmin(DEFAULT_ADMIN_ROLE)).to.equal(DEFAULT_ADMIN_ROLE);
    });
  });

  describe('granting', function () {
    beforeEach(async function () {
      await accessControl.grantRole(ROLE, authorized.address);
    });

    it('non-admin cannot grant role to other accounts', async function () {
      await expect(accessControl.connect(other).grantRole(ROLE, authorized.address)).to.be.revertedWith(
        'AccessControl: account is missing role',
      );
    });

    it('accounts can be granted a role multiple times', async function () {
      await expect(accessControl.grantRole(ROLE, authorized.address))
        .to.emit(accessControl, 'RoleGranted')
        .withArgs(ROLE, authorized.address, admin.address);
    });
  });

  describe('revoking', function () {
    it('roles that are not had can be revoked', async function () {
      expect(await accessControl.hasRole(ROLE, authorized.address)).to.equal(false);

      await expect(accessControl.revokeRole(ROLE, authorized.address))
        .to.emit(accessControl, 'RoleRevoked')
        .withArgs(ROLE, authorized.address, admin.address);
    });

    context('with granted role', function () {
      beforeEach(async function () {
        await accessControl.grantRole(ROLE, authorized.address);
      });

      it('admin can revoke role', async function () {
        await expect(accessControl.revokeRole(ROLE, authorized.address))
          .to.emit(accessControl, 'RoleRevoked')
          .withArgs(ROLE, authorized.address, admin.address);

        expect(await accessControl.hasRole(ROLE, authorized.address)).to.equal(false);
      });

      it('non-admin cannot revoke role', async function () {
        await expect(accessControl.connect(other).revokeRole(ROLE, authorized.address)).to.be.revertedWith(
          'AccessControl: account is missing role',
        );
      });

      it('a role can be revoked multiple times', async function () {
        await expect(accessControl.revokeRole(ROLE, authorized.address))
          .to.emit(accessControl, 'RoleRevoked')
          .withArgs(ROLE, authorized.address, admin.address);
      });
    });
  });

  describe('renouncing', function () {
    it('roles that are not had can be renounced', async function () {
      await expect(accessControl.connect(authorized).renounceRole(ROLE, authorized.address))
        .to.emit(accessControl, 'RoleRevoked')
        .withArgs(ROLE, authorized.address, authorized.address);
    });

    context('with granted role', function () {
      beforeEach(async function () {
        await accessControl.grantRole(ROLE, authorized.address);
      });

      it('bearer can renounce role', async function () {
        await expect(accessControl.connect(authorized).renounceRole(ROLE, authorized.address))
          .to.emit(accessControl, 'RoleRevoked')
          .withArgs(ROLE, authorized.address, authorized.address);

        expect(await accessControl.hasRole(ROLE, authorized.address)).to.equal(false);
      });

      it('only the sender can renounce their roles', async function () {
        await expect(accessControl.renounceRole(ROLE, authorized.address)).to.be.revertedWith(
          'AccessControl: can only renounce roles for self',
        );
      });

      it('a role can be renounced multiple times', async function () {
        await expect(accessControl.connect(authorized).renounceRole(ROLE, authorized.address))
          .to.emit(accessControl, 'RoleRevoked')
          .withArgs(ROLE, authorized.address, authorized.address);
      });
    });
  });

  describe('setting role admin', function () {
    beforeEach(async function () {
      await expect(accessControl.setRoleAdmin(ROLE, OTHER_ROLE))
        .to.emit(accessControl, 'RoleAdminChanged')
        .withArgs(ROLE, DEFAULT_ADMIN_ROLE, OTHER_ROLE);
    });

    it("a role's admin role can be changed", async function () {
      expect(await accessControl.getRoleAdmin(ROLE)).to.equal(OTHER_ROLE);
    });

    it('the new admin can grant roles', async function () {
      await expect(accessControl.connect(otherAdmin).grantRole(ROLE, authorized.address))
        .to.emit(accessControl, 'RoleGranted')
        .withArgs(ROLE, authorized.address, otherAdmin.address);
    });

    it('the new admin can revoke roles', async function () {
      await accessControl.connect(otherAdmin).grantRole(ROLE, authorized.address);

      await expect(accessControl.connect(otherAdmin).revokeRole(ROLE, authorized.address))
        .to.emit(accessControl, 'RoleRevoked')
        .withArgs(ROLE, authorized.address, otherAdmin.address);
    });

    it("a role's previous admins no longer grant roles", async function () {
      await expect(accessControl.grantRole(ROLE, authorized.address)).to.be.revertedWith(
        'AccessControl: account is missing role',
      );
    });

    it("a role's previous admins no longer revoke roles", async function () {
      await expect(accessControl.revokeRole(ROLE, authorized.address)).to.be.revertedWith(
        'AccessControl: account is missing role',
      );
    });
  });

  describe('onlyRole modifier', function () {
    beforeEach(async function () {
      await accessControl.grantRole(ROLE, authorized.address);
    });

    it('do not revert if sender has role', async function () {
      await accessControl.connect(authorized).senderProtected(ROLE);
    });

    it("revert if sender doesn't have role #1", async function () {
      await expect(accessControl.connect(other).senderProtected(ROLE)).to.be.revertedWith(
        'AccessControl: account is missing role',
      );
    });

    it("revert if sender doesn't have role #2", async function () {
      await expect(accessControl.connect(authorized).senderProtected(OTHER_ROLE)).to.be.revertedWith(
        'AccessControl: account is missing role',
      );
    });
  });
});
