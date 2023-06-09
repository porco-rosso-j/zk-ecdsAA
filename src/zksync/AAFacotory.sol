// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.16;

// import "era-system-contracts/contracts/Constants.sol";
// import "era-system-contracts/contracts/libraries/SystemContractsCaller.sol";

// contract AAFactory {
//     bytes32 public aaBytecodeHash;

//     constructor(bytes32 _aaBytecodeHash) {
//         aaBytecodeHash = _aaBytecodeHash;
//     }

//     function deployAccount(
//         bytes32 salt,
//         bytes32 owner,
//     ) external returns (address accountAddress) {
//         (bool success, bytes memory returnData) = SystemContractsCaller
//             .systemCallWithReturndata(
//                 uint32(gasleft()),
//                 address(DEPLOYER_SYSTEM_CONTRACT),
//                 uint128(0),
//                 abi.encodeCall(
//                     DEPLOYER_SYSTEM_CONTRACT.create2Account,
//                     (
//                         salt,
//                         aaBytecodeHash,
//                         abi.encode(owner),
//                         IContractDeployer.AccountAbstractionVersion.Version1
//                     )
//                 )
//             );
//         require(success, "Deployment failed");

//         (accountAddress) = abi.decode(returnData, (bytes32));
//     }
// }
