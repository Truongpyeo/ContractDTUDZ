// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Errors.sol";

abstract contract DZAccessControl {
    mapping(bytes32 => mapping(address => bool)) private _roles;
    mapping(bytes32 => bytes32) private _roleAdmins;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant LECTURER_ROLE = keccak256("LECTURER_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");
    bytes32 public constant EMPLOYER_ROLE = keccak256("EMPLOYER_ROLE");

    mapping(uint256 => address) public studentAddresses;
    mapping(address => uint256) public addressToStudentId;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event StudentAddressSet(uint256 indexed student_id, address indexed studentAddress, address setBy);
    event StudentAddressUpdated(uint256 indexed student_id, address indexed oldAddress, address indexed newAddress, address updatedBy);

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "Access denied");
        _;
    }

    function _initializeAccessControl(address deployer) internal {
        _grantRole(DEFAULT_ADMIN_ROLE, deployer);
        _grantRole(ADMIN_ROLE, deployer);
        _setRoleAdmin(LECTURER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(STUDENT_ROLE, ADMIN_ROLE);
        _setRoleAdmin(EMPLOYER_ROLE, ADMIN_ROLE);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        _roleAdmins[role] = adminRole;
    }

    function grantRole(bytes32 role, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    function grantLecturerRole(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(LECTURER_ROLE, account);
    }

    function grantStudentRole(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(STUDENT_ROLE, account);
    }

    function grantEmployerRole(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(EMPLOYER_ROLE, account);
    }

    function revokeLecturerRole(address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(LECTURER_ROLE, account);
    }

    function revokeStudentRole(address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(STUDENT_ROLE, account);
    }

    function revokeEmployerRole(address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(EMPLOYER_ROLE, account);
    }

    function setStudentAddress(uint256 _student_id, address _studentAddress) public onlyRole(ADMIN_ROLE) {
        if(_student_id == 0) revert Errors.E003();
        if(_studentAddress == address(0)) revert Errors.E005();
        if(studentAddresses[_student_id] != address(0)) revert Errors.E203();
        if(addressToStudentId[_studentAddress] != 0) revert Errors.E202();

        studentAddresses[_student_id] = _studentAddress;
        addressToStudentId[_studentAddress] = _student_id;

        emit StudentAddressSet(_student_id, _studentAddress, msg.sender);
    }

    function updateStudentAddress(uint256 _student_id, address _newAddress) public onlyRole(ADMIN_ROLE) {
        if(_student_id == 0) revert Errors.E003();
        if(_newAddress == address(0)) revert Errors.E005();
        if(studentAddresses[_student_id] == address(0)) revert Errors.E201();
        if(addressToStudentId[_newAddress] != 0) revert Errors.E202();

        address oldAddress = studentAddresses[_student_id];
        delete addressToStudentId[oldAddress];
        studentAddresses[_student_id] = _newAddress;
        addressToStudentId[_newAddress] = _student_id;

        emit StudentAddressUpdated(_student_id, oldAddress, _newAddress, msg.sender);
    }

    function getStudentAddress(uint256 _student_id) public view returns (address) {
        return studentAddresses[_student_id];
    }

    function getStudentIdByAddress(address _address) public view returns (uint256) {
        return addressToStudentId[_address];
    }
}