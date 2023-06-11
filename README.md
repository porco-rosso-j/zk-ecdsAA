# AnonAA

![icon2](https://github.com/porco-rosso-j/zk-ecdsAA/assets/88586592/847da28a-f24c-4f98-abf8-bab74f30b788)

## Overview

AnonAA is an ERC4337-based social recovery wallet that also implements useful privacy-preserving features, such as private ownership and private ownership transfer. These are enabled by ZKP with Noir, generalized zkp language built by Aztec.

## Feature break-down

### Private Social Recovery

One of the biggest unspoken risks associated with the current social recovery scheme is the possible corruption in which the "trusted" guardians communicate behind the scene and collude to take the account ownership and steal the owner's assets. 

Imagine a social recovery wallet with 3 guardians (one is your backup address and the other two are people you trust, like your family members and close friends) and the threshold is 2. As long as the stored guardian addresses are publicly known, it's not difficult for guardians other than you to collude. 

To prevent such actions, AnonAA allows you to store the guardian address masked(hashed) and they can interact with the wallet ( approve/ reject recovery proposals) without revealing their public identity ( eht address / public key ) so that they can't know who the other guardians are, making the corruption nearly impossible.

### Private Ownership

AnonAA only stores encrypted addresses which helps the owner hide the ownership of the account. Hence, as long as the owner manages the account without making any link to his/her other addresses on-chain, nobody can guess/know who controls the smart contract wallet.

### Private Inheritance

AnonAA allows for safe and private transfer of account ownership. Even if you are put into unexpected situations like death and imprisonment where you can't have access to your account/funds anymore, people such as your son, daughter, and wife can safely inherit your assets anonymously.

## Technologies

- [Noir](https://noir-lang.org/), a language for creating and verifying zk-proofs built by Aztec.
- [ERC4337](https://eips.ethereum.org/EIPS/eip-4337), an Account Abstraction standard.
- [zkSync](https://zksync.io/), a layer two zkEVM that supports native Account Abstraction.

### Inspiration & Credit

- [DarkSafe](https://github.com/colinnielsen/dark-safe)
- [ecrecover-noir](https://github.com/colinnielsen/ecrecover-noir)

## Deployed Contracts

Here is the list of the Account contract addresses deployed on each network.

| Chain              | Address                                    |
| ------------------ | ------------------------------------------ |
| Goerli             | 0x0C92B5E41FBAc2CbF1FAD8D72d5BC4F3f73dA104 |
| Optimism Goerli    | 0xaFb4461a934574d33Ae5b759914E14226a3d168e |
| Chiago(Gnosis)     | 0x55b89639d847702d948E307B72651D6213efDb7A |
| Scroll alpha       | 0x542a0d82F98D1796A38a3382235c98C797eaC4F5 |
| Base Goerli        | 0x3a52f22c59bbb86b85eba807cf6ebadbe298d9a3 |

## Challenges

### Building Frontend

Since Noir's JS library used for generating zk-proof is unusable as it hasn't been updated to the latest version of Noir, I couldn't build a fron-tend where users can locally generate proof and submit transactions to get his/her actions done.

### Hashed Address, not Merkle proof

AnonAA stores Pedersen-hashed addresses in smart contracts which is practically secure enough to preserve the privacy of the users: the owner, the guardians of social recovery, and the beneficiary of the inheritance. However, using Merkle root is more desirable and elegant as a solution to manage the user's identity as it reduces storage costs as the number of data increases.

Unfortunately, this is impossible at this point as the Noir JS library is still out of date as I mentioned above.

### Proving time and Verifying cost

Even though applying ZKP to privacy solutions is cool and effective, I think it's still hard to go in production as the proving time is too long ( abt 1.30mins for each ) and verifying contract consumes tons of gas ( min. ~500k). But I believe that this bottlenecks will be eased and removed as the technologies improve in Noir and its underlying proving system.

### Relayer

To make AnonAA purely private, there needs to be a relayer that can work as a relayer/paymaster so that users don't reveal its on-chain recorsds for paying gas. I couldn't build it whithin this hackathon but this is the first thing that should be worked on next.

## Deployments

##### compile

```shell
forge compile
```

##### test

```shell
chmod +x ./actions/prove_app_r.sh
```

```shell
chmod +x ./delete.sh
```

```shell
forge test --contracts zkECDSAATest --match-test test_approve_recovery -vv
```

Expected outcome would look like

<img width="544" alt="Screenshot 2023-06-11 at 9 53 19" src="https://github.com/porco-rosso-j/zk-ecdsAA/assets/88586592/5973d6bb-2d9b-415c-b14a-95d322689f21">

##### deploy

```shell
forge script script/Deploy4337.s.sol:DeployAccount --rpc-url <RPC_URL> --broadcast
```
