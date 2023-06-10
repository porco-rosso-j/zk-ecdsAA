// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./Account.sol";

/**
 * A sample factory contract for SimpleAccount
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract AccountFactory {
    ZkECDSAA public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint) {
        accountImplementation = new ZkECDSAA(address(_entryPoint));
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(
        bytes32 _owner,
        address _verifier,
        bytes32[] memory _guardians,
        uint8 _threshold,
        uint _pendingPeriod,
        bytes32 _beneficiary,
        uint256 salt
    ) public returns (ZkECDSAA ret) {
        address addr = getAddress(
            _owner,
            _verifier,
            _guardians,
            _threshold,
            _pendingPeriod,
            _beneficiary,
            salt
        );
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return ZkECDSAA(payable(addr));
        }
        ret = ZkECDSAA(
            payable(
                new ERC1967Proxy{salt: bytes32(salt)}(
                    address(accountImplementation),
                    abi.encodeCall(
                        ZkECDSAA.initialize,
                        (
                            _owner,
                            _verifier,
                            _guardians,
                            _threshold,
                            _pendingPeriod,
                            _beneficiary
                        )
                    )
                )
            )
        );
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(
        bytes32 _owner,
        address _verifier,
        bytes32[] memory _guardians,
        uint8 _threshold,
        uint _pendingPeriod,
        bytes32 _beneficiary,
        uint256 salt
    ) public view returns (address) {
        return
            Create2.computeAddress(
                bytes32(salt),
                keccak256(
                    abi.encodePacked(
                        type(ERC1967Proxy).creationCode,
                        abi.encode(
                            address(accountImplementation),
                            abi.encodeCall(
                                ZkECDSAA.initialize,
                                (
                                    _owner,
                                    _verifier,
                                    _guardians,
                                    _threshold,
                                    _pendingPeriod,
                                    _beneficiary
                                )
                            )
                        )
                    )
                )
            );
    }
}
