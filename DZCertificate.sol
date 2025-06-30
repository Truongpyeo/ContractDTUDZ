// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./DZReviewManager.sol";
import "./Errors.sol";

abstract contract DZCertificate is DZReviewManager {
    struct Certificate {
        uint256 tokenId;
        uint256 student_id;
        uint256 exam_id;
        uint256 score;
        string metadata_uri;
        uint256 issued_at;
        address issued_by;
        bool is_valid;
    }

    string private _name = "DZBlockChain Certificate";
    string private _symbol = "DZBC";
    uint256 private _currentTokenId;

    mapping(uint256 => Certificate) public certificates;
    mapping(uint256 => mapping(uint256 => uint256)) public studentCertificates;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event CertificateIssued(uint256 indexed tokenId, uint256 indexed student_id, uint256 indexed exam_id, address issued_by);
    event CertificateRevoked(uint256 indexed tokenId, address indexed revoked_by);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view returns (uint256) {
        if(owner == address(0)) revert Errors.E005();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if(owner == address(0)) revert Errors.E801();
        return owner;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if(!_exists(tokenId)) revert Errors.E801();
        return certificates[tokenId].metadata_uri;
    }

    function _mint(address to, uint256 tokenId) internal {
        if(to == address(0)) revert Errors.E005();
        if(_exists(tokenId)) revert Errors.E802();
        _owners[tokenId] = to;
        _balances[to] += 1;
        emit Transfer(address(0), to, tokenId);
    }

    function issueCertificate(uint256 _student_id, uint256 _exam_id, string memory _metadata_uri)
        public
        onlyRole(LECTURER_ROLE)
        returns (uint256)
    {
        if(!exams[_exam_id].is_active) revert Errors.E301();
        if(!scores[_student_id][_exam_id].is_final) revert Errors.E504();
        if(studentCertificates[_student_id][_exam_id] != 0) revert Errors.E802();
        if(studentAddresses[_student_id] == address(0)) revert Errors.E201();
        if(bytes(_metadata_uri).length == 0) revert Errors.E002();
        
        _currentTokenId++;
        uint256 tokenId = _currentTokenId;

        address studentAddress = studentAddresses[_student_id];
        _mint(studentAddress, tokenId);

        certificates[tokenId] = Certificate({
            tokenId: tokenId,
            student_id: _student_id,
            exam_id: _exam_id,
            score: scores[_student_id][_exam_id].score,
            metadata_uri: _metadata_uri,
            issued_at: block.timestamp,
            issued_by: msg.sender,
            is_valid: true
        });

        studentCertificates[_student_id][_exam_id] = tokenId;
        emit CertificateIssued(tokenId, _student_id, _exam_id, msg.sender);
        return tokenId;
    }

    function revokeCertificate(uint256 tokenId) public onlyRole(ADMIN_ROLE) {
        if(!certificates[tokenId].is_valid) revert Errors.E803();
        certificates[tokenId].is_valid = false;
        emit CertificateRevoked(tokenId, msg.sender);
    }

    function getMyCertificate(uint256 _student_id, uint256 _exam_id) public view onlyRole(STUDENT_ROLE) returns (Certificate memory) {
        if(studentAddresses[_student_id] != msg.sender) revert Errors.E101();
        uint256 tokenId = studentCertificates[_student_id][_exam_id];
        if(tokenId == 0) revert Errors.E801();
        return certificates[tokenId];
    }

    function verifyCertificate(uint256 tokenId) public view onlyRole(EMPLOYER_ROLE) returns (Certificate memory) {
        if(!certificates[tokenId].is_valid) revert Errors.E803();
        return certificates[tokenId];
    }

    function getCertificateByStudent(uint256 _student_id, uint256 _exam_id) public view onlyRole(EMPLOYER_ROLE) returns (Certificate memory) {
        uint256 tokenId = studentCertificates[_student_id][_exam_id];
        if(tokenId == 0) revert Errors.E801();
        return certificates[tokenId];
    }
}