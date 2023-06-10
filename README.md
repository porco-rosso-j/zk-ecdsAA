# zk-ecdsAA

## Overview

zkECDSAA is an ERC4337 wallet that implements a couple of privacy-preserving features, such as private ownership, private social recovery and private inheritance.

## Feature break-down

### Private Ownership

While onwer addresses are conventionally publicly stored in smart contract wallet in which the address is used for the signature verification, zkECDSAA only stores encrypted address which helps the owner hide the ownership of the account. The signature verification occurs in a way that verifies the zk-proof provided by the trasaction sender.

Hence, as long as the owner manages the account without making the links to his/her other addresses on-chain, nobody can guess/know who controlls the smart contract wallet.

### Private Social Recovery

One of the biggest unspoken risks associated with the current social recovery scheme is the possible corruptions in which the "trusted" guradians communicate behind the scene and propose a recovery process and approve it to take the account ownership and steal the funds.

Imagine a social recovery wallet with 3 guardians (one is your back-up address and the other two are people you trust, like your family members and close friends) and the threshold is 2. As long as the stored guardian addresses are publicly known, it's fairly easy for the guardians other than you to take malicious actions against your account.

To prevent such actions, zkECDSA allows you to store the guardian as encrypted so that they can't know who the other guardians are, making it impossible for them to even communicate.

### Private Inheritance

zkECDSAA allows for safe and private transfer of the account ownership. Even if you are in occassions like dealth and imprisonment where you can't have access to your account/funds anymore, people like such as your son, daughter, and wife can safely inherit your funds privatey.

## Technologies

- [Noir](https://noir-lang.org/), a language for creating and verifying zk-proofs built by Aztec.
- [ERC4337](https://eips.ethereum.org/EIPS/eip-4337), an Account Abstraction standard.
- [zkSync](https://zksync.io/), a layer two zkEVM that supports native Account Abstraction.

### Inspiration & Credit

- [DarkSafe](https://github.com/colinnielsen/dark-safe)
- [ecrecover-noir](https://github.com/colinnielsen/ecrecover-noir)
