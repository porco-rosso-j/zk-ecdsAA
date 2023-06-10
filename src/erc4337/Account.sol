pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "account-abstraction/core/BaseAccount.sol";
import "./UltraVerifier.sol";

import "../modules/Inheritance.sol";
import "../modules/Recovery.sol";
import "../helpers/BytesLib.sol";

/*

zkECDSAA: An ERC4337 AA wallet with a couple of privacy-preserving features enabled by Noir's zkECDSA. 

features
1: private social recovery
2: private owner
3: private inheritance

- 1
you can register private guardians for recoverying the ownership in case u lost the access to this acc.
to prevent the corruption of ur guardians, their addresses are hidden. 

- 2
as if u create a new EOA, u can create AA acc which is completely unrelated to ur other addresses
but still one of ur public eth address can control this acc privately. 

- 3
you can privately transfer the ownership this AA acc to somebody else.
The new owner can also control this acc as you used to do. 

TODO
0. make everything AA tx. with one zkECDSA circuit.
1. AA test.
  - generate the first 4 bytes: function selector of module methods
  - write tests for each module (validate userOps)
2. think through if the secret_salt is really needed
3. add zksync imp with foundry

*/

contract ZkECDSAA is
    BaseAccount,
    UUPSUpgradeable,
    Initializable,
    UltraVerifier,
    RecoveryModule,
    InheritanceModule
{
    using BytesLib for bytes;
    UltraVerifier public verifier;
    bytes32 public owner;

    // IEntryPoint private immutable _entryPoint;
    IEntryPoint private immutable _entryPoint;

    event ZKECDSAInitialized(
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

    function initialize(
        bytes32 _owner,
        address _verifier,
        bytes32[] memory _guardians,
        uint8 _threshold,
        uint _pendingPeriod,
        bytes32 _beneficiary
    ) public initializer {
        owner = _owner;
        verifier = UltraVerifier(_verifier);
        initializeRecovery(_guardians, _threshold);
        initializeInheritance(_pendingPeriod, _beneficiary);
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
    ) internal view override returns (uint256 validationData) {
        (bytes32 hashedAddr, bytes memory proof) = abi.decode(
            userOp.signature,
            (bytes32, bytes)
        );

        bytes32[] memory publicInputs = new bytes32[](33);
        publicInputs[0] = hashedAddr;

        bytes memory b = bytes.concat(userOpHash);

        for (uint i = 0; i < b.length; i++) {
            publicInputs[i + 1] = bytes32(uint(uint8(b[i])));
        }

        // signature == proof ( mb better abi encoded)
        if (!verifier.verify(proof, publicInputs))
            revert PROOF_VERIFICATION_FAILED();
        return 0;
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
