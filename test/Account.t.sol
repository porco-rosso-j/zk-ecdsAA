pragma solidity 0.8.12;

import "../src/erc4337/UltraVerifier.sol";
import {ZkECDSAA} from "../src/erc4337/Account.sol";
import "../src/helpers/BytesLib.sol";
import "./utils/NoirHelper.sol";
import "./utils/pubkey/address.sol";

import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {MockSetter} from "./mocks/MockSetter.sol";
import {getUserOperation} from "./utils/userOp/Fixtures.sol";

// writing to prover.toml fails if you run multiple test function with proof generation at the same time.
// so you should specify the test function and run each seperately.
// for instance forge test --contracts zkECDSAATest --match-test test_set_value -vv

contract zkECDSAATest is NoirHelper, Addresses {
    using BytesLib for bytes;

    UltraVerifier public verifier;
    ZkECDSAA public zkECDSAA;
    MockSetter public mockSetter;
    EntryPoint public entryPoint;

    // relayer 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
    // 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

    uint256 chainId = block.chainid;

    function setUp() public {
        entryPoint = new EntryPoint();
        verifier = new UltraVerifier();
        mockSetter = new MockSetter();
        zkECDSAA = new ZkECDSAA(address(entryPoint));

        bytes32[] memory guardians = new bytes32[](3);
        guardians[0] = hashedAddr[0];
        guardians[1] = hashedAddr[1];
        guardians[2] = hashedAddr[2];

        zkECDSAA.initialize(
            hashedAddr[0],
            address(verifier),
            guardians,
            uint8(2),
            864000,
            hashedAddr[4]
        );

        // only_self sucks lol
        // but then how could i prevent others from calling specifc funcs inside AA...?

        vm.deal(address(zkECDSAA), 5 ether);
    }

    // basic transaction
    function test_set_value() public {
        bytes memory callData = abi.encodeWithSignature("setValue(uint256)", 1);

        string memory proof_name = "set";

        uint res = prove_and_verify(
            callData,
            string.concat("circuits/zkecdsa/proofs/", proof_name, ".proof"),
            proof_name,
            0,
            0,
            pubkey1
        );
        assertEq(res, 0);

        vm.prank(address(entryPoint));
        zkECDSAA.execute(address(mockSetter), 0, callData);

        uint value = mockSetter.value();
        assertEq(value, 1);
    }

    // function test_approve_recovery_() public {
    //     vm.prank(addresses[3]);
    //     zkECDSAA.proposeRecovery(hashedAddr[3], block.timestamp + 864000);

    //     vm.prank(addresses[3]);
    //     zkECDSAA.approveRecovery(hashedAddr[3], hashedAddr[1]);

    //     uint appCount = zkECDSAA.getApprovalCount(hashedAddr[3]);
    //     assertEq(appCount, 1);
    // }

    function test_approve_recovery() public {
        vm.prank(addresses[3]);
        zkECDSAA.proposeRecovery(hashedAddr[3], block.timestamp + 864000);

        uint _appCount = zkECDSAA.getApprovalCount(hashedAddr[3]);
        assertEq(_appCount, 0);

        bytes memory callData = abi.encodeWithSelector(
            zkECDSAA.approveRecovery.selector,
            hashedAddr[3],
            hashedAddr[1]
        );

        string memory proof_name = "app_r";

        console.logBytes(callData);

        // validation
        uint res = prove_and_verify(
            callData,
            string.concat("circuits/zkecdsa/proofs/", proof_name, ".proof"),
            proof_name,
            1, // pk
            1, // hashedaddr
            pubkey2
        );

        assertEq(res, 0);

        // execute
        vm.prank(address(entryPoint));
        zkECDSAA.execute(address(zkECDSAA), 0, callData);

        uint appCount = zkECDSAA.getApprovalCount(hashedAddr[3]);
        assertEq(appCount, 1);

        bool voted = zkECDSAA.getVoted(hashedAddr[3], hashedAddr[1]);
        assertEq(voted, true);

        // second approval

        bytes memory callData_ = abi.encodeWithSelector(
            zkECDSAA.approveRecovery.selector,
            hashedAddr[3],
            hashedAddr[2]
        );

        uint res_ = prove_and_verify(
            callData_,
            string.concat("circuits/zkecdsa/proofs/", proof_name, ".proof"),
            proof_name,
            2, // pk
            2, // hashedaddr
            pubkey3
        );

        assertEq(res_, 0);

        // execute
        vm.prank(address(entryPoint));
        zkECDSAA.execute(address(zkECDSAA), 0, callData_);

        appCount = zkECDSAA.getApprovalCount(hashedAddr[3]);
        assertEq(appCount, 2);

        bool voted_ = zkECDSAA.getVoted(hashedAddr[3], hashedAddr[2]);
        assertEq(voted_, true);

        bytes32 owner = zkECDSAA.owner();
        assertEq(owner, hashedAddr[3]);

        console.logUint(500);
    }

    function test_inheritance() public {
        // vm.prank(addresses[4]);
        // zkECDSAA.proposeInheritance(hashedAddr[4]);

        bytes memory callData = abi.encodeWithSelector(
            zkECDSAA.proposeInheritance.selector,
            hashedAddr[4]
        );

        console.logBytes(callData);

        string memory proof_name = "prop_i";

        uint res = prove_and_verify(
            callData,
            string.concat("circuits/zkecdsa/proofs/", proof_name, ".proof"),
            proof_name,
            4, // pk
            4, // hashedaddr
            pubkey5
        );

        assertEq(res, 0);

        // execute
        vm.prank(address(entryPoint));
        zkECDSAA.execute(address(zkECDSAA), 0, callData);

        bytes32 benf = zkECDSAA.getBeneficiary(1);
        assertEq(benf, hashedAddr[4]);

        vm.warp(block.timestamp + 865000);

        bytes memory callData_ = abi.encodeWithSelector(
            zkECDSAA.executeInheritance.selector,
            hashedAddr[4],
            1
        );

        proof_name = "exec_i";

        uint res_ = prove_and_verify(
            callData_,
            string.concat("circuits/zkecdsa/proofs/", proof_name, ".proof"),
            proof_name,
            4, // pk
            4, // hashedaddr
            pubkey5
        );

        assertEq(res_, 0);

        // execute
        vm.prank(address(entryPoint));
        zkECDSAA.execute(address(zkECDSAA), 0, callData_);

        bytes32 owner = zkECDSAA.owner();
        assertEq(owner, hashedAddr[4]);
    }

    function prove_and_verify(
        bytes memory _calldata,
        string memory _path,
        string memory _proof_name,
        uint pk_num,
        uint hashed_addr_num,
        uint8[] memory pubkey
    ) internal returns (uint) {
        (UserOperation memory userOp, bytes32 userOpHash) = _getUserOperation(
            _calldata
        );

        bytes memory signature = _getSignature(private_key[pk_num], userOpHash);

        this.withInput(
            "hashedAddr",
            hashedAddr[hashed_addr_num],
            "pub_key",
            pubkey,
            "signature",
            BytesLib.bytesToUint8Array(signature),
            "message_hash",
            BytesLib.bytes32ToUint8Array(userOpHash)
        );

        bytes memory proof = generateProof(_path, _proof_name);
        // bytes memory proof = vm.parseBytes(vm.readFile(_path));
        userOp.signature = abi.encode(hashedAddr[hashed_addr_num], proof);

        vm.prank(address(entryPoint));
        uint256 ValidatinRes = zkECDSAA.validateUserOp(userOp, userOpHash, 0);
        assertEq(ValidatinRes, 0);

        return 0;
    }

    function _getSignature(
        uint _privatekey,
        bytes32 _userOpHash
    ) internal view returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _privatekey, // here
            _userOpHash
        );

        bytes memory signature = BytesLib.sliceStartEnd(
            abi.encodePacked(r, s, v),
            0,
            64
        );
        console.logBytes(signature);

        return signature;
    }

    function _getUserOperation(
        bytes memory _calldata
    ) internal view returns (UserOperation memory userOp, bytes32 userOpHash) {
        return
            getUserOperation(
                address(zkECDSAA),
                zkECDSAA.getNonce(),
                _calldata,
                address(entryPoint),
                uint8(chainId),
                vm
            );
    }
}
