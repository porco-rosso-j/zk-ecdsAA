// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "forge-std/Script.sol";
// import "forge-std/Vm.sol";
// import "forge-std/console.sol";

import "src/erc4337/Account.sol";
import "src/erc4337/AccountFactory.sol";
import "src/verifier/UltraVerifier.sol";
// import "src/core/NonTransparentProxy.sol";
import "../test/utils/pubkey/address.sol";

import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

contract DeployAccount is Script, Addresses {
    address deployerAddress = vm.envAddress("ADDRESS");
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        EntryPoint entryPoint = EntryPoint(
            payable(0x0576a174D229E3cFA37253523E645A78A0C91B57)
        );
        AccountFactory factory = new AccountFactory(entryPoint);

        UltraVerifier verifier = new UltraVerifier();

        // forge script script/Deploy4337.s.sol:DeployAccount --broadcast

        bytes32[] memory guardians = new bytes32[](3);
        guardians[0] = hashedAddr[0];
        guardians[1] = hashedAddr[1];
        guardians[2] = hashedAddr[2];

        ZkECDSAA ret = factory.createAccount(
            hashedAddr[0],
            address(verifier),
            guardians,
            uint8(2),
            12 weeks, // a day
            hashedAddr[4],
            0
        );

        console.logAddress(address(ret));

        vm.stopBroadcast();
    }
}
