import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract } from 'ethers';
import ABI from '../artifacts/contracts/mocks/MultisigMock.sol/MultisigMock.json';

describe('ERC20', function () {
  let multisig: Contract;

  let admin: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let account3: SignerWithAddress;

  let call: string;
  let sig1: string;
  let sig2: string;
  let sig3: string;

  beforeEach(async () => {
    const MultisigMock = await ethers.getContractFactory('MultisigMock');
    multisig = await MultisigMock.deploy();
    await multisig.deployed();

    [admin, account1, account2, account3] = await ethers.getSigners();

    const multisigMockAbi = new ethers.utils.Interface(ABI.abi);
    call = multisigMockAbi.encodeFunctionData('func', [100, 'value']);
    const callHash = ethers.utils.keccak256(call);

    sig1 = await account1.signMessage(callHash);
    sig2 = await account2.signMessage(callHash);
    sig3 = await account3.signMessage(callHash);
  });

  it('has zero signers', async () => {
    expect(await multisig.currentSigners()).to.have.length(0);
  });

  it('fails executing function directly', async () => {
    await expect(multisig.func(100, 'data')).to.be.revertedWith('Multisig: required');
  });

  it('fails executing function with less signatures', async () => {
    await expect(multisig.execute(call, [sig1])).to.be.revertedWith('Multisig: not enough signers');
    expect(await multisig.currentSigners()).to.have.length(0);
  });

  it('succeeds with enough signers', async () => {
    await multisig.execute(call, [sig1, sig2]);
    expect(await multisig.data()).to.equal('value');
    expect(await multisig.currentSigners()).to.have.length(0);
  });

  it('succeeds with more than enough signers', async () => {
    await multisig.execute(call, [sig1, sig2, sig3]);
    expect(await multisig.data()).to.equal('value');
    expect(await multisig.currentSigners()).to.have.length(0);
  });

  it('succeeds executing call but fails calling directly ', async () => {
    await multisig.execute(call, [sig1, sig2, sig3]);
    await expect(multisig.func(100, 'data2')).to.be.revertedWith('Multisig: required');
  });
});
