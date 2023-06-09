pragma solidity 0.8.12;

import "../src/erc4337/UltraVerifier.sol";
import "../src/erc4337/Account.sol";
import "../src/helpers/BytesLib.sol";
import "./utils/NoirHelper.sol";
import "./utils/pubkey/address.sol";

import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {MockSetter} from "./mocks/MockSetter.sol";
import {getUserOperation} from "./utils/userOp/Fixtures.sol";

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
        zkECDSAA.initialize(hashedAddr[0], address(verifier));

        vm.deal(address(zkECDSAA), 5 ether);
    }

    function test_ValidateUserOp() public {
        uint res = proove_and_verify(
            abi.encodeWithSignature("setValue(uint256)", 1),
            "circuits/zkecdsa/proofs/set.proof",
            0,
            0,
            pubkey1
        );
        assertEq(res, 0);
    }

    function test_initializeRecovery() public {
        bytes32[] memory guardians = new bytes32[](3);
        guardians[0] = hashedAddr[0];
        guardians[1] = hashedAddr[1];
        guardians[2] = hashedAddr[2];

        uint res = proove_and_verify(
            abi.encodeWithSignature(
                "initializeRecovery(bytes32[], uint8)",
                guardians,
                2
            ),
            "circuits/zkecdsa/proofs/init_r.proof",
            0,
            0,
            pubkey1
        );
        assertEq(res, 0);
    }

    function proove_and_verify(
        bytes memory _calldata,
        string memory _path,
        uint pk_num,
        uint hashed_addr_num,
        uint[] memory pubkey
    ) internal returns (uint) {
        assertEq(zkECDSAA.getNonce(), 0);
        console.logUint(zkECDSAA.getNonce());

        (UserOperation memory userOp, bytes32 userOpHash) = getUserOperation(
            address(zkECDSAA),
            zkECDSAA.getNonce(),
            _calldata,
            address(entryPoint),
            uint8(chainId),
            vm
        );

        console.logBytes32(userOpHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            private_key[pk_num], // here
            userOpHash
        );

        bytes memory signature = BytesLib.sliceStartEnd(
            abi.encodePacked(r, s, v),
            0,
            64
        );
        console.logBytes(signature);

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

        userOp.signature = generateProof(_path);

        vm.prank(address(entryPoint));
        uint256 res = zkECDSAA.validateUserOp(userOp, userOpHash, 0);

        return res;
    }
}
