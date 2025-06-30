// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./DZAccessControl.sol";
import "./Errors.sol";

abstract contract DZExamManager is DZAccessControl {
    struct Exam {
        string hash;
        uint256 exam_id;
        address created_by;
        uint256 created_at;
        bool is_locked;
        bool is_active;
    }

    mapping(uint256 => Exam) public exams;
    mapping(address => uint256[]) public lecturerExams;

    event ExamStored(
        uint256 indexed exam_id,
        string hash,
        address indexed created_by,
        uint256 created_at,
        bytes32 indexed blockHash,
        uint256 blockNumber
    );

    event ExamLocked(uint256 indexed exam_id, address indexed locked_by);

    function storeExam(string memory _hash, uint256 _exam_id)
        public
        onlyRole(ADMIN_ROLE)
        returns (
            string memory hash,
            uint256 exam_id,
            address created_by,
            uint256 created_at,
            bool is_active
        )
    {
        if(_exam_id == 0) revert Errors.E003();
        if(bytes(_hash).length == 0) revert Errors.E002();
        if(exams[_exam_id].is_active) revert Errors.E302();

        exams[_exam_id] = Exam({
            hash: _hash,
            exam_id: _exam_id,
            created_by: msg.sender,
            created_at: block.timestamp,
            is_locked: false,
            is_active: true
        });

        lecturerExams[msg.sender].push(_exam_id);

        emit ExamStored(
            _exam_id,
            _hash,
            msg.sender,
            block.timestamp,
            blockhash(block.number - 1),
            block.number
        );

        return (_hash, _exam_id, msg.sender, block.timestamp, true);
    }

    function lockExam(uint256 _exam_id) public {
        if(!(hasRole(LECTURER_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender))) revert Errors.E101();
        if(!exams[_exam_id].is_active) revert Errors.E301();
        if(!(exams[_exam_id].created_by == msg.sender || hasRole(ADMIN_ROLE, msg.sender))) revert Errors.E305();

        exams[_exam_id].is_locked = true;
        emit ExamLocked(_exam_id, msg.sender);
    }

    function getExam(uint256 _exam_id)
        public
        view
        returns (
            string memory hash,
            uint256 exam_id,
            address created_by,
            uint256 created_at,
            bool is_locked,
            bool is_active
        )
    {
        Exam memory examData = exams[_exam_id];
        return (
            examData.hash,
            examData.exam_id,
            examData.created_by,
            examData.created_at,
            examData.is_locked,
            examData.is_active
        );
    }

    function getLecturerExams(address _lecturer)
        public
        view
        returns (uint256[] memory)
    {
        if(!(hasRole(LECTURER_ROLE, _lecturer) || hasRole(ADMIN_ROLE, _lecturer))) revert Errors.E103();
        return lecturerExams[_lecturer];
    }
}