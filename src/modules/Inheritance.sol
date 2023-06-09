pragma solidity ^0.8.12;

import "./ModuleBase.sol";

contract InheritanceModule is ModuleBase {
    uint public pendingPeriod; // e.g. 7884008 ( = 3 months )

    struct Inheritance {
        bytes32 beneficiary;
        bool succeed;
        uint deadline; // time until when the current owner should reject the proposal
    }

    mapping(uint => Inheritance) public inheritances; // inheritanceCount => Inheritance
    uint public inheritanceCount;

    mapping(bytes32 => bool) public beneficiaries;

    function initializeInheritance(uint _pendingPeriod) internal {
        setPendingPeriod(_pendingPeriod);
    }

    function setPendingPeriod(uint _pendingPeriod) public onlySelf {
        pendingPeriod = _pendingPeriod;
    }

    function proposeInheritance(bytes32 _beneficiary) public returns (uint) {
        require(_beneficiary.length != 0, "INVALID_BENFICIARY_LENGTH");
        require(_beneficiary != _owmer(), "INVALID_BENFICIARY");
        require(beneficiaries[_beneficiary], "NON_REGISTERED_BENFICIARY");

        uint newInheritanceCount = inheritanceCount + 1;

        Inheritance memory inheritance = inheritances[newInheritanceCount];
        inheritance.beneficiary = _beneficiary;
        inheritance.succeed = true;
        inheritance.deadline = block.timestamp + pendingPeriod;

        inheritances[newInheritanceCount] = inheritance;

        return newInheritanceCount;
    }

    // if owner doesn't reject the proposal && deadline has been passed, the proposer can take ownership.
    // if owner said no, it fails.
    function executeInheritance(
        bytes32 _beneficiary,
        uint _inheritanceCount
    ) public {
        Inheritance memory inheritance = inheritances[_inheritanceCount];
        require(_beneficiary == inheritance.beneficiary, "INVALID_BENFICIARY");

        if (inheritance.succeed && inheritance.deadline <= block.timestamp) {
            bytes32 newOwner = inheritance.beneficiary;
            changeOwner(newOwner);
        } else {
            revert("INHERITRANCE_FAILED");
        }
    }

    // the owner approves the change of the ownership without waiting for pending period.
    // if expired, the owner can't do this but wait the proposer to execute inheritance.
    function approveInheritance(uint _inheritanceCount) public onlySelf {
        require(
            _inheritanceCount != 0 && _inheritanceCount <= inheritanceCount,
            "INVALID_COUNT"
        );
        Inheritance memory inheritance = inheritances[_inheritanceCount];
        require(inheritance.succeed, "INVALID_ACTION");
        require(inheritance.deadline <= block.timestamp, "EXPIERED_ACTION");
        bytes32 newOwner = inheritance.beneficiary;
        changeOwner(newOwner);
    }

    // the owner simply rejects the change of the ownership within the pending period.
    // if expired, the owner can't reject but wait the proposer to execute inheritance.
    function rejectInheritance(uint _inheritanceCount) public onlySelf {
        require(
            _inheritanceCount != 0 && _inheritanceCount <= inheritanceCount,
            "INVALID_COUNT"
        );
        Inheritance memory inheritance = inheritances[_inheritanceCount];
        require(inheritance.succeed, "INVALID_ACTION");
        require(inheritance.deadline <= block.timestamp, "EXPIERED_ACTION");
        inheritance.succeed = false;
        inheritances[_inheritanceCount] = inheritance;
    }
}
