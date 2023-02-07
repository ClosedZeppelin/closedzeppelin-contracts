import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract } from 'ethers';

const zeroAccount = '0x0000000000000000000000000000000000000000';

describe('ERC20', function () {
  const _metadata = 'metadata';
  let token: Contract;

  let admin: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let account3: SignerWithAddress;

  beforeEach(async () => {
    // deploy accounts control
    const AccountControlMock = await ethers.getContractFactory('AccountControlMock');
    const accounts = await AccountControlMock.deploy();
    await accounts.deployed();

    // deploy erc20
    const ERC20 = await ethers.getContractFactory('ERC20Mock');
    token = await ERC20.deploy('Token Name', 100, 'Token Symbol', 0, accounts.address);
    await token.deployed();

    [admin, account1, account2, account3] = await ethers.getSigners();

    await accounts.addSigner(account1.address, account2.address, _metadata);
  });

  describe('balanceOf', () => {
    it('admin account has initial minting balance', async function () {
      expect(await token.balanceOf(admin.address)).to.equal(100);
    });
  });

  describe('transfer', () => {
    beforeEach(async () => {
      await token.transfer(account2.address, 10);
    });

    it('non-signer cannot spend money', async function () {
      expect(await token.balanceOf(account2.address)).to.equal(10);

      await expect(token.connect(account2).transfer(account3.address, 5)).to.be.revertedWith(
        'ERC20: transfer from the zero address',
      );
    });

    it('signer can spend money', async function () {
      expect(await token.balanceOf(account1.address)).to.equal(0);

      await expect(token.connect(account1).transfer(account3.address, 5))
        .to.emit(token, 'Transfer')
        .withArgs(account2.address, account3.address, 5);
    });
  });
});
