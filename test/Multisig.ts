import { expect } from 'chai';
import { ethers, network } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, TypedDataDomain, TypedDataField } from 'ethers';
import { TypedDataUtils } from 'ethers-eip712';
import ABI from '../artifacts/contracts/mocks/MultisigMock.sol/MultisigMock.json';

describe('Multisig', function () {
  let multisig: Contract;

  let admin: SignerWithAddress;
  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let account3: SignerWithAddress;

  beforeEach(async () => {
    const MultisigMock = await ethers.getContractFactory('MultisigMock');
    multisig = await MultisigMock.deploy();
    await multisig.deployed();

    [admin, account1, account2, account3] = await ethers.getSigners();
  });

  describe('signers', () => {
    it('has zero signers', async () => {
      expect(await multisig.currentSigners()).to.have.length(0);
    });
  });

  // describe('func', () => {
  //   let call: string;
  //   let sig1: string;
  //   let sig2: string;
  //   let sig3: string;

  //   beforeEach(async () => {
  //     const multisigMockAbi = new ethers.utils.Interface(ABI.abi);
  //     call = multisigMockAbi.encodeFunctionData('func', [100, 'value']);
  //     const callHash = ethers.utils.keccak256(call);

  //     sig1 = await account1.signMessage(callHash);
  //     sig2 = await account2.signMessage(callHash);
  //     sig3 = await account3.signMessage(callHash);
  //   });

  //   it('fails executing directly', async () => {
  //     await expect(multisig.func(100, 'data')).to.be.revertedWith('Multisig: required');
  //   });

  //   it('fails executing with less signatures', async () => {
  //     await expect(multisig.execute(call, [sig1])).to.be.revertedWith('Multisig: not enough signers');
  //     expect(await multisig.currentSigners()).to.have.length(0);
  //   });

  //   it('succeeds with enough signers', async () => {
  //     await multisig.execute(call, [sig1, sig2]);
  //     expect(await multisig.data()).to.equal('value');
  //     expect(await multisig.currentSigners()).to.have.length(0);
  //   });

  //   it('succeeds with more than enough signers', async () => {
  //     await multisig.execute(call, [sig1, sig2, sig3]);
  //     expect(await multisig.data()).to.equal('value');
  //     expect(await multisig.currentSigners()).to.have.length(0);
  //   });

  //   it('succeeds executing call but fails calling directly ', async () => {
  //     await multisig.execute(call, [sig1, sig2, sig3]);
  //     await expect(multisig.func(100, 'data2')).to.be.revertedWith('Multisig: required');
  //   });
  // });

  describe('check', () => {
    let call: string;
    let deadline: number;

    let sig1: string;
    let sig2: string;
    let sig3: string;

    beforeEach(async () => {
      const multisigMockAbi = new ethers.utils.Interface(ABI.abi);

      call = multisigMockAbi.encodeFunctionData('check', [account1.address, account2.address]);
      deadline = Math.floor(Date.now() / 1000) + 1000;

      const domain: TypedDataDomain = {
        chainId: network.config.chainId,
        name: 'MultisigMock',
        verifyingContract: multisig.address,
        version: '1',
      };

      // Execute(uint256 nonce,uint256 deadline)
      const types: Record<string, TypedDataField[]> = {
        Execute: [
          { name: 'call', type: 'bytes32' },
          { name: 'sender', type: 'address' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' },
        ],
      };

      const value: Record<string, any> = {
        call: ethers.utils.keccak256(call),
        sender: admin.address,
        nonce: 0,
        deadline: deadline,
      };

      sig1 = await account1._signTypedData(domain, types, value);
      sig2 = await account2._signTypedData(domain, types, value);
      sig3 = await account3._signTypedData(domain, types, value);
    });

    it('has initial nonce zero', async () => {
      expect(await multisig.nonces(admin.address)).to.equal(0);
    });

    it('fails with different signer', async () => {
      await expect(multisig.execute(call, deadline, [sig1, sig3])).to.be.revertedWith(
        'invalid signer 2',
      );
    });

    // beforeEach(async () => {
    //   await ethers.provider.send("evm_increaseTime", [2 * 60 * 60]);
    // });

    // it('succeeds with correct signers', async () => {
    //   await multisig.execute(call, [sig1, sig2]);
    //   expect(await multisig.data()).to.equal('');
    // });
  });
});
