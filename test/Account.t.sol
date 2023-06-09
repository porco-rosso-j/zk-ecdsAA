pragma solidity 0.8.12;

import "../src/erc4337/UltraVerifier.sol";
import "../src/erc4337/Account.sol";
import "../src/helpers/BytesLib.sol";
import "./utils/NoirHelper.sol";
import "./utils/pubkey/address.sol";

import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {MockSetter} from "./mocks/MockSetter.sol";
import {getUserOperation} from "./utils/Fixtures.sol";

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
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        //vm.startBroadcast(deployerPrivateKey);

        entryPoint = new EntryPoint();
        verifier = new UltraVerifier();
        mockSetter = new MockSetter();
        zkECDSAA = new ZkECDSAA(address(entryPoint));
        zkECDSAA.initialize(
            // hashed addr
            vm.envBytes32("HASHED_ADDR1"),
            address(verifier)
        );

        vm.deal(address(zkECDSAA), 5 ether);
    }

    function verify(
        bytes memory sig,
        string memory _path
    ) internal returns (uint) {
        assertEq(zkECDSAA.getNonce(), 0);
        console.logUint(zkECDSAA.getNonce());

        (UserOperation memory userOp, bytes32 userOpHash) = getUserOperation(
            address(zkECDSAA),
            zkECDSAA.getNonce(),
            sig,
            address(entryPoint),
            uint8(chainId),
            vm
        );

        console.logBytes32(userOpHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            vm.envUint("PRIVATE_KEY1"),
            userOpHash
        );

        console.logUint(v);
        console.logBytes32(r);
        console.logBytes32(s);

        bytes memory raw_sig = abi.encodePacked(r, s, v);
        console.logBytes(raw_sig);
        console.logUint(raw_sig.length);

        bytes memory signature = BytesLib.sliceStartEnd(raw_sig, 0, 64);
        console.logBytes(signature);

        uint8[] memory arraySig = BytesLib.bytesToUint8Array(signature);
        console.logUint(arraySig[0]);

        this.withInput(
            "hashedAddr",
            vm.envBytes32("HASHED_ADDR1"),
            "pub_key",
            pubkey1,
            "signature",
            BytesLib.bytesToUint8Array(signature),
            "message_hash",
            BytesLib.bytes32ToUint8Array(userOpHash)
        );

        console.logUint(0);
        userOp.signature = generateProof(_path);
        uint256 missingWalletFunds = 0;

        vm.prank(address(entryPoint));
        uint256 res = zkECDSAA.validateUserOp(
            userOp,
            userOpHash,
            missingWalletFunds
        );

        return res;
    }

    // vm.sign

    function test_ValidateUserOp() public {
        uint res = verify(
            abi.encodeWithSignature("setValue(uint256)", 1),
            "circuits/zkecdsa/proofs/set.proof"
        );
        assertEq(res, 0);
    }

    // function test_proposeRecovery() public {
    //     assertEq(zkECDSAA.getNonce(), 0);

    //     bytes32[] memory guardians = new bytes32[](3);
    //     guardians[0] = bytes32(
    //         0x13ab2733d03b0c89ab8222acd18b002120fec289a54d5769536b3b758d8dc780
    //     );
    //     guardians[1] = bytes32(
    //         0x1c9fcea8cdb14e79710ec43e3f5a2c0b5c736586bd4a896c52033acab345577d
    //     );
    //     guardians[2] = bytes32(
    //         0x2cc5a2e55e9a482940665b3e3dc88a9e3b0cf90e6b4966f97c8b13fa686cfe5d
    //     );

    //     (UserOperation memory userOp, bytes32 userOpHash) = getUserOperation(
    //         address(zkECDSAA),
    //         zkECDSAA.getNonce(),
    //         abi.encodeWithSignature(
    //             "initializeRecovery(bytes32[], uint8)",
    //             guardians,
    //             2
    //         ),
    //         address(entryPoint),
    //         uint8(chainId),
    //         vm
    //     );

    //     console.logBytes32(userOpHash);
    //     //0x8d86c2c36bcbfc0291af09310862d787b4872815bde60da6d8f3f43a71d2b9f6

    //     // string
    //     //     memory proof = "2ac110487c75afc7215097b7b21548ef956acdd63e004e8fcf5c28002e7a545c1e78e93dcacebbfee6cb9b7b1586e6838fc6db590dd32b7a77f71c88ad7dcb3e0c5284d99921ff642e280f78e7a79ac934239cacf36a9903d530ccc58476db202e06f7d133c95c41e1b4494441edda0c158777e76f6c34d5c6d5eba93e8b106f08a55a1476b25f0423faf58a15242b6eedc3a0c14b37cd9cc478f0cd4c408f4f2ad6b89545665e5b00f283f649cba168695bd474bcc3bca41e092176e1259a9408ff9a43862cc57602f18e791eae1cb613b2276ca8a4ada198f00ada2be9a6a910c3f4486cd8ce36cd60cdb82f77a0b2e3a31da9b60c3316df1c475c757f0ca723b268b8571ba72ffe37688b3fc9963b26b54716f781e25cc3e81baf0ab7582923dda95eeabefaa8135dfa88170e0f36c76e8c2c189d5753b78fded398e26dcd1c3ae970ae904f09d0d608d698fc7ef3e69951bd963d6da90105457cf19d8c7d0bc2767683e38ab0471312c77106d551da0e74831b2c85c6e8e2f2c839901e2607171a0abaa7b8b901aa5a409c00b48b43beca0c11bdb1aa473ede800517112500f2215630c4139894fde549c9ac486c1de26f7b83a0843cf47d12031c68a7122a13792e3caa8365090f8a59836144c651a55cd4b806474f83a2688df6bbf99b213cf11f9b01e76f07e17b33a7fd5f3213bc10717f5b258a5c182ef2508f719a1dd1fbd45ad8dad6fd9a14bd69f395cebf3169483e4f3792d1854e38d3062a1f038a2fe4441b2de82a965bb35edc9f4553b4a4245624fe1183e340576d3a742817b8b958dac7fa5777087f34c50ab304c9e66a3ca8c0a173afcfb4efefbece0d1b5bbe0e1c8ce41933e6f5e5558382f7f7a42e3d356d512c22612001d83818132b2d9b1b12714dbc6a6085600debe2e8fdbc73e7f1d8b675eaae4c289b0a62b21b51a38f54162e8f58d0d88e4f63c78b6ebc79f5f680b30de71c16583e1053d21cecc4f35ba27c410de87388fc3caccbe4afaab6cae5a1fed18cc818805a8a3917cfb8c1e4e2e20162af3520d048084490e80904572e2fefe3fe90adb92ade3206e546357507739ae6fa2ae75ddef24a7f864c50bb901604916e6d64e1579efa23d4239f8c1456505cca2fd6499419bbdbeb21394e917b54624411552df290da146765c9e7ef8de9a0020d4567a3e2b5c316bf10f50506821d40d017b34371b2087ea4013e800f5ce37123c01ce8d0eb08dc9807303546e621d65ed1b773399821492380f93aec7a497bdac2b02cd239c6111166abb46a4a93e28a92b49acbe00f8837994c33b068958d74fe0ee76e6b8ef2b730fe5fdee8d7a6d1423bbe2098237242a6fb330f973ca71f3ee09bcc20aa20651ee5fe30550a37a7af62403d621e82e679a21fde568c99d267b4884ffe9ed4eb8407d5ce8763d45966c0c20314141341c4882b33fb84d219688ba7bcb0c0db18875d34de436febd7f2f1e45d4b20dc01171560a59ac89dc72b89a26bcf25bb93f94e72150d32fc7236c327fb700148fbd9e7b05a58c1467d8a5bedc8802e98f4c0c98bda79f8d40a9d98a3801016eb015abf49a8535dbd3f6b4092d3c4d1fe040fc1d0f3cc30ff9ab88f86c5e224b9390102d3fb29d17f9f1bb323fd0899911cc4a5d8e0f5c2f02fb8c5871cb21793392a7da221b7cae18ae7f235062d94ba01ca428298a9848551ee2c65ae0b24fe5b0a8ab3c9145c1e18e71bf79e35d2da30f39fe9f1d571d2db273f3b2ac12688fed05838c4c55da9ed425daf76e6bf532bdcf9eabd0ba7301dae29e297722ddc76e006481532393eace2b9bb34a6a8409d4c02a54c955ef0efca225134d82d5c7756eb8056264c6409c6b51488cc7fc4e349e31f6e9cfc1962b7cd239b2016e8e150d845acec15cd2d010ffa5e2eb9f577011e55633b447e8b681c5281af15f1b234ff37b98c8ffdd40b2e38b05e61135ba9233d426e99b2d13f7e5a06a6025e24616dc2ab7fb3451d988f6786d445c8fc533972e7a1d4bc8e1686421e860e4b57bf65006a167450e3bea9302f4e4fb546afd40a14f7c3577968e407eb0428e780010e35a70573baba11782aae26f9887d7234fa1e193b19d540cf3c1d8006262b7813b5460419b8d52e9df8fb81db7356fe1ca94439939367ed4d0590a11a5b91dd2e2d425fbb116fe3beb083979c7191416222b16da4b412178ad38fc1204f2e106d85f0fe8e1850d5bb829cfc5ed4451b922fdba6e54c6e5c88a069b726a8361ad9ae7d836345b0acde6324a9791c2855bb74bf61435b032c7a391abf089f6ce5393c3efeaac156d1de6d43cac4e04d40b1a205c6276966b39d3959b82c58813b2b9c8c0deb02931cdeee80306eb7d17a14017c2f25fc361d072dad100cd42eb6fbf590a416448f429fc44aae9dc0255cf3c0e51115910c6d6cff1ec201d1c58320790bba9dba14bff0c00d9db9b03a2395b99def96d4865652a5f1fb0e6cbfa327b085192eaa2c261efecfd6c67496977aee3e15a91d1ca5c9c59524080f6349148cdc0eb6c8818ddfe429ab3bc50c6bb770b82ef33350d7f176fcd5193538a3a41b59184cf0b3e0c4cf82b809704cd09401d1bf0e7df76af6e5d1ae2ea03842b12347be50119d431d51951730df272633b22f34c882492ed53651e71fa96c655e472025d9c602b37eed4259f2b39ed9ff22756e100199f99f9007902ed6f630c8c820276f504794965454b347cd9e5880a338b22e03dc2fb1cdf14d1e99207ddbfcfa92f6bc68cf0b8b4d9cdbc782aacd3dc882468a5c424047ec2604d400f5a21c39e40d51738b613eeb24e0ac767e02d5e3c39ce8d6d8e7e3db5d20d171e907adfe702947cd4aa4d9aa109824fd5b7a678b862880aff1a80dfcfd2e183ef8c32bbeb24fa6e32595ac07ec731308a95c400c3c88f68a5b46cb87e710542e663ede94e97ade20fb75aea5f43bcbe2376746b7fb668f94e60b21b2b8122438eb2aa2c08873383228392bc802fd892b7f2db46c70557bc9326029e348";
    //     // bytes memory proofBytes = vm.parseBytes(proof);

    //     userOp.signature = proofBytes;

    //     uint256 missingWalletFunds = 0;

    //     vm.prank(address(entryPoint));
    //     uint256 res = zkECDSAA.validateUserOp(
    //         userOp,
    //         userOpHash,
    //         missingWalletFunds
    //     );
    //     assertEq(res, 0);

    //     // Validate nonce incremented
    //     // assertEq(zkECDSAA.getNonce(), 1);
    // }
}
