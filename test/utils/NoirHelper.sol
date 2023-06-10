pragma solidity 0.8.12;

// import {TestBase} from "forge-std/Base.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NoirHelper is Test {
    using Strings for uint;
    struct CircuitInput {
        string n_hashedAddr;
        bytes32 hashedAddr;
        string n_pub_key;
        uint8[] pub_key;
        string n_signature;
        uint8[] signature;
        string n_message_hash;
        uint8[] message_hash;
    }

    CircuitInput public inputs;

    function withInput(
        string memory n_hashedAddr,
        bytes32 hashedAddr,
        string memory n_pub_key,
        uint8[] memory pub_key,
        string memory n_signature,
        uint8[] memory signature,
        string memory n_message_hash,
        uint8[] memory message_hash
    ) public returns (NoirHelper) {
        inputs = CircuitInput(
            n_hashedAddr,
            hashedAddr,
            n_pub_key,
            pub_key,
            n_signature,
            signature,
            n_message_hash,
            message_hash
        );
        return this;
    }

    function clean() public {
        string[] memory ffi_cmds = new string[](1);
        ffi_cmds[0] = "./delete.sh";
        vm.ffi(ffi_cmds);
        delete inputs;
    }

    // function readProof(string memory fileName) public returns (bytes memory) {
    //     string memory file = vm.readFile(
    //         string.concat("circuits/zkecdsa/proofs/", fileName, ".proof")
    //     );
    //     return vm.parseBytes(file);
    // }

    function generateProof(
        string memory _path,
        string memory _proof_name
    ) public returns (bytes memory) {
        string memory proverTOML = "circuits/zkecdsa/Prover.toml";
        string memory params1 = string.concat(
            inputs.n_hashedAddr,
            " = ",
            '"',
            vm.toString(inputs.hashedAddr),
            '"'
        );

        string memory params2 = string.concat(
            inputs.n_pub_key,
            " = ",
            uint8ArrayToString(inputs.pub_key)
        );

        string memory params3 = string.concat(
            inputs.n_signature,
            " = ",
            uint8ArrayToString(inputs.signature)
        );

        string memory params4 = string.concat(
            inputs.n_message_hash,
            " = ",
            uint8ArrayToString(inputs.message_hash)
        );

        vm.writeLine(proverTOML, params1);
        vm.writeLine(proverTOML, params2);
        vm.writeLine(proverTOML, params3);
        vm.writeLine(proverTOML, params4);

        // generate proof
        string[] memory ffi_cmds = new string[](1);
        ffi_cmds[0] = string.concat("./actions/prove_", _proof_name, ".sh");
        // chmod +x ./prove.sh to give the permission.
        vm.ffi(ffi_cmds);

        // clean inputs
        clean();
        // read proof
        string memory proof = vm.readFile(_path); // "circuits/zkecdsa/proofs/.proof"
        return vm.parseBytes(proof);
    }

    function uint8ArrayToString(
        uint8[] memory array
    ) internal pure returns (string memory) {
        string memory str = "[";
        for (uint i = 0; i < array.length; i++) {
            str = string(abi.encodePacked(str, uint256(array[i]).toString()));
            if (i < array.length - 1) {
                str = string(abi.encodePacked(str, ","));
            }
        }
        str = string(abi.encodePacked(str, "]"));
        return str;
    }
}

// 161b
