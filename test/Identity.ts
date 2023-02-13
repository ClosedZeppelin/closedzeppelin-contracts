import { expect } from 'chai';
import { ethers, network } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract } from 'ethers';
import ABI from '../artifacts/contracts/collection/Identity.sol/Identity.json';
import { Interface } from '@ethersproject/abi';

const DEFAULT_ADMIN_ROLE = 1 << 0;
const ADMIN_ROLE = 1 << 1;
const MANAGER_ROLE = 1 << 2;
const OPERATOR_ROLE = 1 << 3;

const _metadata = 'reason';
const _account = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

describe('Identity', function () {
  let identity: Contract;
  let deadline: number;

  let admin: SignerWithAddress;

  let account1: SignerWithAddress;
  let account2: SignerWithAddress;
  let account3: SignerWithAddress;
  let account4: SignerWithAddress; // has no roles

  let identityAbi: Interface;

  beforeEach(async () => {
    [admin, account1, account2, account3, account4] = await ethers.getSigners();

    deadline = Math.floor(Date.now() / 1000) + 1000;
    identityAbi = new ethers.utils.Interface(ABI.abi);

    const Identity = await ethers.getContractFactory('Identity');
    identity = await Identity.deploy(
      'ClosedZeppelin - ID',
      2,
      3,
      [account1.address, account2.address, account3.address],
      [account1.address, account2.address, account3.address],
      [account1.address, account2.address, account3.address],
      [account1.address, account2.address, account3.address],
      'closed-zeppelin identity initial role',
    );
    await identity.deployed();
  });

  describe('constructor', () => {
    it('accounts are DEFAULT_ADMIN', async () => {
      expect(await identity.hasRole(DEFAULT_ADMIN_ROLE, admin.address)).to.be.false;
      expect(await identity.hasRole(DEFAULT_ADMIN_ROLE, account1.address)).to.be.true;
      expect(await identity.hasRole(DEFAULT_ADMIN_ROLE, account2.address)).to.be.true;
      expect(await identity.hasRole(DEFAULT_ADMIN_ROLE, account3.address)).to.be.true;
    });
    it('accounts have signers', async () => {
      expect(await identity.accountOf(account1.address)).to.equal(account1.address);
      expect(await identity.accountOf(account2.address)).to.equal(account2.address);
      expect(await identity.accountOf(account3.address)).to.equal(account3.address);
    });
  });

  describe('grantRole', () => {
    beforeEach(async () => {});
    it('fails if called without using multisig', async () => {
      await expect(identity.grantRole(OPERATOR_ROLE, _account)).to.be.revertedWith(
        'Multisig: required',
      );
    });

    it('fails if called without required amount of signatures', async () => {
      const call = identityAbi.encodeFunctionData('grantRole', [OPERATOR_ROLE, account4.address]);
      const { domain, types, value } = getTypesData(call);

      const sig1 = await account1._signTypedData(domain, types, value);
      const sig2 = await account2._signTypedData(domain, types, value);

      await expect(
        identity.connect(account1).execute(call, deadline, [sig2, sig1]),
      ).to.be.revertedWith('Multisig: not enough signers');
    });

    it('fails if signers have not required admin roles', async () => {
      const call = identityAbi.encodeFunctionData('grantRole', [OPERATOR_ROLE, account4.address]);
      const { domain, types, value } = getTypesData(call);

      const sig1 = await account4._signTypedData(domain, types, value); // not admin
      const sig2 = await account2._signTypedData(domain, types, value);
      const sig3 = await account3._signTypedData(domain, types, value);

      await expect(
        identity.connect(account1).execute(call, deadline, [sig1, sig2, sig3]),
      ).to.be.revertedWith('Identity: invalid role for signer');
    });

    it('grants role correctly', async () => {
      const call = identityAbi.encodeFunctionData('grantRole', [OPERATOR_ROLE, account4.address]);
      const { domain, types, value } = getTypesData(call);

      const sig1 = await account1._signTypedData(domain, types, value);
      const sig2 = await account2._signTypedData(domain, types, value);
      const sig3 = await account3._signTypedData(domain, types, value);

      await expect(identity.connect(account1).execute(call, deadline, [sig2, sig1, sig3]))
        .to.emit(identity, 'RoleGranted')
        .withArgs(OPERATOR_ROLE, account4.address, account1.address);
    });
  });

  describe('revokeRole', () => {
    it('fails if called without using multisig', async () => {
      await expect(identity.revokeRole(ADMIN_ROLE, _account)).to.be.revertedWith(
        'Multisig: required',
      );
    });

    it('fails if called without required amount of signatures', async () => {
      const call = identityAbi.encodeFunctionData('revokeRole', [OPERATOR_ROLE, account3.address]);
      const { domain, types, value } = getTypesData(call);

      const sig1 = await account1._signTypedData(domain, types, value);
      const sig2 = await account2._signTypedData(domain, types, value);

      await expect(
        identity.connect(account1).execute(call, deadline, [sig2, sig1]),
      ).to.be.revertedWith('Multisig: not enough signers');
    });

    it('fails if signers have not required admin roles', async () => {
      const call = identityAbi.encodeFunctionData('revokeRole', [OPERATOR_ROLE, account3.address]);
      const { domain, types, value } = getTypesData(call);

      const sig1 = await account4._signTypedData(domain, types, value); // not admin
      const sig2 = await account2._signTypedData(domain, types, value);
      const sig3 = await account3._signTypedData(domain, types, value);

      await expect(
        identity.connect(account1).execute(call, deadline, [sig1, sig2, sig3]),
      ).to.be.revertedWith('Identity: invalid role for signer');
    });

    it('revokes role correctly', async () => {
      const call = identityAbi.encodeFunctionData('revokeRole', [OPERATOR_ROLE, account3.address]);
      const { domain, types, value } = getTypesData(call);

      const sig1 = await account1._signTypedData(domain, types, value);
      const sig2 = await account2._signTypedData(domain, types, value);
      const sig3 = await account3._signTypedData(domain, types, value);

      await expect(identity.connect(account1).execute(call, deadline, [sig2, sig1, sig3]))
        .to.emit(identity, 'RoleRevoked')
        .withArgs(OPERATOR_ROLE, account3.address, account1.address);
    });
  });

  describe('addSigner', () => {
    it('fails if called without using multisig', async () => {
      await expect(identity.addSigner(_account, _account, _metadata)).to.be.revertedWith(
        'Multisig: required',
      );
    });

    it('fails if called without required amount of signatures', async () => {
      const call = identityAbi.encodeFunctionData('addSigner', [_account, _account, _metadata]);
      const { domain, types, value } = getTypesData(call);

      const sig1 = await account1._signTypedData(domain, types, value);

      await expect(identity.connect(account1).execute(call, deadline, [sig1])).to.be.revertedWith(
        'Multisig: not enough signers',
      );
    });

    it('fails if signers have not required admin roles', async () => {
      const call = identityAbi.encodeFunctionData('addSigner', [_account, _account, _metadata]);
      const { domain, types, value } = getTypesData(call);

      const sig1 = await account4._signTypedData(domain, types, value); // not admin
      const sig2 = await account2._signTypedData(domain, types, value);

      await expect(
        identity.connect(account1).execute(call, deadline, [sig1, sig2]),
      ).to.be.revertedWith('Identity: invalid role for signer');
    });

    it('adds signer correctly', async () => {
      const call = identityAbi.encodeFunctionData('addSigner', [_account, _account, _metadata]);
      const { domain, types, value } = getTypesData(call);

      const sig1 = await account1._signTypedData(domain, types, value);
      const sig2 = await account2._signTypedData(domain, types, value);

      await expect(identity.connect(account1).execute(call, deadline, [sig2, sig1]))
        .to.emit(identity, 'AccountCreated')
        .withArgs(_account, account1.address, _metadata);
    });
  });

  describe('removeSigner', () => {
    it('fails if sender have not required roles', async () => {
      await expect(
        identity.connect(account4).removeSigner(account3.address, _metadata),
      ).to.be.revertedWith('AccessControl: account is missing role');
    });

    it('removes signer correctly', async () => {
      await expect(identity.connect(account1).removeSigner(account3.address, _metadata))
        .to.emit(identity, 'SignerRemoved')
        .withArgs(account3.address, account1.address, _metadata);
    });
  });

  const getTypesData = (call: string, nonce: number = 0, sender: string = account1.address) => ({
    domain: {
      chainId: network.config.chainId,
      name: 'ClosedZeppelin - ID',
      verifyingContract: identity.address,
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
      sender,
      nonce,
      deadline,
    },
  });
});
