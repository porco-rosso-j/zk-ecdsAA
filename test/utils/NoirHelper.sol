pragma solidity 0.8.12;

// import {TestBase} from "forge-std/Base.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//import {console2 as console} from "forge-std/console2.sol";

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

    /// Adds an input.
    /// Can be chained.
    ///
    /// # Example
    ///
    /// ```
    /// withInput("x", 1).withInput("y", 2).withInput("return", 3);
    /// ```
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

    // function withInputArray(
    //     string memory _name,
    //     uint8[] memory _array
    // ) public returns (NoirHelper) {
    //     inputsArray.push(CircuitInput_Array(_name, _array));
    //     return this;
    // }

    /// "Empty" the inputs array.
    ///
    /// # Example
    ///
    /// ```
    /// clean();
    /// ```
    function clean() public {
        delete inputs;
    }

    /// Read a proof from a file located in circuits/proofs.
    ///
    /// # Example
    ///
    /// ```
    /// bytes memory proof = readProof("my_proof");
    /// ```
    function readProof(string memory fileName) public returns (bytes memory) {
        string memory file = vm.readFile(
            string.concat("circuits/zkecdsa/proofs/", fileName, ".proof")
        );
        return vm.parseBytes(file);
    }

    /// Generates a proof based on inputs and returns it.
    ///
    /// # Example
    ///
    /// ```
    /// withInput("x", 1).withInput("y", 2).withInput("return", 3);
    /// bytes memory proof = generateProof();
    /// ```

    // string n_hashedAddr;
    // bytes32 hashedAddr;
    // string n_pub_key;
    // uint8[] pub_key;
    // string n_signature;
    // uint8[] signature;
    // string n_message_hash;
    // uint8[] message_hash;

    function generateProof(string memory _path) public returns (bytes memory) {
        // write to Prover.toml
        string memory proverTOML = "circuits/zkecdsa/Prover.toml";
        //vm.writeFile(proverTOML, "");
        // write all inputs with their values

        console.logUint(1);

        // for (uint i; i < inputsArray.length; i++) {
        string memory params = string.concat(
            inputs.n_hashedAddr,
            " = ",
            vm.toString(inputs.hashedAddr),
            inputs.n_pub_key,
            " = ",
            uint8ArrayToString(inputs.pub_key),
            inputs.n_signature,
            " = ",
            uint8ArrayToString(inputs.signature),
            inputs.n_message_hash,
            " = ",
            uint8ArrayToString(inputs.message_hash)
        );

        vm.writeLine(proverTOML, params);

        // generate proof
        string[] memory ffi_cmds = new string[](1);
        ffi_cmds[0] = "./prove.sh";
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
