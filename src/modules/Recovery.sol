pragma solidity ^0.8.12;

import "./ModuleBase.sol";

// https://github.com/noir-lang/noir-starter/blob/main/foundry-voting/src/zkVote.sol
// https://github.com/colinnielsen/dark-safe/blob/colinnielsen/verify-sigs/contracts/DarkSafe.sol

abstract contract RecoveryModule is ModuleBase {
    mapping(bytes32 => bool) public guardians;

    struct Recovery {
        uint approvalCount;
        uint deadline;
        mapping(bytes32 => bool) voted; // double-spend checker
    }

    mapping(bytes32 => Recovery) public recoveries; // new owner => Recovery

    uint8 public recoveryThreshold;

    // ) public onlySelf {
    function initializeRecovery(
        bytes32[] memory _guardians,
        uint8 _threshold
    ) internal {
        require(_guardians.length >= _threshold, "INVALID_GUARDIAN_NUMBER");
        setGurdian(_guardians);
        setThreshold(_threshold);
    }

    function setGurdian(bytes32[] memory _guardians) public {
        for (uint i; i < _guardians.length; i++) {
            guardians[_guardians[i]] = true;
        }
    }

    function removeGurdian(bytes32[] memory _guardians) external onlySelf {
        for (uint i; i < _guardians.length; i++) {
            guardians[_guardians[i]] = false;
        }
    }

    function setThreshold(uint8 _threshold) public {
        recoveryThreshold = _threshold;
    }

    // called from new EOA which is created by the owner who lost access to this account
    function proposeRecovery(bytes32 _newOwner, uint _deadline) public {
        require(_newOwner != _owmer(), "INVALID_NEW_OWENR");
        require(_newOwner.length != 0, "INVALID_BYTES");

        Recovery storage recovery = recoveries[_newOwner];
        recovery.approvalCount = 0;
        recovery.deadline = _deadline;
    }

    function approveRecovery(
        bytes32 _newOwner, // proposed new onwer
        bytes32 _guardian // "caller"
    ) public onlySelf {
        require(
            block.timestamp < recoveries[_newOwner].deadline,
            "Voting period is over."
        );
        require(
            !recoveries[_newOwner].voted[_guardian],
            "DOUBLE_VOTE_NOT_ALLOWED"
        );
        require(guardians[_guardian], "INVALID_GUARDIAN");
        recoveries[_newOwner].approvalCount += 1;
        if (recoveries[_newOwner].approvalCount >= recoveryThreshold) {
            changeOwner(_newOwner);
        }
        recoveries[_newOwner].voted[_guardian] = true;
    }

    function getApprovalCount(bytes32 _hashedAddr) public view returns (uint) {
        return recoveries[_hashedAddr].approvalCount;
    }

    function getVoted(
        bytes32 _newOwner,
        bytes32 _approver
    ) public view returns (bool) {
        return recoveries[_newOwner].voted[_approver];
    }
}

/*

        // --  this part below can be put into validateSignature ---
        // implementing all features with one circuit.

        bytes32[] memory publicInputs = new bytes32[](3);
        publicInputs[0] = _guardian;
        publicInputs[1] = msg.data;

        // --- ----
*/
