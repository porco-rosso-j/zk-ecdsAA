pragma solidity ^0.8.12;

contract ModuleBase {
    modifier onlySelf() {
        require(msg.sender == address(this), "ONLY_SELF");
        _;
    }

    function changeOwner(bytes32 _owner) internal virtual {}

    function _owmer() internal view virtual returns (bytes32) {}
}
