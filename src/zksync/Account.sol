// https://github.com/matter-labs/foundry-zksync
// https://github.com/sammyshakes/sample-fzksync-project/blob/main/src/TwoUserMultiSig.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "era-system-contracts/contracts/interfaces/IAccount.sol";
import "era-system-contracts/contracts/libraries/TransactionHelper.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1271.sol";

// Access zkSync system contracts for nonce validation via NONCE_HOLDER_SYSTEM_CONTRACT
import "era-system-contracts/contracts/Constants.sol";
// to call non-view function of system contracts
import "era-system-contracts/contracts/libraries/SystemContractsCaller.sol";

import "../modules/Inheritance.sol";
import "../modules/Recovery.sol";
import "../helpers/BytesLib.sol";
import "../erc4337/UltraVerifier.sol";

contract Account is
    IAccount,
    IERC1271,
    UltraVerifier,
    RecoveryModule,
    InheritanceModule
{
    // to get transaction hash
    using TransactionHelper for Transaction;
    using BytesLib for bytes;

    UltraVerifier public verifier;

    // state variables for account owners
    bytes32 public owner;

    bytes4 constant EIP1271_SUCCESS_RETURN_VALUE = 0x1626ba7e;

    modifier onlyBootloader() {
        require(
            msg.sender == BOOTLOADER_FORMAL_ADDRESS,
            "Only bootloader can call this function"
        );
        // Continue execution if called from the bootloader.
        _;
    }

    constructor(
        bytes32 _owner,
        address _verifier,
        bytes32[] memory _guardians,
        uint8 _threshold,
        uint _pendingPeriod,
        bytes32 _beneficiary
    ) {
        owner = _owner;
        verifier = UltraVerifier(_verifier);
        initializeRecovery(_guardians, _threshold);
        initializeInheritance(_pendingPeriod, _beneficiary);
    }

    function validateTransaction(
        bytes32,
        bytes32 _suggestedSignedHash,
        Transaction calldata _transaction
    ) external payable override onlyBootloader returns (bytes4 magic) {
        return _validateTransaction(_suggestedSignedHash, _transaction);
    }

    function _validateTransaction(
        bytes32 _suggestedSignedHash,
        Transaction calldata _transaction
    ) internal returns (bytes4 magic) {
        // Incrementing the nonce of the account.
        // Note, that reserved[0] by convention is currently equal to the nonce passed in the transaction
        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(
                INonceHolder.incrementMinNonceIfEquals,
                (_transaction.nonce)
            )
        );

        bytes32 txHash;
        // While the suggested signed hash is usually provided, it is generally
        // not recommended to rely on it to be present, since in the future
        // there may be tx types with no suggested signed hash.
        if (_suggestedSignedHash == bytes32(0)) {
            txHash = _transaction.encodeHash();
        } else {
            txHash = _suggestedSignedHash;
        }

        // The fact there is are enough balance for the account
        // should be checked explicitly to prevent user paying for fee for a
        // transaction that wouldn't be included on Ethereum.
        uint256 totalRequiredBalance = _transaction.totalRequiredBalance();
        require(
            totalRequiredBalance <= address(this).balance,
            "Not enough balance for fee + value"
        );

        (bytes32 hashedAddr, bytes memory proof) = abi.decode(
            _transaction.signature,
            (bytes32, bytes)
        );

        bytes32[] memory publicInputs = new bytes32[](33);
        publicInputs[0] = hashedAddr;

        bytes memory b = bytes.concat(txHash);

        for (uint i = 0; i < b.length; i++) {
            publicInputs[i + 1] = bytes32(uint(uint8(b[i])));
        }

        if (verifier.verify(proof, publicInputs)) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }
    }

    function executeTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    ) external payable override onlyBootloader {
        _executeTransaction(_transaction);
    }

    function _executeTransaction(Transaction calldata _transaction) internal {
        address to = address(uint160(_transaction.to));
        uint128 value = Utils.safeCastToU128(_transaction.value);
        bytes memory data = _transaction.data;

        if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
            uint32 gas = Utils.safeCastToU32(gasleft());

            // Note, that the deployer contract can only be called
            // with a "systemCall" flag.
            SystemContractsCaller.systemCallWithPropagatedRevert(
                gas,
                to,
                value,
                data
            );
        } else {
            bool success;
            assembly {
                success := call(
                    gas(),
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
            require(success);
        }
    }

    function executeTransactionFromOutside(
        Transaction calldata _transaction
    ) external payable {
        _validateTransaction(bytes32(0), _transaction);
        _executeTransaction(_transaction);
    }

    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    ) public view override returns (bytes4 magic) {
        magic = EIP1271_SUCCESS_RETURN_VALUE;

        publicInputs = getPublicInputs(userOp, _hash, publicInputs);

        // Note, that we should abstain from using the require here in order to allow for fee estimation to work
        if (!verifier.verify(userOp.signature, publicInputs)) {
            magic = bytes4(0);
        }
    }

    function getPublicInputs(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        bytes32[] memory publicInputs
    ) internal view returns (bytes32[] memory) {
        bytes4 msgSig = BytesLib.getSelector(userOp.callData);

        // https://abi.hashex.org/
        publicInputs[0] = msgSig == bytes4(0x238bc149)
            ? BytesLib.decodeRecoveryArgs(userOp.callData)
            : msgSig == bytes4(0x11111111)
            ? BytesLib.decodeProposeInheritanceArgs(userOp.callData)
            : msgSig == bytes4(0x22222222)
            ? BytesLib.decodeExecuteInheritanceArgs(userOp.callData)
            : owner;

        bytes memory b = bytes.concat(userOpHash);

        for (uint i = 0; i < b.length; i++) {
            publicInputs[i + 1] = bytes32(uint(uint8(b[i])));
        }

        return publicInputs;
    }

    function payForTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    ) external payable override onlyBootloader {
        bool success = _transaction.payToTheBootloader();
        require(success, "Failed to pay the fee to the operator");
    }

    function prepareForPaymaster(
        bytes32, // _txHash
        bytes32, // _suggestedSignedHash
        Transaction calldata _transaction
    ) external payable override onlyBootloader {
        _transaction.processPaymasterInput();
    }

    function changeOwner(bytes32 _owner) internal override {
        owner = _owner;
    }

    function _owmer() internal view override returns (bytes32) {
        return owner;
    }

    fallback() external {
        // fallback of default account shouldn't be called by bootloader under no circumstances
        assert(msg.sender != BOOTLOADER_FORMAL_ADDRESS);

        // If the contract is called directly, behave like an EOA
    }

    receive() external payable {
        // If the contract is called directly, behave like an EOA.
        // Note, that is okay if the bootloader sends funds with no calldata as it may be used for refunds/operator payments
    }
}
