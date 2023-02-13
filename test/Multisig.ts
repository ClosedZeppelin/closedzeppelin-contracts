import { expect } from 'chai';
import { ethers, network } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract } from 'ethers';
import ABI from '../artifacts/contracts/mocks/MultisigMock.sol/MultisigMock.json';

describe('Multisig', function () {
  let multisig: Contract;
  let deadline: number;

  let admin: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let account3: SignerWithAddress;

  beforeEach(async () => {
    const MultisigMock = await ethers.getContractFactory('MultisigMock');
    multisig = await MultisigMock.deploy();
    await multisig.deployed();

    deadline = Math.floor(Date.now() / 1000) + 1000;

    [admin, account1, account2, account3] = await ethers.getSigners();
  });

  describe('signers', () => {
    it('has zero signers', async () => {
      expect(await multisig.currentSigners()).to.have.length(0);
    });
  });

  describe('func2', () => {
    it('fails if called with multisig', async () => {
      const multisigMockAbi = new ethers.utils.Interface(ABI.abi);
      const call = multisigMockAbi.encodeFunctionData('func2', ['value']);
      const { domain, types, value } = getTypesData(call);
      const sig1 = await account1._signTypedData(domain, types, value);

      await expect(multisig.execute(call, deadline, [sig1])).to.be.revertedWith(
        'Multisig: disabled',
      );
    });
    
    it('succeeds if called directly', async () => {
      const _data = 'func2 data';
      await multisig.func2(_data);
      expect(await multisig.data()).to.equal(_data);
    });
  });

  describe('func', () => {
    let call: string;
    let sig1: string;
    let sig2: string;
    let sig3: string;

    beforeEach(async () => {
      const multisigMockAbi = new ethers.utils.Interface(ABI.abi);
      call = multisigMockAbi.encodeFunctionData('func', [100, 'value']);

      const { domain, types, value } = getTypesData(call);

      sig1 = await account1._signTypedData(domain, types, value);
      sig2 = await account2._signTypedData(domain, types, value);
      sig3 = await account3._signTypedData(domain, types, value);
    });

    it('fails executing directly', async () => {
      await expect(multisig.func(100, 'data')).to.be.revertedWith('Multisig: required');
    });

    it('fails executing with less signatures', async () => {
      await expect(multisig.execute(call, deadline, [sig1])).to.be.revertedWith(
        'Multisig: not enough signers',
      );
      expect(await multisig.currentSigners()).to.have.length(0);
    });

    it('fails executing with repeated signature', async () => {
      await expect(multisig.execute(call, deadline, [sig1, sig1])).to.be.revertedWith(
        'Multisig: unsorted signers',
      );
    });

    it('fails executing with unsorted signers', async () => {
      await expect(multisig.execute(call, deadline, [sig1, sig2])).to.be.revertedWith(
        'Multisig: unsorted signers',
      );
    });

    it('succeeds with enough signers', async () => {
      await multisig.execute(call, deadline, [sig2, sig1]);
      expect(await multisig.data()).to.equal('value');
      expect(await multisig.currentSigners()).to.have.length(0);
    });

    it('succeeds with more than enough signers', async () => {
      await multisig.execute(call, deadline, [sig2, sig1, sig3]);
      expect(await multisig.data()).to.equal('value');
      expect(await multisig.currentSigners()).to.have.length(0);
    });
  });

  describe('check', () => {
    let call: string;

    let sig1: string;
    let sig2: string;
    let sig3: string;

    beforeEach(async () => {
      const multisigMockAbi = new ethers.utils.Interface(ABI.abi);

      call = multisigMockAbi.encodeFunctionData('check', [account2.address, account1.address]);

      const { domain, types, value } = getTypesData(call);

      sig1 = await account1._signTypedData(domain, types, value);
      sig2 = await account2._signTypedData(domain, types, value);
      sig3 = await account3._signTypedData(domain, types, value);
    });

    it('has initial nonce zero', async () => {
      expect(await multisig.nonces(admin.address)).to.equal(0);
    });

    it('fails with different signer', async () => {
      await expect(multisig.execute(call, deadline, [sig2, sig3])).to.be.revertedWith(
        'invalid signer 2',
      );
    });

    it('succeeds with correct signers', async () => {
      await multisig.execute(call, deadline, [sig2, sig1]);
      expect(await multisig.data()).to.equal('signers are correct');
    });

    it('fails sending execution two times with same signatures', async () => {
      await multisig.execute(call, deadline, [sig2, sig1]);

      expect(await multisig.nonces(admin.address)).to.equal(1);

      await expect(multisig.execute(call, deadline, [sig2, sig1])).to.be.reverted;
    });

    it('fails execution with exceeded deadline', async () => {
      await ethers.provider.send('evm_increaseTime', [1000]);

      await expect(multisig.execute(call, deadline, [sig2, sig1])).to.be.revertedWith(
        'Multisig: execution expired',
      );
    });
  });

  const getTypesData = (call: string, nonce: number = 0) => ({
    domain: {
      chainId: network.config.chainId,
      name: 'MultisigMock',
      verifyingContract: multisig.address,
      version: '1',
    },

    types: {
      Execute: [
        { name: 'call', type: 'bytes32' },
        { name: 'sender', type: 'address' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' },
      ],
    },

    value: {
      call: ethers.utils.keccak256(call),
      sender: admin.address,
      nonce,
      deadline,
    },
  });
});
