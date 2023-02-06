import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract } from 'ethers';

const zeroAccount = '0x0000000000000000000000000000000000000000';

describe('AccessControl', function () {
  const _metadata = 'metadata';
  let accountControl: Contract;

  let admin: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let account3: SignerWithAddress;

  beforeEach(async () => {
    const AccountControlMock = await ethers.getContractFactory('AccountControlMock');
    accountControl = await AccountControlMock.deploy();
    await accountControl.deployed();

    [admin, account1, account2, account3] = await ethers.getSigners();
  });

  describe('addSigner', () => {
    it('non-admin cannot edit account signer', async function () {
      await expect(
        accountControl.connect(account1).addSigner(account2.address, account3.address, _metadata),
      ).to.be.revertedWith('AccessControl: account is missing role');
    });

    it('admin can create account signer', async function () {
      await expect(accountControl.addSigner(account2.address, account2.address, _metadata))
        .to.emit(accountControl, 'AccountCreated')
        .withArgs(account2.address, admin.address, _metadata);
    });

    it('admin can edit account signer', async function () {
      await expect(accountControl.addSigner(account2.address, account3.address, _metadata))
        .to.emit(accountControl, 'SignerAdded')
        .withArgs(account2.address, account3.address, admin.address, _metadata);
    });
  });

  describe('removeSigner', () => {
    beforeEach(async () => {
      await accountControl.addSigner(account2.address, account3.address, _metadata);
    });

    it('non-admin cannot remove account signer', async function () {
      await expect(accountControl.connect(account1).removeSigner(account2.address, _metadata)).to.be.revertedWith(
        'AccessControl: account is missing role',
      );
    });

    it('admin can remove account signer', async function () {
      await expect(accountControl.removeSigner(account2.address, _metadata))
        .to.emit(accountControl, 'SignerRemoved')
        .withArgs(account2.address, admin.address, _metadata);
    });
  });

  describe('accountOf', () => {
    beforeEach(async () => {
      await accountControl.addSigner(account2.address, account3.address, _metadata);
    });

    it('returns zero-address for non-registered user', async function () {
      expect(await accountControl.accountOf(account3.address)).to.equal(zeroAccount);
    });
    
    it('returns correct address for registered user', async function () {
      expect(await accountControl.accountOf(account2.address)).to.equal(account3.address);
    });
  });
});
