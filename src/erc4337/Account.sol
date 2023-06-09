pragma solidity ^0.8.12;

import "openzeppelin-contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import "account-abstraction/core/BaseAccount.sol";
import "./UltraPlonkVerifier.sol";

import "./helpers/BytesLib.sol";

contract zkECDSAA is
    BaseAccount,
    UUPSUpgradeable,
    Initializable,
    UltraPlonkVerifier
{
    using BytesLib for bytes;
    UltraPlonkVerifier public verifier;
    bytes32 public owner;

    IEntryPoint private immutable _entryPoint;

    event DarkAAInitialized(
        IEntryPoint indexed entryPoint,
        bytes32 indexed owner
    );

    modifier onlyEntryPoint() {
        require(msg.sender == address(_entryPoint), "only entrypoint");
        _;
    }

    function _onlySelf() internal view {
        require(msg.sender == address(this), "ONLY_SELF");
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    error PROOF_VERIFICATION_FAILED();

    constructor(address anEntryPoint) {
        _entryPoint = IEntryPoint(anEntryPoint);
    }

    function initialize(bytes32 _owner, address _verifier) public initializer {
        owner = _owner;
        verifier = UltraPlonkVerifier(_verifier);
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external onlyEntryPoint {
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(
        address[] calldata dest,
        bytes[] calldata func
    ) external onlyEntryPoint {
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override returns (uint256 validationData) {
        _requireFromEntryPoint();
        validationData = _validateSignature(userOp, userOpHash);
        _validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal override returns (uint256 validationData) {
        bytes32[] memory publicInputs = new bytes32[](33);

        publicInputs = getPublicInputs(userOp, userOpHash, publicInputs);

        // if bytes4(callData) == approveRecovery or proposeInheritance
        // inputs for proof will be another one.

        // signature == proof ( mb better abi encoded)
        if (!verifier.verify(userOp.signature, publicInputs))
            revert PROOF_VERIFICATION_FAILED();
        return 0;
    }

    // is it possible for somebody to call approveRecovery more than signle times
    // by using other's hashed address. nah?
    // i guess that person cant create proof as he/she cant sign tx properly.

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

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) public {
        _onlySelf();
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override {
        (newImplementation);
        _onlySelf();
    }

    function changeOwner(bytes32 _owner) internal override {
        owner = _owner;
    }

    function _owmer() internal view override returns (bytes32) {
        return owner;
    }
}
